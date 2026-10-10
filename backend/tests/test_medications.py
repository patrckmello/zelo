from .conftest import auth_headers, register


def _create(client, headers, **overrides):
    payload = {
        "name": "Dipirona",
        "expiration_date": "2027-01-10",
        "quantity": 8,
        "notes": "Armário da cozinha",
    }
    payload.update(overrides)
    response = client.post("/v1/medications", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


def test_exige_autenticacao(client):
    assert client.get("/v1/medications").status_code == 401


def test_crud_completo_normaliza_e_ordena_por_validade(client, user_headers):
    later = _create(client, user_headers, name="  Dipirona  ", expiration_date="2027-05-01")
    sooner = _create(client, user_headers, name="Loratadina", expiration_date="2026-11-01")

    assert later["name"] == "Dipirona"
    listed = client.get("/v1/medications", headers=user_headers).json()
    assert [item["id"] for item in listed] == [sooner["id"], later["id"]]

    updated = client.put(
        f"/v1/medications/{later['id']}",
        json={"name": "Dipirona gotas", "expiration_date": "2027-06-01", "quantity": 1},
        headers=user_headers,
    )
    assert updated.status_code == 200
    assert updated.json()["notes"] == ""
    assert updated.json()["quantity"] == 1

    assert client.delete(f"/v1/medications/{sooner['id']}", headers=user_headers).status_code == 204
    remaining = client.get("/v1/medications", headers=user_headers).json()
    assert [item["name"] for item in remaining] == ["Dipirona gotas"]


def test_valida_quantidade_e_nome(client, user_headers):
    zero = client.post(
        "/v1/medications",
        json={"name": "X", "expiration_date": "2027-01-01", "quantity": 0},
        headers=user_headers,
    )
    blank = client.post(
        "/v1/medications",
        json={"name": "   ", "expiration_date": "2027-01-01", "quantity": 1},
        headers=user_headers,
    )
    assert zero.status_code == blank.status_code == 422


def test_isola_medicamentos_entre_contas(client):
    owner = auth_headers(register(client, email="dona@example.com"))
    other = auth_headers(register(client, email="outra@example.com"))
    medication = _create(client, owner)

    assert client.get("/v1/medications", headers=other).json() == []
    payload = {"name": "Alterado", "expiration_date": "2027-01-01", "quantity": 2}
    assert (
        client.put(f"/v1/medications/{medication['id']}", json=payload, headers=other).status_code
        == 404
    )
    assert client.delete(f"/v1/medications/{medication['id']}", headers=other).status_code == 404
    assert len(client.get("/v1/medications", headers=owner).json()) == 1
