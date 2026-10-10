"""Dependências compartilhadas por toda a aplicação."""

from dataclasses import dataclass

import httpx

from .config import Settings
from .database import Database
from .services.ecomed import CollectionPointsService, EcoMedClient
from .services.geo_cache import TtlCache
from .services.medication_ocr import TextRecognizer, default_recognizer
from .services.password_reset import (
    DisabledPasswordResetNotifier,
    OutboxPasswordResetNotifier,
    PasswordResetNotifier,
)
from .services.rate_limiter import SlidingWindowLimiter


@dataclass
class AppContainer:
    settings: Settings
    database: Database
    collection_points: CollectionPointsService
    login_limiter: SlidingWindowLimiter
    password_reset_notifier: PasswordResetNotifier
    text_recognizer: TextRecognizer
    ocr_limiter: SlidingWindowLimiter

    @classmethod
    def build(
        cls,
        settings: Settings,
        *,
        ecomed_transport: httpx.BaseTransport | None = None,
        password_reset_notifier: PasswordResetNotifier | None = None,
        text_recognizer: TextRecognizer | None = None,
    ) -> "AppContainer":
        api_key = settings.ecomed_api_key
        client_factory = (
            (
                lambda: EcoMedClient(
                    api_key=api_key.get_secret_value(),
                    base_url=settings.ecomed_base_url,
                    timeout_seconds=settings.ecomed_timeout_seconds,
                    transport=ecomed_transport,
                )
            )
            if api_key is not None
            else None
        )
        if password_reset_notifier is None:
            outbox = settings.password_reset_outbox_dir
            password_reset_notifier = (
                OutboxPasswordResetNotifier(outbox)
                if outbox is not None and settings.environment != "production"
                else DisabledPasswordResetNotifier()
            )
        return cls(
            settings=settings,
            database=Database(settings.database_url),
            collection_points=CollectionPointsService(
                client_factory=client_factory,
                cache=TtlCache(settings.ecomed_cache_ttl_seconds),
                limiter=SlidingWindowLimiter(settings.ecomed_rate_limit_per_minute, 60),
            ),
            login_limiter=SlidingWindowLimiter(
                settings.login_attempts_per_window, settings.login_window_seconds
            ),
            password_reset_notifier=password_reset_notifier,
            text_recognizer=text_recognizer or default_recognizer(settings.ocr_engine),
            # A leitura usa CPU: no máximo 20 imagens por minuto por conta.
            ocr_limiter=SlidingWindowLimiter(20, 60),
        )

    def close(self) -> None:
        self.collection_points.close()
        self.database.engine.dispose()
