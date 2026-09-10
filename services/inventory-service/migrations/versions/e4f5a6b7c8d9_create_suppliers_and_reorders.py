"""Create supplier and reorder tables.

Creates ``supplier`` first (business-scoped vendor directory), then
``reorder`` (store-scoped purchase orders) which FKs to both ``supplier``
and the existing ``item`` table — real foreign keys since both tables live
in this same database (see ``app/models/reorders.py``'s module docstring).

Revision ID: e4f5a6b7c8d9
Revises: d3e4f5a6b7c8
Create Date: 2026-09-10
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "e4f5a6b7c8d9"
down_revision: Union[str, None] = "d3e4f5a6b7c8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_REORDER_STATUS_VALUES = ("pending", "received", "cancelled")


def upgrade() -> None:
    op.execute(
        "CREATE TYPE reorderstatus AS ENUM "
        f"({', '.join(repr(v) for v in _REORDER_STATUS_VALUES)})"
    )

    # ── supplier ─────────────────────────────────────────────────────────
    op.create_table(
        "supplier",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(64), nullable=True),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("address_line1", sa.String(255), nullable=True),
        sa.Column("notes", sa.String(1000), nullable=True),
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
    )
    op.create_index(op.f("ix_supplier_business_id"), "supplier", ["business_id"])
    op.create_index(op.f("ix_supplier_is_deleted"), "supplier", ["is_deleted"])

    # ── reorder ──────────────────────────────────────────────────────────
    op.create_table(
        "reorder",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.Column("supplier_id", sa.Uuid(), nullable=False),
        sa.Column("quantity", sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column("unit", sa.String(16), nullable=False),
        sa.Column("unit_cost", sa.Numeric(precision=12, scale=4), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM(*_REORDER_STATUS_VALUES, name="reorderstatus", create_type=False),
            nullable=False,
            server_default="pending",
        ),
        sa.Column("notes", sa.String(1000), nullable=True),
        sa.Column("ordered_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ordered_by", sa.Uuid(), nullable=True),
        sa.Column("expected_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("received_by", sa.Uuid(), nullable=True),
        sa.Column("cancelled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("cancelled_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["item_id"], ["item.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["supplier_id"], ["supplier.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_reorder_business_id"), "reorder", ["business_id"])
    op.create_index(op.f("ix_reorder_store_id"), "reorder", ["store_id"])
    op.create_index(op.f("ix_reorder_item_id"), "reorder", ["item_id"])
    op.create_index(op.f("ix_reorder_supplier_id"), "reorder", ["supplier_id"])
    op.create_index(op.f("ix_reorder_status"), "reorder", ["status"])


def downgrade() -> None:
    op.drop_index(op.f("ix_reorder_status"), table_name="reorder")
    op.drop_index(op.f("ix_reorder_supplier_id"), table_name="reorder")
    op.drop_index(op.f("ix_reorder_item_id"), table_name="reorder")
    op.drop_index(op.f("ix_reorder_store_id"), table_name="reorder")
    op.drop_index(op.f("ix_reorder_business_id"), table_name="reorder")
    op.drop_table("reorder")
    op.drop_index(op.f("ix_supplier_is_deleted"), table_name="supplier")
    op.drop_index(op.f("ix_supplier_business_id"), table_name="supplier")
    op.drop_table("supplier")
    op.execute("DROP TYPE IF EXISTS reorderstatus")
