"""Senhas, tokens de acesso e tokens opacos.

- Senhas: Argon2id (argon2-cffi), nunca armazenadas ou registradas em claro.
- Acesso: JWT HS256 de curta duração com `sub`, `type`, `iat` e `exp`.
- Renovação e recuperação: valores aleatórios entregues uma única vez ao
  cliente; o banco guarda somente o SHA-256.
"""

import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

_hasher = PasswordHasher()

ACCESS_TOKEN_TYPE = "access"  # noqa: S105 - tipo de token, não segredo
JWT_ALGORITHM = "HS256"

# Hash calculado uma vez para equalizar o tempo de resposta quando o e-mail
# não existe, reduzindo a enumeração de contas por tempo.
_DUMMY_HASH = _hasher.hash(secrets.token_urlsafe(16))


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    try:
        return _hasher.verify(password_hash or _DUMMY_HASH, password) and bool(password_hash)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def password_needs_rehash(password_hash: str) -> bool:
    return _hasher.check_needs_rehash(password_hash)


def create_access_token(
    user_id: uuid.UUID, secret: str, minutes: int, now: datetime | None = None
) -> tuple[str, int]:
    issued_at = now or datetime.now(UTC)
    expires_in = minutes * 60
    payload = {
        "sub": str(user_id),
        "type": ACCESS_TOKEN_TYPE,
        "iat": int(issued_at.timestamp()),
        "exp": int((issued_at + timedelta(seconds=expires_in)).timestamp()),
    }
    return jwt.encode(payload, secret, algorithm=JWT_ALGORITHM), expires_in


def decode_access_token(token: str, secret: str) -> uuid.UUID | None:
    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=[JWT_ALGORITHM],
            options={"require": ["sub", "exp", "iat", "type"]},
        )
        if payload.get("type") != ACCESS_TOKEN_TYPE:
            return None
        return uuid.UUID(payload["sub"])
    except (jwt.PyJWTError, ValueError):
        return None


def new_opaque_token() -> str:
    return secrets.token_urlsafe(32)


def hash_opaque_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
