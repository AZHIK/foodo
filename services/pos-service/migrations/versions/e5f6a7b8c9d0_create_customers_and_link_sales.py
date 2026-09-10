"""Create customers table and link sales.customer_id to it.

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-09-10 18:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel  # noqa: F401


# revision identifiers, used by Alembic.
revision: str = "e5f6a7b8c9d0"
down_revision: Union[str, None] = "d4e5f6a7b8c9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── customers ────────────────────────────────────────────────────────
    # Created first: sales.customer_id (below) FKs to it.
    op.create_table(
        "customers",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(50), nullable=False),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("address_line1", sa.String(500), nullable=True),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=False),
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
    )
    op.create_index(
        op.f("ix_customers_business_id"), "customers", ["business_id"]
    )
    op.create_index(op.f("ix_customers_name"), "customers", ["name"])
    op.create_index(op.f("ix_customers_phone"), "customers", ["phone"])
    op.create_index(op.f("ix_customers_actor_id"), "customers", ["actor_id"])
    op.create_index(
        op.f("ix_customers_is_deleted"), "customers", ["is_deleted"]
    )
    op.create_index(
        "ix_customers_business_id_phone", "customers", ["business_id", "phone"]
    )

    # ── sales.customer_id ───────────────────────────────────────────────
    op.add_column("sales", sa.Column("customer_id", sa.Uuid(), nullable=True))
    op.create_foreign_key(
        "fk_sales_customer_id",
        "sales",
        "customers",
        ["customer_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(op.f("ix_sales_customer_id"), "sales", ["customer_id"])


def downgrade() -> None:
    op.drop_index(op.f("ix_sales_customer_id"), table_name="sales")
    op.drop_constraint("fk_sales_customer_id", "sales", type_="foreignkey")
    op.drop_column("sales", "customer_id")
    op.drop_table("customers")
