"""Cliente da API Pública EcoMed v1 e normalização dos pontos de coleta.

Contrato conforme a documentação pública (https://ecomed.eco.br/desenvolvedores,
consultada em 02/10/2026):

- `GET /pontos/proximos?lat=&lng=&raio=` devolve até 30 pontos ordenados por
  distância, em `pontos`, com `id`, `name`, `address`, `city`, `state`,
  `latitude`, `longitude`, `phone`, `residueTypes` e `distancia_metros`;
- `GET /pontos/:id` devolve os detalhes de um ponto (formato de `schedules`
  ainda não documentado e, por isso, não exposto);
- autenticação pelo header `X-API-Key`, limite de 60 requisições por minuto.

A chave nunca é registrada em logs, mensagens de erro ou respostas. Os logs
também não incluem coordenadas.
"""

import logging
import re
import time
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any, Literal

import httpx

from .geo_cache import TtlCache, nearby_cache_key, round_coordinate
from .rate_limiter import SlidingWindowLimiter

logger = logging.getLogger("zelo.ecomed")

MIN_RADIUS_M = 500
MAX_RADIUS_M = 50_000
DEFAULT_RADIUS_M = 5_000
POINT_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")

_RESIDUE_CANONICAL = {
    "medicamento": "medicamento",
    "medicamentos": "medicamento",
    "seringa": "seringa",
    "seringas": "seringa",
}
_RESIDUE_ORDER = ["medicamento", "seringa"]

EcoMedFailure = Literal[
    "not_configured",
    "unauthorized",
    "rate_limited",
    "timeout",
    "unavailable",
    "invalid_response",
    "not_found",
]


class EcoMedError(Exception):
    def __init__(self, failure: EcoMedFailure, retry_after: float | None = None) -> None:
        super().__init__(failure)
        self.failure = failure
        self.retry_after = retry_after


@dataclass(frozen=True)
class CollectionPoint:
    id: str
    name: str
    address: str
    city: str
    state: str
    latitude: float
    longitude: float
    phone: str | None
    residue_types: tuple[str, ...]
    distance_m: int | None

    @property
    def origin(self) -> Literal["logmed", "other"]:
        # Somente IDs logmed-* identificam farmácias do programa LogMed.
        return "logmed" if self.id.lower().startswith("logmed-") else "other"

    @property
    def requires_confirmation(self) -> bool:
        return self.origin != "logmed"

    def as_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "address": self.address,
            "city": self.city,
            "state": self.state,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "phone": self.phone,
            "residue_types": list(self.residue_types),
            "distance_m": self.distance_m,
            "origin": self.origin,
            "requires_confirmation": self.requires_confirmation,
        }


def normalize_residue_types(values: Any) -> tuple[str, ...]:
    if not isinstance(values, list):
        return ()
    found: list[str] = []
    for value in values:
        if not isinstance(value, str):
            continue
        text = " ".join(value.strip().lower().split())
        if not text:
            continue
        canonical = _RESIDUE_CANONICAL.get(text, text)
        if canonical not in found:
            found.append(canonical)
    known = [item for item in _RESIDUE_ORDER if item in found]
    return tuple(known + sorted(item for item in found if item not in _RESIDUE_ORDER))


def _text(value: Any) -> str:
    return " ".join(value.split()) if isinstance(value, str) else ""


def _coordinate(value: Any, limit: float) -> float | None:
    if isinstance(value, bool):
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if -limit <= number <= limit else None


def normalize_point(raw: Any) -> CollectionPoint | None:
    """Converte um ponto da EcoMed; devolve `None` se faltar o essencial."""
    if not isinstance(raw, dict):
        return None
    point_id = _text(raw.get("id"))
    name = _text(raw.get("name"))
    latitude = _coordinate(raw.get("latitude"), 90)
    longitude = _coordinate(raw.get("longitude"), 180)
    if not point_id or not name or latitude is None or longitude is None:
        return None

    distance = raw.get("distancia_metros")
    distance_m = (
        round(distance)
        if isinstance(distance, (int, float)) and not isinstance(distance, bool) and distance >= 0
        else None
    )
    phone = _text(raw.get("phone")) or None
    return CollectionPoint(
        id=point_id,
        name=name,
        address=_text(raw.get("address")),
        city=_text(raw.get("city")),
        state=_text(raw.get("state")).upper(),
        latitude=latitude,
        longitude=longitude,
        phone=phone,
        residue_types=normalize_residue_types(raw.get("residueTypes")),
        distance_m=distance_m,
    )


