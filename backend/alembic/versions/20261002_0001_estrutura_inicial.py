"""Estrutura inicial: usuários, sessões, recuperação, medicamentos e descartes.

Revision ID: 0001
Revises:
Create Date: 2026-10-02
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("email", sa.String(length=254), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "disposals",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("disposed_on", sa.Date(), nullable=False),
        sa.Column("point_external_id", sa.String(length=64), nullable=True),
        sa.Column("point_name", sa.String(length=200), nullable=True),
        sa.Column("point_address", sa.String(length=300), nullable=True),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_disposals_user_id", "disposals", ["user_id"])

    op.create_table(
        "password_reset_tokens",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash"),
    )
    op.create_index("ix_password_reset_tokens_user_id", "password_reset_tokens", ["user_id"])

    op.create_table(
        "refresh_sessions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash"),
    )
    op.create_index("ix_refresh_sessions_user_id", "refresh_sessions", ["user_id"])

    op.create_table(
        "disposal_items",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("disposal_id", sa.Uuid(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("medication_name", sa.String(length=120), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("expiration_date", sa.Date(), nullable=False),
        sa.ForeignKeyConstraint(["disposal_id"], ["disposals.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_disposal_items_disposal_id", "disposal_items", ["disposal_id"])

    op.create_table(
        "medications",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("expiration_date", sa.Date(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("disposed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("disposal_id", sa.Uuid(), nullable=True),
        sa.CheckConstraint("quantity > 0", name="ck_medications_quantity_positive"),
        sa.ForeignKeyConstraint(["disposal_id"], ["disposals.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_medications_user_active", "medications", ["user_id", "disposed_at"])


def downgrade() -> None:
    op.drop_index("ix_medications_user_active", table_name="medications")
    op.drop_table("medications")
    op.drop_index("ix_disposal_items_disposal_id", table_name="disposal_items")
    op.drop_table("disposal_items")
    op.drop_index("ix_refresh_sessions_user_id", table_name="refresh_sessions")
    op.drop_table("refresh_sessions")
    op.drop_index("ix_password_reset_tokens_user_id", table_name="password_reset_tokens")
    op.drop_table("password_reset_tokens")
    op.drop_index("ix_disposals_user_id", table_name="disposals")
    op.drop_table("disposals")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
