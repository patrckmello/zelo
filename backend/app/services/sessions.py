"""Emissão e revogação de sessões, compartilhadas por autenticação e conta."""

import uuid
from datetime import timedelta

from sqlalchemy import update
from sqlalchemy.orm import Session

from ..container import AppContainer
from ..models import RefreshSession, User, utc_now
from ..schemas import TokenPair, UserOut
from ..security import create_access_token, hash_opaque_token, new_opaque_token


def issue_tokens(container: AppContainer, db: Session, user: User) -> TokenPair:
    settings = container.settings
    access_token, expires_in = create_access_token(
        user.id, settings.jwt_secret.get_secret_value(), settings.access_token_minutes
    )
    refresh_token = new_opaque_token()
    db.add(
        RefreshSession(
            user_id=user.id,
            token_hash=hash_opaque_token(refresh_token),
            expires_at=utc_now() + timedelta(days=settings.refresh_token_days),
        )
    )
    return TokenPair(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
        user=UserOut.model_validate(user),
    )


def revoke_all_sessions(db: Session, user_id: uuid.UUID) -> None:
    db.execute(
        update(RefreshSession)
        .where(RefreshSession.user_id == user_id, RefreshSession.revoked_at.is_(None))
        .values(revoked_at=utc_now())
    )
