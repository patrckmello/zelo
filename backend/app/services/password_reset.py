"""Entrega do código de recuperação de senha.

Ainda não há provedor de e-mail definido (PENDENTE). No desenvolvimento, o
código pode ser gravado em uma caixa de saída local ignorada pelo Git; nunca
em logs. Sem caixa configurada, a entrega fica desativada.
"""

import logging
import uuid
from datetime import UTC, datetime
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
