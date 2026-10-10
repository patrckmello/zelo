"""Cadastro, login, renovação, logout e recuperação de senha."""

from datetime import timedelta

from fastapi import APIRouter, Request, Response
from sqlalchemy import select

from ..dependencies import ContainerDep, CurrentUser, DbDep, as_utc
from ..errors import ApiError
from ..models import PasswordResetToken, RefreshSession, User, utc_now
from ..schemas import (
    LoginRequest,
    PasswordResetConfirm,
    PasswordResetRequest,
    RefreshRequest,
    RegisterRequest,
    TokenPair,
    UserOut,
)
from ..security import (
    hash_opaque_token,
    hash_password,
    new_opaque_token,
    password_needs_rehash,
    verify_password,
)
from ..services.sessions import issue_tokens, revoke_all_sessions

router = APIRouter(prefix="/auth", tags=["autenticação"])

_INVALID_REFRESH = ApiError(401, "invalid_refresh_token", "Sessão expirada. Entre novamente.")


@router.post("/register", status_code=201, response_model=TokenPair)
def register(body: RegisterRequest, container: ContainerDep, db: DbDep) -> TokenPair:
    email = body.email.lower()
    if db.scalar(select(User.id).where(User.email == email)) is not None:
        raise ApiError(409, "email_already_registered", "Já existe uma conta com este e-mail.")
    user = User(name=body.name, email=email, password_hash=hash_password(body.password))
    db.add(user)
    db.flush()
    tokens = issue_tokens(container, db, user)
    db.commit()
    return tokens


@router.post("/login", response_model=TokenPair)
def login(body: LoginRequest, request: Request, container: ContainerDep, db: DbDep) -> TokenPair:
    email = body.email.lower()
    client = request.client.host if request.client else "desconhecido"
    attempt_key = f"{client}|{email}"
    wait = container.login_limiter.try_acquire(attempt_key)
    if wait is not None:
        raise ApiError(
            429,
            "too_many_attempts",
            "Muitas tentativas de acesso. Aguarde alguns minutos.",
            headers={"Retry-After": str(max(int(wait), 1))},
        )

    user = db.scalar(select(User).where(User.email == email))
    if not verify_password(body.password, user.password_hash if user else None):
        raise ApiError(401, "invalid_credentials", "E-mail ou senha inválidos.")
    assert user is not None
    if password_needs_rehash(user.password_hash):
        user.password_hash = hash_password(body.password)

    tokens = issue_tokens(container, db, user)
    db.commit()
    container.login_limiter.reset(attempt_key)
    return tokens


@router.post("/refresh", response_model=TokenPair)
def refresh(body: RefreshRequest, container: ContainerDep, db: DbDep) -> TokenPair:
    session = db.scalar(
        select(RefreshSession).where(
            RefreshSession.token_hash == hash_opaque_token(body.refresh_token)
        )
    )
    if session is None:
        raise _INVALID_REFRESH
    if session.revoked_at is not None:
        # Reuso de um token já trocado indica vazamento: encerra tudo.
        revoke_all_sessions(db, session.user_id)
        db.commit()
        raise _INVALID_REFRESH
    if as_utc(session.expires_at) <= utc_now():
        raise _INVALID_REFRESH

    session.revoked_at = utc_now()
    user = db.get(User, session.user_id)
    if user is None:
        raise _INVALID_REFRESH
    tokens = issue_tokens(container, db, user)
    db.commit()
    return tokens


@router.post("/logout", status_code=204)
def logout(body: RefreshRequest, db: DbDep) -> Response:
    session = db.scalar(
        select(RefreshSession).where(
            RefreshSession.token_hash == hash_opaque_token(body.refresh_token)
        )
    )
    if session is not None and session.revoked_at is None:
        session.revoked_at = utc_now()
        db.commit()
    return Response(status_code=204)


@router.get("/me", response_model=UserOut)
def me(user: CurrentUser) -> User:
    return user


@router.post("/password-reset/request", status_code=202)
def request_password_reset(
    body: PasswordResetRequest, container: ContainerDep, db: DbDep
) -> dict[str, str]:
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    if user is not None:
        token = new_opaque_token()
        expires_at = utc_now() + timedelta(minutes=container.settings.password_reset_minutes)
        db.add(
            PasswordResetToken(
                user_id=user.id,
                token_hash=hash_opaque_token(token),
                expires_at=expires_at,
            )
        )
        db.commit()
        container.password_reset_notifier.send(user.email, token, expires_at)
    # Mesma resposta com ou sem conta, para não revelar e-mails cadastrados.
    return {
        "message": "Se houver uma conta para este e-mail, enviaremos as instruções de recuperação."
    }


@router.post("/password-reset/confirm", status_code=204)
def confirm_password_reset(body: PasswordResetConfirm, db: DbDep) -> Response:
    record = db.scalar(
        select(PasswordResetToken).where(
            PasswordResetToken.token_hash == hash_opaque_token(body.token)
        )
    )
    if record is None or record.used_at is not None or as_utc(record.expires_at) <= utc_now():
        raise ApiError(400, "invalid_reset_token", "Código inválido ou expirado.")
    user = db.get(User, record.user_id)
    if user is None:
        raise ApiError(400, "invalid_reset_token", "Código inválido ou expirado.")

    user.password_hash = hash_password(body.new_password)
    record.used_at = utc_now()
    revoke_all_sessions(db, user.id)
    db.commit()
    return Response(status_code=204)
