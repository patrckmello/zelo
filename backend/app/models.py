"""Modelo relacional da API Zelo.

Medicamentos são dados indiretos de saúde (D018): pertencem sempre a um
usuário e só são acessados por consultas filtradas pelo dono.
"""

import uuid
from datetime import UTC, date, datetime

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def utc_now() -> datetime:
    return datetime.now(UTC)


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(254), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    medications: Mapped[list["Medication"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class RefreshSession(Base):
    """Token de renovação opaco; somente o hash SHA-256 é armazenado."""

    __tablename__ = "refresh_sessions"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)


class PasswordResetToken(Base):
    """Token de recuperação de uso único; somente o hash é armazenado."""

    __tablename__ = "password_reset_tokens"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)


class Disposal(Base):
    """Descarte registrado pelo usuário, com cópia dos itens entregues."""

    __tablename__ = "disposals"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    disposed_on: Mapped[date] = mapped_column(Date)
    point_external_id: Mapped[str | None] = mapped_column(String(64), default=None)
    point_name: Mapped[str | None] = mapped_column(String(200), default=None)
    point_address: Mapped[str | None] = mapped_column(String(300), default=None)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    items: Mapped[list["DisposalItem"]] = relationship(
        back_populates="disposal",
        cascade="all, delete-orphan",
        order_by="DisposalItem.position",
    )


class DisposalItem(Base):
    __tablename__ = "disposal_items"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    disposal_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("disposals.id", ondelete="CASCADE"), index=True
    )
    position: Mapped[int] = mapped_column(Integer)
    medication_name: Mapped[str] = mapped_column(String(120))
    quantity: Mapped[int] = mapped_column(Integer)
    expiration_date: Mapped[date] = mapped_column(Date)

    disposal: Mapped[Disposal] = relationship(back_populates="items")


class Medication(Base):
    __tablename__ = "medications"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_medications_quantity_positive"),
        Index("ix_medications_user_active", "user_id", "disposed_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(120))
    expiration_date: Mapped[date] = mapped_column(Date)
    quantity: Mapped[int] = mapped_column(Integer)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )
    disposed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    disposal_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("disposals.id", ondelete="SET NULL"), default=None
    )

    user: Mapped[User] = relationship(back_populates="medications")
