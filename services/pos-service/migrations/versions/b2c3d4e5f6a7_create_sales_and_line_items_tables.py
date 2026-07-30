"""Create sales and sale_line_items tables.

Revision ID: b2c3d4e5f6a7
Revises: 02724c7d24c8
Create Date: 2026-07-29 12:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel  # noqa: F401


# revision identifiers, used by Alembic.
revision: str = "b2c3d4e5f6a7"
down_revision: Union[str, None] = "02724c7d24c8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── sales ────────────────────────────────────────────────────────
    op.create_table(
        "sales",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False, index=True),
        sa.Column("business_location_id", sa.Uuid(), nullable=False, index=True),
        sa.Column("client_sale_id", sa.String(255), nullable=False, unique=True),
        sa.Column(
            "status",
            sa.Enum("completed", "voided", "refunded", name="salestatus"),
            nullable=False,
        ),
        sa.Column("subtotal", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column(
            "discount_amount",
            sa.Numeric(precision=12, scale=2),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "tax_amount",
            sa.Numeric(precision=12, scale=2),
            nullable=False,
            server_default="0",
        ),
        sa.Column("total", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column(
            "payment_method",
            sa.Enum("cash", "mobile_money", "card", "other", name="paymentmethod"),
            nullable=False,
        ),
        sa.Column("actor_id", sa.Uuid(), nullable=True, index=True),
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
        sa.Column("voided_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("refunded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("void_or_refund_reason", sa.String(500), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_sales_occurred_at"), "sales", ["occurred_at"]
    )

    # ── sale_line_items ──────────────────────────────────────────────
    op.create_table(
        "sale_line_items",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("sale_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=False, index=True),
        sa.Column("quantity", sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column("unit_price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column(
            "discount_amount",
            sa.Numeric(precision=12, scale=2),
            nullable=False,
            server_default="0",
        ),
        sa.Column("line_total", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["sale_id"],
            ["sales.id"],
            name="fk_sale_line_items_sale_id",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        op.f("ix_sale_line_items_sale_id"),
        "sale_line_items",
        ["sale_id"],
    )


def downgrade() -> None:
    op.drop_table("sale_line_items")
    op.drop_table("sales")
    op.execute("DROP TYPE IF EXISTS paymentmethod CASCADE")
    op.execute("DROP TYPE IF EXISTS salestatus CASCADE")
