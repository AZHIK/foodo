"""Create couriers table and add delivery fields to sales.

Revision ID: f6a7b8c9d0e2
Revises: e5f6a7b8c9d0
Create Date: 2026-10-01 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel  # noqa: F401


# revision identifiers, used by Alembic.
revision: str = "f6a7b8c9d0e2"
down_revision: Union[str, None] = "e5f6a7b8c9d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_ORDERTYPE = sa.Enum(
    "dine_in", "takeaway", "delivery", name="ordertype",
)
_DELIVERYSTATUS = sa.Enum(
    "pending",
    "assigned",
    "out_for_delivery",
    "delivered",
    "failed",
    name="deliverystatus",
)


def upgrade() -> None:
    # ── couriers ─────────────────────────────────────────────────────────
    op.create_table(
        "couriers",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(50), nullable=False),
        sa.Column("vehicle", sa.String(255), nullable=True),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "business_id", "phone", name="uq_couriers_business_id_phone",
        ),
    )
    op.create_index(op.f("ix_couriers_business_id"), "couriers", ["business_id"])
    op.create_index(op.f("ix_couriers_name"), "couriers", ["name"])
    op.create_index(op.f("ix_couriers_phone"), "couriers", ["phone"])
    op.create_index(op.f("ix_couriers_actor_id"), "couriers", ["actor_id"])
    op.create_index(op.f("ix_couriers_is_active"), "couriers", ["is_active"])

    # ── sales delivery columns ─────────────────────────────────────────
    _ORDERTYPE.create(op.get_bind(), checkfirst=True)
    _DELIVERYSTATUS.create(op.get_bind(), checkfirst=True)

    op.add_column(
        "sales",
        sa.Column(
            "order_type",
            _ORDERTYPE,
            nullable=False,
            server_default="dine_in",
        ),
    )
    op.add_column("sales", sa.Column("courier_id", sa.Uuid(), nullable=True))
    op.add_column(
        "sales", sa.Column("delivery_address_line1", sa.String(500), nullable=True)
    )
    op.add_column(
        "sales", sa.Column("delivery_recipient_phone", sa.String(50), nullable=True)
    )
    op.add_column(
        "sales", sa.Column("delivery_note", sa.String(500), nullable=True)
    )
    op.add_column(
        "sales",
        sa.Column(
            "delivery_fee",
            sa.Numeric(precision=12, scale=2),
            nullable=False,
            server_default="0",
        ),
    )
    op.add_column(
        "sales", sa.Column("delivery_status", _DELIVERYSTATUS, nullable=True)
    )
    op.create_foreign_key(
        "fk_sales_courier_id",
        "sales",
        "couriers",
        ["courier_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(op.f("ix_sales_order_type"), "sales", ["order_type"])
    op.create_index(op.f("ix_sales_courier_id"), "sales", ["courier_id"])
    op.create_index(op.f("ix_sales_delivery_status"), "sales", ["delivery_status"])


def downgrade() -> None:
    op.drop_index(op.f("ix_sales_delivery_status"), table_name="sales")
    op.drop_index(op.f("ix_sales_courier_id"), table_name="sales")
    op.drop_index(op.f("ix_sales_order_type"), table_name="sales")
    op.drop_constraint("fk_sales_courier_id", "sales", type_="foreignkey")
    op.drop_column("sales", "delivery_status")
    op.drop_column("sales", "delivery_fee")
    op.drop_column("sales", "delivery_note")
    op.drop_column("sales", "delivery_recipient_phone")
    op.drop_column("sales", "delivery_address_line1")
    op.drop_column("sales", "courier_id")
    op.drop_column("sales", "order_type")
    _DELIVERYSTATUS.drop(op.get_bind(), checkfirst=True)
    _ORDERTYPE.drop(op.get_bind(), checkfirst=True)

    op.drop_index(op.f("ix_couriers_is_active"), table_name="couriers")
    op.drop_index(op.f("ix_couriers_actor_id"), table_name="couriers")
    op.drop_index(op.f("ix_couriers_phone"), table_name="couriers")
    op.drop_index(op.f("ix_couriers_name"), table_name="couriers")
    op.drop_index(op.f("ix_couriers_business_id"), table_name="couriers")
    op.drop_table("couriers")
