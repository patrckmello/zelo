import logging

import httpx

from .conftest import TEST_ECOMED_KEY, body_text

NEARBY = "/v1/collection-points/nearby"


def test_exige_autenticacao(client):
    assert client.get(NEARBY, params={"latitude": -30, "longitude": -51}).status_code == 401


def test_sem_chave_informa_que_nao_esta_configurado(make_client, ecomed):
    from .conftest import auth_headers, register

    client = make_client(ECOMED_API_KEY="")
    headers = auth_headers(register(client))
    response = client.get(NEARBY, params={"latitude": -30, "longitude": -51}, headers=headers)

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "collection_points_not_configured"
    assert ecomed.requests == []
    assert client.get("/health").json()["ecomed_configured"] is False


def test_consulta_normaliza_e_envia_coordenadas_arredondadas(client, ecomed, user_headers):
    response = client.get(
        NEARBY,
        params={"latitude": -23.550512, "longitude": -46.633308, "radius_m": 5000},
        headers=user_headers,
    )

    assert response.status_code == 200, response.text
    body = response.json()
    request = ecomed.requests[0]
    assert request.headers["X-API-Key"] == TEST_ECOMED_KEY
    assert request.url.path == "/api/public/v1/pontos/proximos"
    assert request.url.params["lat"] == "-23.551"
    assert request.url.params["lng"] == "-46.633"
    assert request.url.params["raio"] == "5000"

    assert body["count"] == 2  # o ponto sem coordenadas é descartado
    assert body["cache"] == "miss"
    assert body["attribution"].startswith("Dados: EcoMed")
    pharmacy, unit = body["points"]
    assert pharmacy["origin"] == "logmed"
    assert pharmacy["requires_confirmation"] is False
    assert pharmacy["distance_m"] == 412
    assert unit == {
        "id": "exemplo-ubs-1",
        "name": "Unidade de Saúde Exemplo",
        "address": "Rua Fictícia, 45",
        "city": "São Paulo",
        "state": "SP",
        "latitude": -23.5602,
        "longitude": -46.6455,
        "phone": None,
        "residue_types": ["medicamento", "seringa"],
        "distance_m": 3100,
        "origin": "other",
        "requires_confirmation": True,
    }
    assert TEST_ECOMED_KEY not in body_text(response)


def test_cache_reutiliza_buscas_no_mesmo_quadrante(client, ecomed, user_headers):
    first = client.get(
        NEARBY, params={"latitude": -30.03461, "longitude": -51.21771}, headers=user_headers
    )
    # -30.03452/-51.21758 arredondam para o mesmo par (-30.035, -51.218).
    second = client.get(
        NEARBY, params={"latitude": -30.03452, "longitude": -51.21758}, headers=user_headers
    )
    other_radius = client.get(
        NEARBY,
        params={"latitude": -30.03452, "longitude": -51.21758, "radius_m": 10000},
        headers=user_headers,
    )

    assert first.json()["cache"] == "miss"
    assert second.json()["cache"] == "hit"
    assert other_radius.json()["cache"] == "miss"
    assert len(ecomed.requests) == 2


def test_valida_limites_dos_parametros(client, user_headers):
    too_small = client.get(
        NEARBY, params={"latitude": -30, "longitude": -51, "radius_m": 100}, headers=user_headers
    )
    invalid_latitude = client.get(
        NEARBY, params={"latitude": -91, "longitude": -51}, headers=user_headers
    )
    assert too_small.status_code == invalid_latitude.status_code == 422
    assert "-91" not in body_text(invalid_latitude)


def test_limite_local_protege_a_cota_compartilhada(make_client, ecomed):
    from .conftest import auth_headers, register

    client = make_client(ECOMED_RATE_LIMIT_PER_MINUTE=2, ECOMED_CACHE_TTL_SECONDS=0)
    headers = auth_headers(register(client))
    statuses = [
        client.get(
            NEARBY, params={"latitude": -30 + index, "longitude": -51}, headers=headers
        ).status_code
        for index in range(3)
    ]

    assert statuses == [200, 200, 503]
    assert len(ecomed.requests) == 2


def test_limite_da_ecomed_vira_503_com_retry_after(client, ecomed, user_headers):
    ecomed.respond = lambda request: httpx.Response(429, headers={"Retry-After": "12"})
    response = client.get(NEARBY, params={"latitude": -30, "longitude": -51}, headers=user_headers)

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "collection_points_rate_limited"
    assert response.headers["Retry-After"] == "12"


def test_chave_recusada_nao_expoe_segredo_nem_coordenadas(client, ecomed, user_headers, caplog):
    ecomed.respond = lambda request: httpx.Response(401, json={"error": "invalid key"})
    with caplog.at_level(logging.INFO):
        response = client.get(
            NEARBY, params={"latitude": -30.0346, "longitude": -51.2177}, headers=user_headers
        )

    assert response.status_code == 502
    assert response.json()["error"]["code"] == "collection_points_unavailable"
    assert TEST_ECOMED_KEY not in body_text(response)
    assert TEST_ECOMED_KEY not in caplog.text
    assert "-30.03" not in caplog.text and "-51.21" not in caplog.text


def test_timeout_e_resposta_invalida_sao_tratados(client, ecomed, user_headers):
    def timeout(request):
        raise httpx.ReadTimeout("tempo esgotado", request=request)

    ecomed.respond = timeout
    slow = client.get(NEARBY, params={"latitude": -30, "longitude": -51}, headers=user_headers)
    ecomed.respond = lambda request: httpx.Response(200, content=b"<html>erro</html>")
    broken = client.get(NEARBY, params={"latitude": -31, "longitude": -51}, headers=user_headers)
    ecomed.respond = lambda request: httpx.Response(200, json={"inesperado": True})
    unexpected = client.get(
        NEARBY, params={"latitude": -32, "longitude": -51}, headers=user_headers
    )

    assert slow.status_code == 504
    assert broken.status_code == unexpected.status_code == 502


def test_detalhe_do_ponto_e_id_invalido(client, ecomed, user_headers):
    found = client.get("/v1/collection-points/logmed-001234", headers=user_headers)
    invalid = client.get("/v1/collection-points/id..invalido", headers=user_headers)

    assert found.status_code == 200
    assert found.json()["origin"] == "logmed"
    assert invalid.status_code == 404
    assert [request.url.path for request in ecomed.requests] == [
        "/api/public/v1/pontos/logmed-001234"
    ]
