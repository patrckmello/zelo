"""Dependências das rotas: sessão do banco, contêiner e usuário autenticado."""

from collections.abc import Iterator
from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .container import AppContainer
from .errors import ApiError
from .models import User
from .security import decode_access_token

_bearer = HTTPBearer(auto_error=False)


def get_container(request: Request) -> AppContainer:
    return request.app.state.container


def get_db(container: Annotated[AppContainer, Depends(get_container)]) -> Iterator[Session]:
    yield from container.database.session()


def get_current_user(
    container: Annotated[AppContainer, Depends(get_container)],
    db: Annotated[Session, Depends(get_db)],
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> User:
    unauthenticated = ApiError(
        401,
        "not_authenticated",
        "Sessão inválida ou expirada. Entre novamente.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise unauthenticated
    user_id = decode_access_token(
        credentials.credentials, container.settings.jwt_secret.get_secret_value()
    )
    user = db.get(User, user_id) if user_id is not None else None
    if user is None:
        raise unauthenticated
    return user


def as_utc(value: datetime) -> datetime:
    """O SQLite devolve datas sem fuso; o PostgreSQL, com fuso."""
    return value if value.tzinfo is not None else value.replace(tzinfo=UTC)


ContainerDep = Annotated[AppContainer, Depends(get_container)]
DbDep = Annotated[Session, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
