from datetime import date, timedelta

from .conftest import auth_headers, register


def _medication(client, headers, name, quantity=1, expiration="2026-09-01"):
    response = client.post(
        "/v1/medications",
        json={"name": name, "expiration_date": expiration, "quantity": quantity},
        headers=headers,
    )
    return response.json()["id"]


def test_registra_descarte_e_retira_itens_da_farmacia(client, user_headers):
    soro = _medication(client, user_headers, "Soro fisiológico", quantity=1)
    xarope = _medication(client, user_headers, "Xarope", quantity=2, expiration="2026-08-15")
    keep = _medication(client, user_headers, "Dipirona", expiration="2027-12-01")

    response = client.post(
        "/v1/disposals",
        json={
            "medication_ids": [soro, xarope, soro],
            "disposed_on": date.today().isoformat(),
            "point": {
                "external_id": "logmed-001234",
                "name": "Farmácia Exemplo - Centro",
                "address": "Rua das Flores, 100",
            },
        },
        headers=user_headers,
    )
    assert response.status_code == 201, response.text
    disposal = response.json()
    assert disposal["point_name"] == "Farmácia Exemplo - Centro"
    assert [item["medication_name"] for item in disposal["items"]] == [
        "Soro fisiológico",
        "Xarope",
    ]
    assert disposal["items"][1] == {
        "medication_name": "Xarope",
        "quantity": 2,
        "expiration_date": "2026-08-15",
    }

    active = client.get("/v1/medications", headers=user_headers).json()
    assert [item["id"] for item in active] == [keep]
    history = client.get("/v1/disposals", headers=user_headers).json()
    assert [entry["id"] for entry in history] == [disposal["id"]]

    again = client.post(
        "/v1/disposals",
        json={"medication_ids": [soro], "disposed_on": date.today().isoformat()},
        headers=user_headers,
    )
    assert again.status_code == 404


def test_descarte_sem_ponto_informado_e_permitido(client, user_headers):
    medication = _medication(client, user_headers, "Pomada")
    response = client.post(
        "/v1/disposals",
        json={"medication_ids": [medication], "disposed_on": date.today().isoformat()},
        headers=user_headers,
    )
    assert response.status_code == 201
    assert response.json()["point_name"] is None


def test_descarte_rejeita_itens_de_outra_conta_e_data_futura(client):
    owner = auth_headers(register(client, email="dona@example.com"))
    other = auth_headers(register(client, email="outra@example.com"))
    medication = _medication(client, owner, "Soro")

    foreign = client.post(
        "/v1/disposals",
        json={"medication_ids": [medication], "disposed_on": date.today().isoformat()},
        headers=other,
    )
    future = client.post(
        "/v1/disposals",
        json={
            "medication_ids": [medication],
            "disposed_on": (date.today() + timedelta(days=5)).isoformat(),
        },
        headers=owner,
    )
    assert foreign.status_code == 404
    assert future.status_code == 422
    assert client.get("/v1/disposals", headers=other).json() == []
