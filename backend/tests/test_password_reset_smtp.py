"""Entrega do código de recuperação por SMTP (D043).

Nenhum teste abre conexão real: o servidor SMTP é simulado e as credenciais são
fictícias.
"""

import logging
import smtplib
from datetime import UTC, datetime, timedelta

import pytest
from pydantic import ValidationError

from app.container import AppContainer
from app.services.password_reset import (
    DisabledPasswordResetNotifier,
    OutboxPasswordResetNotifier,
    SmtpPasswordResetNotifier,
)

from .conftest import body_text, build_settings, register

SENHA_SMTP = "abcd-efgh-ijkl-mnop"


class FakeSmtp:
    """Registra a ordem das chamadas, como um servidor SMTP de teste."""

    def __init__(self, *, login_error: Exception | None = None) -> None:
        self.calls: list[object] = []
        self.messages = []
        self.login_error = login_error
        self.opened_with: tuple | None = None

    def factory(self, host, port, timeout=None):
        self.opened_with = (host, port, timeout)
        return self

    def __enter__(self):
        return self

    def __exit__(self, *exc) -> bool:
        self.calls.append("quit")
        return False

    def starttls(self, context=None) -> None:
        self.calls.append("starttls")

    def login(self, user: str, password: str) -> None:
        self.calls.append(("login", user, password))
        if self.login_error is not None:
            raise self.login_error

    def send_message(self, message) -> None:
        self.calls.append("send")
        self.messages.append(message)


def notifier_with(smtp: FakeSmtp, **overrides) -> SmtpPasswordResetNotifier:
    values = {
        "host": "smtp.example.test",
        "port": 587,
        "username": "zelo.demo@example.test",
        "password": SENHA_SMTP,
        "sender": "zelo.demo@example.test",
        "smtp_factory": smtp.factory,
    }
    values.update(overrides)
    return SmtpPasswordResetNotifier(**values)


def expires_in(minutes: int = 30) -> datetime:
    return datetime.now(UTC) + timedelta(minutes=minutes)


def test_envia_codigo_com_starttls_login_e_mensagem_em_portugues():
    smtp = FakeSmtp()
    notifier_with(smtp).send("pessoa@example.com", "CODIGO-123", expires_in())

    assert smtp.opened_with == ("smtp.example.test", 587, 10.0)
    assert smtp.calls == [
        "starttls",
        ("login", "zelo.demo@example.test", SENHA_SMTP),
        "send",
        "quit",
    ]
    message = smtp.messages[0]
    assert message["To"] == "pessoa@example.com"
    assert message["From"] == "Zelo <zelo.demo@example.test>"
    assert message["Subject"] == "Recuperação de acesso ao Zelo"
    text = message.get_content()
    assert "CODIGO-123" in text
    assert "vale por 30 minutos" in text


def test_modo_ssl_nao_usa_starttls():
    smtp = FakeSmtp()
    notifier_with(smtp, port=465, use_ssl=True).send("a@example.com", "T", expires_in())

    assert "starttls" not in smtp.calls
    assert smtp.calls[-2:] == ["send", "quit"]


def test_falha_de_rede_nao_vaza_erro_nem_codigo_nos_logs(caplog):
    def broken(host, port, timeout=None):
        raise ConnectionRefusedError("recusada")

    notifier = notifier_with(FakeSmtp(), smtp_factory=broken)
    with caplog.at_level(logging.INFO, logger="zelo.password_reset"):
        notifier.send("pessoa@example.com", "CODIGO-SECRETO", expires_in())

    assert "resultado=falhou" in caplog.text
    assert "ConnectionRefusedError" in caplog.text
    assert "CODIGO-SECRETO" not in caplog.text
    assert "pessoa@example.com" not in caplog.text


def test_falha_de_autenticacao_nao_registra_a_senha_do_aplicativo(caplog):
    smtp = FakeSmtp(login_error=smtplib.SMTPAuthenticationError(535, b"credenciais ruins"))
    with caplog.at_level(logging.INFO, logger="zelo.password_reset"):
        notifier_with(smtp).send("pessoa@example.com", "CODIGO-SECRETO", expires_in())

    assert smtp.messages == []
    assert "SMTPAuthenticationError" in caplog.text
    for secreto in (SENHA_SMTP, "CODIGO-SECRETO", "credenciais ruins"):
        assert secreto not in caplog.text


