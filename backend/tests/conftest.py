"""Infraestrutura de testes: SQLite isolado por teste e EcoMed simulada.

Nenhum teste acessa a rede ou a API EcoMed real. As respostas simuladas seguem
o exemplo publicado na documentação pública da EcoMed e usam dados fictícios.
"""

import json
from collections.abc import Callable, Iterator
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

import httpx
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.config import Settings
from app.database import Base
from app.main import create_app
from app.services.medication_ocr import OcrLine

TEST_JWT_SECRET = "segredo-de-teste-com-mais-de-32-caracteres!"
TEST_ECOMED_KEY = "chave-ficticia-de-teste-0001"

ECOMED_EXAMPLE_PAYLOAD = {
    "source": "EcoMed Public API v1",
    "attribution": "Dados originais: LogMed / Sindusfarma...",
    "count": 3,
    "query": {"lat": -23.551, "lng": -46.633, "raio_metros": 5000},
    "pontos": [
        {
            "id": "logmed-001234",
            "name": "Farmácia Exemplo - Centro",
            "address": "Rua das Flores, 100",
            "city": "São Paulo",
            "state": "SP",
            "latitude": -23.5489,
            "longitude": -46.6388,
            "phone": "(11) 3333-4444",
            "residueTypes": ["medicamento"],
            "distancia_metros": 412,
        },
        {
            "id": "exemplo-ubs-1",
            "name": "  Unidade de Saúde   Exemplo ",
            "address": "Rua Fictícia, 45",
            "city": "São Paulo",
            "state": "sp",
            "latitude": -23.5602,
            "longitude": -46.6455,
            "phone": "",
            "residueTypes": ["Medicamentos", "seringas", "medicamento"],
            "distancia_metros": 3100.4,
        },
        {"id": "sem-coordenadas", "name": "Ponto incompleto"},
    ],
}


class CapturingNotifier:
    def __init__(self) -> None:
        self.sent: list[tuple[str, str]] = []

    def send(self, email: str, token: str, expires_at: datetime) -> None:
        self.sent.append((email, token))


@dataclass
class FakeEcoMed:
    """Servidor EcoMed simulado; `respond` pode ser trocado em cada teste."""

    requests: list[httpx.Request] = field(default_factory=list)
    respond: Callable[[httpx.Request], httpx.Response] | None = None

    def handle(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        if self.respond is not None:
            return self.respond(request)
        if request.url.path.endswith("/pontos/proximos"):
            return httpx.Response(
                200,
                json=ECOMED_EXAMPLE_PAYLOAD,
                headers={"X-RateLimit-Remaining": "59"},
            )
        point_id = request.url.path.rsplit("/", 1)[-1]
        for point in ECOMED_EXAMPLE_PAYLOAD["pontos"]:
            if point["id"] == point_id:
                return httpx.Response(200, json=point)
        return httpx.Response(404, json={"error": "not found"})


def build_settings(tmp_path, **overrides: Any) -> Settings:
    values: dict[str, Any] = {
        "ZELO_ENV": "test",
        "ZELO_DATABASE_URL": f"sqlite:///{(tmp_path / 'zelo.db').as_posix()}",
        "ZELO_JWT_SECRET": TEST_JWT_SECRET,
        "ZELO_CORS_ORIGINS": "",
        "ECOMED_API_KEY": TEST_ECOMED_KEY,
        "ECOMED_BASE_URL": "https://ecomed.example.test/api/public/v1",
        "ECOMED_CACHE_TTL_SECONDS": 300,
        "ECOMED_RATE_LIMIT_PER_MINUTE": 60,
        "ZELO_LOGIN_ATTEMPTS": 5,
    }
    values.update(overrides)
    return Settings(_env_file=None, **values)


class FakeRecognizer:
    """OCR simulado: devolve as linhas configuradas no teste."""

    def __init__(self) -> None:
        self.lines: list[OcrLine] = []
        self.available = True
        self.calls = 0

    def recognize(self, image) -> list[OcrLine]:
        self.calls += 1
        if not self.available:
            from app.services.medication_ocr import OcrUnavailableError

            raise OcrUnavailableError
        return self.lines


@pytest.fixture
def recognizer() -> FakeRecognizer:
    return FakeRecognizer()


@pytest.fixture
def ecomed() -> FakeEcoMed:
    return FakeEcoMed()


@pytest.fixture
def notifier() -> CapturingNotifier:
    return CapturingNotifier()


@pytest.fixture
def make_client(tmp_path, ecomed, notifier, recognizer) -> Iterator[Callable[..., TestClient]]:
    clients: list[TestClient] = []

    def factory(**overrides: Any) -> TestClient:
        app: FastAPI = create_app(
            build_settings(tmp_path, **overrides),
            ecomed_transport=httpx.MockTransport(ecomed.handle),
            password_reset_notifier=notifier,
            text_recognizer=recognizer,
        )
        Base.metadata.create_all(app.state.container.database.engine)
        client = TestClient(app)
        client.__enter__()
        clients.append(client)
        return client

    yield factory
    for client in clients:
        client.__exit__(None, None, None)


@pytest.fixture
def client(make_client) -> TestClient:
    return make_client()


def register(
    client: TestClient,
    email: str = "pessoa@example.com",
    password: str = "senha-segura-123",
    name: str = "Pessoa de Teste",
) -> dict:
    response = client.post(
        "/v1/auth/register", json={"name": name, "email": email, "password": password}
    )
    assert response.status_code == 201, response.text
    return response.json()


def auth_headers(tokens: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {tokens['access_token']}"}


@pytest.fixture
def user_headers(client) -> dict[str, str]:
    return auth_headers(register(client))


def body_text(response: httpx.Response) -> str:
    return json.dumps(response.json(), ensure_ascii=False)
