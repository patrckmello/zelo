from .conftest import auth_headers, register


def test_perfil_mostra_contagens_e_atualiza_nome(client):
    headers = auth_headers(register(client))
    client.post(
        "/v1/medications",
        json={"name": "Dipirona", "expiration_date": "2027-01-01", "quantity": 1},
        headers=headers,
    )

    profile = client.get("/v1/account", headers=headers).json()
    assert profile["medications_count"] == 1
    assert profile["disposals_count"] == 0

    updated = client.patch("/v1/account", json={"name": "  Ana  "}, headers=headers)
    assert updated.status_code == 200
    assert updated.json()["name"] == "Ana"


def test_troca_de_senha_exige_senha_atual_e_renova_sessao(client):
    tokens = register(client)
    headers = auth_headers(tokens)

    wrong = client.post(
        "/v1/account/password",
        json={"current_password": "errada-000", "new_password": "nova-senha-456"},
        headers=headers,
    )
    assert wrong.status_code == 401

    changed = client.post(
        "/v1/account/password",
        json={"current_password": "senha-segura-123", "new_password": "nova-senha-456"},
        headers=headers,
    )
    assert changed.status_code == 200
    assert (
        client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}).status_code
        == 401
    )
    assert (
        client.post(
            "/v1/auth/login", json={"email": "pessoa@example.com", "password": "nova-senha-456"}
        ).status_code
        == 200
    )


def test_troca_de_email_e_exclusao_da_conta(client):
    register(client, email="outra@example.com")
    headers = auth_headers(register(client))

    taken = client.post(
        "/v1/account/email",
        json={"new_email": "outra@example.com", "current_password": "senha-segura-123"},
        headers=headers,
    )
    assert taken.status_code == 409
    moved = client.post(
        "/v1/account/email",
        json={"new_email": "nova@example.com", "current_password": "senha-segura-123"},
        headers=headers,
    )
    assert moved.json()["email"] == "nova@example.com"

    deleted = client.post(
        "/v1/account/delete", json={"current_password": "senha-segura-123"}, headers=headers
    )
    assert deleted.status_code == 204
    assert client.get("/v1/account", headers=headers).status_code == 401
    assert (
        client.post(
            "/v1/auth/login", json={"email": "nova@example.com", "password": "senha-segura-123"}
        ).status_code
        == 401
    )
