"""Entrega do código de recuperação de senha.

Há três formas, escolhidas pela configuração (ver `AppContainer`):

- SMTP (D043): envia o código por e-mail com uma conta dedicada e senha de
  aplicativo, adequado à demonstração; um provedor transacional com domínio
  próprio continua PENDENTE para uso real;
- caixa de saída local, só em desenvolvimento, ignorada pelo Git;
- desativada, quando nada está configurado.

O código nunca vai para logs: o registro diz apenas o canal e o resultado.
"""

import logging
import smtplib
import ssl
import uuid
from collections.abc import Callable
from datetime import UTC, datetime
from email.message import EmailMessage
from email.utils import formataddr
from pathlib import Path
from typing import Protocol

logger = logging.getLogger("zelo.password_reset")


class PasswordResetNotifier(Protocol):
    def send(self, email: str, token: str, expires_at: datetime) -> None: ...


class DisabledPasswordResetNotifier:
    def send(self, email: str, token: str, expires_at: datetime) -> None:
        logger.info("recuperacao_solicitada entrega=desativada")


class OutboxPasswordResetNotifier:
    """Grava cada mensagem em um arquivo local, somente para desenvolvimento."""

    def __init__(self, directory: Path) -> None:
        self.directory = directory

    def send(self, email: str, token: str, expires_at: datetime) -> None:
        self.directory.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
        path = self.directory / f"{stamp}-{uuid.uuid4().hex[:8]}.txt"
        path.write_text(
            "Assunto: Recuperação de acesso ao Zelo\n"
            f"Para: {email}\n\n"
            "Use o código abaixo no aplicativo para criar uma nova senha:\n\n"
            f"{token}\n\n"
            f"Válido até {expires_at.astimezone(UTC):%d/%m/%Y %H:%M} (UTC).\n",
            encoding="utf-8",
        )
        logger.info("recuperacao_solicitada entrega=caixa_local")


def build_reset_message(
    *, sender: str, recipient: str, token: str, expires_at: datetime
) -> EmailMessage:
    minutes = max(1, round((expires_at - datetime.now(UTC)).total_seconds() / 60))
    message = EmailMessage()
    message["Subject"] = "Recuperação de acesso ao Zelo"
    message["From"] = formataddr(("Zelo", sender))
    message["To"] = recipient
    message.set_content(
        "\n".join(
            [
                "Olá!",
                "",
                "Recebemos um pedido para criar uma nova senha no Zelo. Digite o código "
                "abaixo no aplicativo:",
                "",
                token,
                "",
                f"O código vale por {minutes} minutos e só pode ser usado uma vez.",
                "Se não foi você, ignore esta mensagem: sua senha continua a mesma.",
                "",
            ]
        )
    )
    return message


class SmtpPasswordResetNotifier:
    """Envia o código por SMTP (STARTTLS na 587 ou SSL na 465).

    Falhas de rede ou de autenticação são registradas sem detalhes sensíveis e
    não chegam ao cliente: a resposta da API é a mesma com ou sem conta.
    """

    def __init__(
        self,
        *,
        host: str,
        port: int,
        username: str,
        password: str,
        sender: str,
        use_ssl: bool = False,
        timeout_seconds: float = 10.0,
        smtp_factory: Callable[..., smtplib.SMTP] | None = None,
    ) -> None:
        self.host = host
        self.port = port
        self.username = username
        self._password = password
        self.sender = sender
        self.use_ssl = use_ssl
        self.timeout_seconds = timeout_seconds
        self._smtp_factory = smtp_factory

    def _connect(self) -> smtplib.SMTP:
        if self._smtp_factory is not None:
            return self._smtp_factory(self.host, self.port, timeout=self.timeout_seconds)
        if self.use_ssl:
            return smtplib.SMTP_SSL(
                self.host,
                self.port,
                timeout=self.timeout_seconds,
                context=ssl.create_default_context(),
            )
        return smtplib.SMTP(self.host, self.port, timeout=self.timeout_seconds)

    def send(self, email: str, token: str, expires_at: datetime) -> None:
        message = build_reset_message(
            sender=self.sender, recipient=email, token=token, expires_at=expires_at
        )
        try:
            with self._connect() as smtp:
                if not self.use_ssl:
                    smtp.starttls(context=ssl.create_default_context())
                smtp.login(self.username, self._password)
                smtp.send_message(message)
        except (OSError, smtplib.SMTPException) as error:
            logger.warning(
                "recuperacao_solicitada entrega=smtp resultado=falhou erro=%s",
                type(error).__name__,
            )
            return
        logger.info("recuperacao_solicitada entrega=smtp resultado=enviado")
