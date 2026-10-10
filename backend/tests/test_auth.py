from sqlalchemy import select

from app.models import User

from .conftest import auth_headers, body_text, register


def test_cadastro_devolve_tokens_e_armazena_somente_hash(client):
    tokens = register(client, email="Pessoa@Example.com")

    assert tokens["token_type"] == "bearer"
    assert tokens["expires_in"] == 15 * 60
    assert tokens["user"]["email"] == "pessoa@example.com"
    with client.app.state.container.database.session_factory() as db:
        user = db.scalar(select(User))
        assert user.password_hash.startswith("$argon2id$")
        assert "senha-segura-123" not in user.password_hash


def test_cadastro_rejeita_email_duplicado_sem_diferenciar_maiusculas(client):
    register(client)
    response = client.post(
        "/v1/auth/register",
        json={"name": "Outra", "email": "PESSOA@example.com", "password": "outra-senha-1"},
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "email_already_registered"


def test_cadastro_exige_senha_com_oito_caracteres(client):
    response = client.post(
        "/v1/auth/register",
        json={"name": "Pessoa", "email": "p@example.com", "password": "curta"},
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"
    assert "curta" not in body_text(response)


def test_login_valido_e_mensagem_generica_para_falhas(client):
    register(client)

    ok = client.post(
        "/v1/auth/login", json={"email": "pessoa@example.com", "password": "senha-segura-123"}
    )
    wrong_password = client.post(
        "/v1/auth/login", json={"email": "pessoa@example.com", "password": "errada-123"}
    )
    unknown = client.post(
        "/v1/auth/login", json={"email": "ninguem@example.com", "password": "errada-123"}
    )

    assert ok.status_code == 200
    assert wrong_password.status_code == unknown.status_code == 401
    assert wrong_password.json() == unknown.json()


def test_login_limita_tentativas_repetidas(make_client):
    client = make_client(ZELO_LOGIN_ATTEMPTS=3)
    register(client)
    payload = {"email": "pessoa@example.com", "password": "errada-123"}

    codes = [client.post("/v1/auth/login", json=payload).status_code for _ in range(4)]

    assert codes == [401, 401, 401, 429]
    blocked = client.post("/v1/auth/login", json=payload)
    assert blocked.json()["error"]["code"] == "too_many_attempts"
    assert int(blocked.headers["Retry-After"]) >= 1


def test_me_exige_token_valido(client):
    tokens = register(client)

    assert client.get("/v1/auth/me", headers=auth_headers(tokens)).json()["name"] == (
        "Pessoa de Teste"
    )
    assert client.get("/v1/auth/me").status_code == 401
    invalid = client.get("/v1/auth/me", headers={"Authorization": "Bearer invalido"})
    assert invalid.status_code == 401
    assert invalid.json()["error"]["code"] == "not_authenticated"


def test_refresh_troca_o_token_e_detecta_reuso(client):
    first = register(client)
    second = client.post("/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert second.status_code == 200
    second_tokens = second.json()
    assert second_tokens["refresh_token"] != first["refresh_token"]

    reused = client.post("/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    assert reused.status_code == 401

    # O reuso encerra também a sessão mais recente da mesma conta.
    after_reuse = client.post(
        "/v1/auth/refresh", json={"refresh_token": second_tokens["refresh_token"]}
    )
    assert after_reuse.status_code == 401


def test_logout_revoga_o_token_de_renovacao(client):
    tokens = register(client)

    assert (
        client.post("/v1/auth/logout", json={"refresh_token": tokens["refresh_token"]}).status_code
        == 204
    )
    assert (
        client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}).status_code
        == 401
    )


def test_recuperacao_nao_revela_conta_e_troca_a_senha(client, notifier):
    tokens = register(client)

    unknown = client.post("/v1/auth/password-reset/request", json={"email": "x@example.com"})
    known = client.post("/v1/auth/password-reset/request", json={"email": "pessoa@example.com"})
    assert unknown.status_code == known.status_code == 202
    assert unknown.json() == known.json()
    assert len(notifier.sent) == 1
    email, code = notifier.sent[0]
    assert email == "pessoa@example.com"

    confirm = client.post(
        "/v1/auth/password-reset/confirm",
        json={"token": code, "new_password": "nova-senha-456"},
    )
    assert confirm.status_code == 204
    assert (
        client.post(
            "/v1/auth/password-reset/confirm",
            json={"token": code, "new_password": "outra-senha-789"},
        ).status_code
        == 400
    )
    assert (
        client.post(
            "/v1/auth/login", json={"email": "pessoa@example.com", "password": "nova-senha-456"}
        ).status_code
        == 200
    )
    # Sessões anteriores são encerradas após a troca de senha.
    assert (
        client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}).status_code
        == 401
    )


def test_recuperacao_rejeita_codigo_invalido(client):
    response = client.post(
        "/v1/auth/password-reset/confirm",
        json={"token": "codigo-inexistente-0000", "new_password": "nova-senha-456"},
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_reset_token"
