"""Perfil da conta: dados, e-mail, senha e exclusão (direito de eliminação)."""

from fastapi import APIRouter, Response
from sqlalchemy import func, select

from ..container import AppContainer
from ..dependencies import ContainerDep, CurrentUser, DbDep
from ..errors import ApiError
from ..models import Disposal, Medication, User
from ..schemas import (
    AccountDeletion,
    AccountOut,
    AccountUpdate,
    EmailChange,
    PasswordChange,
    TokenPair,
)
from ..security import hash_password, verify_password
from ..services.sessions import issue_tokens, revoke_all_sessions

router = APIRouter(prefix="/account", tags=["conta"])


def _profile(db: DbDep, user: User) -> AccountOut:
    medications = db.scalar(
        select(func.count())
        .select_from(Medication)
        .where(Medication.user_id == user.id, Medication.disposed_at.is_(None))
    )
    disposals = db.scalar(
        select(func.count()).select_from(Disposal).where(Disposal.user_id == user.id)
    )
    return AccountOut(
        id=user.id,
        name=user.name,
        email=user.email,
        created_at=user.created_at,
        medications_count=medications or 0,
        disposals_count=disposals or 0,
    )


def _confirm_password(container: AppContainer, user: User, password: str) -> None:
    """Exige a senha atual, com o mesmo limite de tentativas do login."""
    key = f"conta|{user.id}"
    wait = container.login_limiter.try_acquire(key)
    if wait is not None:
        raise ApiError(
            429,
            "too_many_attempts",
            "Muitas tentativas. Aguarde alguns minutos.",
            headers={"Retry-After": str(max(int(wait), 1))},
        )
    if not verify_password(password, user.password_hash):
        raise ApiError(401, "invalid_password", "Senha atual incorreta.")
    container.login_limiter.reset(key)


@router.get("", response_model=AccountOut)
def get_account(user: CurrentUser, db: DbDep) -> AccountOut:
    return _profile(db, user)


@router.patch("", response_model=AccountOut)
def update_account(body: AccountUpdate, user: CurrentUser, db: DbDep) -> AccountOut:
    user.name = body.name
    db.commit()
    return _profile(db, user)


@router.post("/email", response_model=AccountOut)
def change_email(
    body: EmailChange, user: CurrentUser, container: ContainerDep, db: DbDep
) -> AccountOut:
    _confirm_password(container, user, body.current_password)
    email = body.new_email.lower()
    if email != user.email:
        taken = db.scalar(select(User.id).where(User.email == email, User.id != user.id))
        if taken is not None:
            raise ApiError(409, "email_already_registered", "Já existe uma conta com este e-mail.")
        user.email = email
        db.commit()
    return _profile(db, user)


@router.post("/password", response_model=TokenPair)
def change_password(
    body: PasswordChange, user: CurrentUser, container: ContainerDep, db: DbDep
) -> TokenPair:
    _confirm_password(container, user, body.current_password)
    if body.new_password == body.current_password:
        raise ApiError(422, "password_unchanged", "A nova senha precisa ser diferente da atual.")
    user.password_hash = hash_password(body.new_password)
    # Encerra as outras sessões e devolve uma nova para este aparelho.
    revoke_all_sessions(db, user.id)
    tokens = issue_tokens(container, db, user)
    db.commit()
    return tokens


@router.post("/delete", status_code=204)
def delete_account(
    body: AccountDeletion, user: CurrentUser, container: ContainerDep, db: DbDep
) -> Response:
    _confirm_password(container, user, body.current_password)
    # Remove conta, medicamentos, descartes, sessões e códigos de recuperação.
    db.delete(user)
    db.commit()
    return Response(status_code=204)