def normalize_nearby_payload(payload: Any) -> list[CollectionPoint]:
    if not isinstance(payload, dict) or not isinstance(payload.get("pontos"), list):
        raise EcoMedError("invalid_response")
    points = [normalize_point(item) for item in payload["pontos"]]
    skipped = sum(point is None for point in points)
    if skipped:
        logger.warning("ecomed_pontos_descartados quantidade=%d", skipped)
    valid = [point for point in points if point is not None]
    return sorted(
        valid,
        key=lambda point: (point.distance_m is None, point.distance_m or 0, point.name),
    )


def _retry_after(response: httpx.Response, now: float) -> float:
    for header in ("Retry-After", "X-RateLimit-Reset"):
        raw = response.headers.get(header)
        if not raw:
            continue
        try:
            value = float(raw)
        except ValueError:
            continue
        # O formato do reset não é documentado: aceita época ou segundos.
        seconds = value - now if value > 1_000_000_000 else value
        return min(max(seconds, 1.0), 60.0)
    return 30.0


class EcoMedClient:
    def __init__(
        self,
        api_key: str,
        base_url: str,
        timeout_seconds: float,
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        self._client = httpx.Client(
            base_url=base_url.rstrip("/") + "/",
            timeout=timeout_seconds,
            headers={
                "X-API-Key": api_key,
                "Accept": "application/json",
                "User-Agent": "ZeloAPI/1.0 (projeto academico CESUCA)",
            },
            transport=transport,
        )

    def close(self) -> None:
        self._client.close()

    def get_json(self, path: str, params: dict[str, Any] | None = None) -> Any:
        started = time.perf_counter()
        try:
            response = self._client.get(path, params=params)
        except httpx.TimeoutException:
            logger.warning("ecomed_timeout")
            raise EcoMedError("timeout") from None
        except httpx.HTTPError as error:
            logger.warning("ecomed_falha_rede tipo=%s", type(error).__name__)
            raise EcoMedError("unavailable") from None

        elapsed_ms = round((time.perf_counter() - started) * 1000)
        logger.info(
            "ecomed_resposta status=%d duracao_ms=%d restantes=%s",
            response.status_code,
            elapsed_ms,
            response.headers.get("X-RateLimit-Remaining", "?"),
        )
        if response.status_code in (401, 403):
            raise EcoMedError("unauthorized")
        if response.status_code == 404:
            raise EcoMedError("not_found")
        if response.status_code == 429:
            raise EcoMedError("rate_limited", _retry_after(response, time.time()))
        if response.status_code >= 400:
            raise EcoMedError("unavailable")
        try:
            return response.json()
        except ValueError:
            raise EcoMedError("invalid_response") from None


class CollectionPointsService:
    """Cache e limite antes de qualquer chamada à EcoMed."""

    def __init__(
        self,
        client_factory: Callable[[], EcoMedClient] | None,
        cache: TtlCache,
        limiter: SlidingWindowLimiter,
    ) -> None:
        self._client_factory = client_factory
        self._client: EcoMedClient | None = None
        self._cache = cache
        self._limiter = limiter

    @property
    def configured(self) -> bool:
        return self._client_factory is not None

    def close(self) -> None:
        if self._client is not None:
            self._client.close()
            self._client = None

    def nearby(
        self, latitude: float, longitude: float, radius_m: int
    ) -> tuple[list[CollectionPoint], Literal["hit", "miss"]]:
        key = nearby_cache_key(latitude, longitude, radius_m)
        cached = self._cache.get(key)
        if cached is not None:
            return cached, "hit"

        payload = self._call(
            "pontos/proximos",
            {
                "lat": round_coordinate(latitude),
                "lng": round_coordinate(longitude),
                "raio": radius_m,
            },
        )
        points = normalize_nearby_payload(payload)
        self._cache.set(key, points)
        return points, "miss"

    def detail(self, point_id: str) -> CollectionPoint:
        if not POINT_ID_PATTERN.fullmatch(point_id):
            raise EcoMedError("not_found")
        key = ("detail", point_id)
        cached = self._cache.get(key)
        if cached is not None:
            return cached

        payload = self._call(f"pontos/{point_id}", None)
        # Formato do detalhe ainda não documentado: aceita o ponto na raiz ou
        # em "ponto"; qualquer outro formato é tratado como resposta inválida.
        raw = payload.get("ponto") if isinstance(payload, dict) and "ponto" in payload else payload
        point = normalize_point(raw)
        if point is None:
            raise EcoMedError("invalid_response")
        self._cache.set(key, point)
        return point

    def _call(self, path: str, params: dict[str, Any] | None) -> Any:
        if self._client_factory is None:
            raise EcoMedError("not_configured")
        wait = self._limiter.try_acquire("ecomed")
        if wait is not None:
            logger.warning("ecomed_limite_local_atingido")
            raise EcoMedError("rate_limited", wait)
        if self._client is None:
            self._client = self._client_factory()
        return self._client.get_json(path, params)