def test_sucesso_registra_apenas_canal_e_resultado(caplog):
    with caplog.at_level(logging.INFO, logger="zelo.password_reset"):
        notifier_with(FakeSmtp()).send("pessoa@example.com", "CODIGO-SECRETO", expires_in())

    assert "entrega=smtp resultado=enviado" in caplog.text
    assert "CODIGO-SECRETO" not in caplog.text


def smtp_settings(tmp_path, **overrides):
    values = {
        "ZELO_SMTP_HOST": "smtp.example.test",
        "ZELO_SMTP_USER": "zelo.demo@example.test",
        "ZELO_SMTP_PASSWORD": SENHA_SMTP,
    }
    values.update(overrides)
    return build_settings(tmp_path, **values)


def test_configuracao_smtp_incompleta_e_rejeitada(tmp_path):
    with pytest.raises(ValidationError, match="ZELO_SMTP_HOST"):
        build_settings(tmp_path, ZELO_SMTP_HOST="smtp.example.test")
    with pytest.raises(ValidationError, match="ZELO_SMTP_PASSWORD"):
        build_settings(tmp_path, ZELO_SMTP_USER="zelo.demo@example.test")


def test_valores_em_branco_do_env_contam_como_ausentes(tmp_path):
    settings = build_settings(
        tmp_path, ZELO_SMTP_HOST="", ZELO_SMTP_USER=" ", ZELO_SMTP_PASSWORD="", ZELO_SMTP_FROM=""
    )

    assert settings.smtp_configured is False
    assert settings.smtp_sender is None


def test_senha_smtp_nao_aparece_na_representacao_das_configuracoes(tmp_path):
    assert SENHA_SMTP not in repr(smtp_settings(tmp_path))


def test_container_prefere_smtp_a_caixa_local(tmp_path):
    settings = smtp_settings(tmp_path, ZELO_PASSWORD_RESET_OUTBOX_DIR=str(tmp_path / "outbox"))
    container = AppContainer.build(settings)
    try:
        notifier = container.password_reset_notifier
        assert isinstance(notifier, SmtpPasswordResetNotifier)
        assert notifier.sender == "zelo.demo@example.test"
        assert notifier.use_ssl is False
    finally:
        container.close()


def test_container_usa_remetente_e_ssl_configurados(tmp_path):
    settings = smtp_settings(
        tmp_path,
        ZELO_SMTP_FROM="noreply@example.test",
        ZELO_SMTP_PORT=465,
        ZELO_SMTP_SECURITY="ssl",
    )
    container = AppContainer.build(settings)
    try:
        notifier = container.password_reset_notifier
        assert isinstance(notifier, SmtpPasswordResetNotifier)
        assert (notifier.sender, notifier.port, notifier.use_ssl) == (
            "noreply@example.test",
            465,
            True,
        )
    finally:
        container.close()


@pytest.mark.parametrize(
    ("overrides", "expected"),
    [
        ({}, DisabledPasswordResetNotifier),
        ({"ZELO_PASSWORD_RESET_OUTBOX_DIR": "outbox"}, OutboxPasswordResetNotifier),
        (
            {"ZELO_ENV": "production", "ZELO_PASSWORD_RESET_OUTBOX_DIR": "outbox"},
            DisabledPasswordResetNotifier,
        ),
    ],
)
def test_container_sem_smtp_mantem_o_comportamento_anterior(tmp_path, overrides, expected):
    container = AppContainer.build(build_settings(tmp_path, **overrides))
    try:
        assert isinstance(container.password_reset_notifier, expected)
    finally:
        container.close()


def test_recuperacao_pela_api_entrega_o_codigo_por_smtp(make_client):
    client = make_client()
    smtp = FakeSmtp()
    client.app.state.container.password_reset_notifier = notifier_with(smtp)
    register(client)

    desconhecido = client.post("/v1/auth/password-reset/request", json={"email": "x@example.com"})
    conhecido = client.post("/v1/auth/password-reset/request", json={"email": "pessoa@example.com"})

    assert desconhecido.status_code == conhecido.status_code == 202
    assert desconhecido.json() == conhecido.json()
    assert len(smtp.messages) == 1  # só a conta existente recebe e-mail
    # O código é a única linha longa do corpo sem espaços.
    code = next(
        line.strip()
        for line in smtp.messages[0].get_content().splitlines()
        if len(line.strip()) >= 16 and " " not in line.strip()
    )
    confirmed = client.post(
        "/v1/auth/password-reset/confirm",
        json={"token": code, "new_password": "nova-senha-segura-456"},
    )
    assert confirmed.status_code == 204, body_text(confirmed)
