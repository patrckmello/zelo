"""Fábrica da aplicação FastAPI.

Execução local: `uvicorn app.main:create_app --factory --reload`.
"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, get_settings
from .container import AppContainer
from .errors import register_error_handlers
from .routers import account, auth, collection_points, disposals, health, medications, ocr
from .services.medication_ocr import TextRecognizer
from .services.password_reset import PasswordResetNotifier

API_PREFIX = "/v1"


def _configure_logging() -> None:
    if not logging.getLogger().handlers:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(name)s %(message)s",
        )
    # O httpx registra URLs completas (com coordenadas) no nível INFO.
    logging.getLogger("httpx").setLevel(logging.WARNING)


def create_app(
    settings: Settings | None = None,
    *,
    ecomed_transport: httpx.BaseTransport | None = None,
    password_reset_notifier: PasswordResetNotifier | None = None,
    text_recognizer: TextRecognizer | None = None,
) -> FastAPI:
    _configure_logging()
    settings = settings or get_settings()
    container = AppContainer.build(
        settings,
        ecomed_transport=ecomed_transport,
        password_reset_notifier=password_reset_notifier,
        text_recognizer=text_recognizer,
    )

    @asynccontextmanager
    async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
        yield
        container.close()

    app = FastAPI(
        title="API Zelo",
        version="0.1.0",
        description="Organização de medicamentos domésticos e descarte responsável.",
        lifespan=lifespan,
        docs_url="/docs" if settings.environment != "production" else None,
        redoc_url=None,
    )
    app.state.container = container
    register_error_handlers(app)

    if settings.cors_origins or settings.cors_origin_regex:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origins,
            allow_origin_regex=settings.cors_origin_regex,
            allow_methods=["GET", "POST", "PUT", "DELETE"],
            allow_headers=["Authorization", "Content-Type"],
        )

    app.include_router(health.router)
    for router in (
        auth.router,
        account.router,
        medications.router,
        disposals.router,
        collection_points.router,
        ocr.router,
    ):
        app.include_router(router, prefix=API_PREFIX)
    return app
