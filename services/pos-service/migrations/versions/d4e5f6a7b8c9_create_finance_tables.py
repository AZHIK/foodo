"""Create finance_attachments, other_expenses, and other_incomes tables.

Revision ID: d4e5f6a7b8c9
Revises: 3c2fa01b639c
Create Date: 2026-09-10 12:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import sqlmodel  # noqa: F401


# revision identifiers, used by Alembic.
revision: str = "d4e5f6a7b8c9"
down_revision: Union[str, None] = "3c2fa01b639c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# The ``paymentmethod`` PG enum type already exists (created by the sales
# migration, b2c3d4e5f6a7). Reference it with create_type=False rather than
# letting SQLAlchemy attempt to re-CREATE it, which would fail.
_payment_method_type = postgresql.ENUM(
    "cash", "mobile_money", "card", "other",
    name="paymentmethod",
    create_type=False,
)


def upgrade() -> None:
    # ── finance_attachments ─────────────────────────────────────────────
    # Created first: other_expenses/other_incomes.receipt_attachment_id
    # references it.
    op.create_table(
        "finance_attachments",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("storage_key", sa.String(500), nullable=False, unique=True),
        sa.Column("original_filename", sa.String(255), nullable=False),
        sa.Column("content_type", sa.String(100), nullable=False),
        sa.Column("byte_size", sa.Integer(), nullable=False),
        sa.Column("checksum_sha256", sa.String(64), nullable=True),
        sa.Column("uploaded_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_finance_attachments_business_id"),
        "finance_attachments",
        ["business_id"],
    )

    # ── other_expenses ───────────────────────────────────────────────────
    op.create_table(
        "other_expenses",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("client_expense_id", sa.String(255), nullable=False, unique=True),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("description", sa.String(500), nullable=False),
        sa.Column("payee", sa.String(255), nullable=True),
        sa.Column("note", sa.String(1000), nullable=True),
        sa.Column("payment_method", _payment_method_type, nullable=False),
        sa.Column("receipt_attachment_id", sa.Uuid(), nullable=True),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "synced_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("device_sequence", sa.Integer(), nullable=True),
        sa.Column(
            "is_time_suspect",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("deleted_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["receipt_attachment_id"],
            ["finance_attachments.id"],
            name="fk_other_expenses_receipt_attachment_id",
            ondelete="SET NULL",
        ),
    )
    op.create_index(
        op.f("ix_other_expenses_business_id"), "other_expenses", ["business_id"]
    )
    op.create_index(
        op.f("ix_other_expenses_store_id"), "other_expenses", ["store_id"]
    )
    op.create_index(
        op.f("ix_other_expenses_actor_id"), "other_expenses", ["actor_id"]
    )
    op.create_index(
        op.f("ix_other_expenses_occurred_at"), "other_expenses", ["occurred_at"]
    )
    op.create_index(
        op.f("ix_other_expenses_category"), "other_expenses", ["category"]
    )
    op.create_index(
        op.f("ix_other_expenses_is_deleted"), "other_expenses", ["is_deleted"]
    )

    # ── other_incomes ────────────────────────────────────────────────────
    op.create_table(
        "other_incomes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("client_income_id", sa.String(255), nullable=False, unique=True),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("description", sa.String(500), nullable=False),
        sa.Column("source", sa.String(255), nullable=True),
        sa.Column("note", sa.String(1000), nullable=True),
        sa.Column("payment_method", _payment_method_type, nullable=False),
        sa.Column("receipt_attachment_id", sa.Uuid(), nullable=True),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "synced_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("device_sequence", sa.Integer(), nullable=True),
        sa.Column(
            "is_time_suspect",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("deleted_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["receipt_attachment_id"],
            ["finance_attachments.id"],
            name="fk_other_incomes_receipt_attachment_id",
            ondelete="SET NULL",
        ),
    )
    op.create_index(
        op.f("ix_other_incomes_business_id"), "other_incomes", ["business_id"]
    )
    op.create_index(
        op.f("ix_other_incomes_store_id"), "other_incomes", ["store_id"]
    )
    op.create_index(
        op.f("ix_other_incomes_actor_id"), "other_incomes", ["actor_id"]
    )
    op.create_index(
        op.f("ix_other_incomes_occurred_at"), "other_incomes", ["occurred_at"]
    )
    op.create_index(
        op.f("ix_other_incomes_category"), "other_incomes", ["category"]
    )
    op.create_index(
        op.f("ix_other_incomes_is_deleted"), "other_incomes", ["is_deleted"]
    )


def downgrade() -> None:
    op.drop_table("other_incomes")
    op.drop_table("other_expenses")
    op.drop_table("finance_attachments")
    # Do NOT drop the paymentmethod type here — sales.payment_method (created
    # by migration b2c3d4e5f6a7) still depends on it.
