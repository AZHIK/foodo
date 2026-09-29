"""Requisition split: requisition + lines, supplier catalogue, messages.

Additive migration — no existing table is restructured:

* NEW ``requisition`` / ``requisitionline`` / ``supplieritem`` /
  ``suppliermessage`` (+ 4 native enums).
* ``supplier`` gains ``whatsapp_number``, ``contact_person``, ``is_active``.
* ``purchaseorder`` gains nullable ``requisition_id`` FK + ``idempotency_key``;
  its native enum gains payload_ready/sent/confirmed/partially_fulfilled/
  fulfilled (old values kept — classic GRN flow untouched).
* ``purchaseorderline`` gains ``price_unconfirmed`` (default false).

Revision ID: n2b3c4d5e6f7
Revises: m1a2b3c4d5e6
Create Date: 2026-09-28
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "n2b3c4d5e6f7"
down_revision: Union[str, None] = "m1a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_NEW_PO_VALUES = ("payload_ready", "sent", "confirmed", "partially_fulfilled", "fulfilled")


def upgrade() -> None:
    # ── extend purchaseorderstatus (additive ALTER TYPE … ADD VALUE) ──────
    for value in _NEW_PO_VALUES:
        op.execute(f"ALTER TYPE purchaseorderstatus ADD VALUE IF NOT EXISTS '{value}'")

    op.execute(
        "CREATE TYPE assignmentsource AS ENUM ('manual_per_item', 'bulk_all')"
    )
    op.execute("CREATE TYPE messagedirection AS ENUM ('outbound', 'inbound')")
    op.execute("CREATE TYPE messagechannel AS ENUM ('whatsapp', 'in_app')")
    op.execute(
        "CREATE TYPE messagestatus AS ENUM "
        "('draft', 'ready', 'sent', 'delivered', 'read', 'failed')"
    )

    # ── supplier additive columns ─────────────────────────────────────────
    op.add_column("supplier", sa.Column("whatsapp_number", sa.String(64), nullable=True))
    op.add_column("supplier", sa.Column("contact_person", sa.String(255), nullable=True))
    op.add_column(
        "supplier",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.create_index(op.f("ix_supplier_is_active"), "supplier", ["is_active"])

    # ── purchaseorder additive columns ────────────────────────────────────
    # (FK constraint added AFTER the requisition table is created below.)
    op.add_column("purchaseorder", sa.Column("requisition_id", sa.Uuid(), nullable=True))
    op.add_column("purchaseorder", sa.Column("idempotency_key", sa.String(128), nullable=True))

    # ── purchaseorderline additive column ─────────────────────────────────
    op.add_column(
        "purchaseorderline",
        sa.Column("price_unconfirmed", sa.Boolean(), nullable=False, server_default="false"),
    )

    # ── requisition ───────────────────────────────────────────────────────
    op.create_table(
        "requisition",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.Column("notes", sa.String(1000), nullable=True),
        sa.Column("expected_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("idempotency_key", sa.String(128), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("business_id", "idempotency_key", name="uq_requisition_business_idem"),
    )
    op.create_index(op.f("ix_requisition_business_id"), "requisition", ["business_id"])
    op.create_index(op.f("ix_requisition_store_id"), "requisition", ["store_id"])
    op.create_index(op.f("ix_requisition_idempotency_key"), "requisition", ["idempotency_key"])

    # Now that requisition exists, wire the PO linkage FK + indexes.
    op.create_foreign_key(
        "fk_purchaseorder_requisition_id", "purchaseorder", "requisition",
        ["requisition_id"], ["id"], ondelete="RESTRICT",
    )
    op.create_index(op.f("ix_purchaseorder_requisition_id"), "purchaseorder", ["requisition_id"])
    op.create_index(op.f("ix_purchaseorder_idempotency_key"), "purchaseorder", ["idempotency_key"])

    # ── requisitionline ───────────────────────────────────────────────────
    op.create_table(
        "requisitionline",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("requisition_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.Column("qty", sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column("supplier_id", sa.Uuid(), nullable=True),
        sa.Column("unit_price_snapshot", sa.Numeric(precision=12, scale=4), nullable=True),
        sa.Column("price_unconfirmed", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column(
            "supplier_assignment_source",
            postgresql.ENUM("manual_per_item", "bulk_all", name="assignmentsource", create_type=False),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["requisition_id"], ["requisition.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["item_id"], ["item.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["supplier_id"], ["supplier.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_requisitionline_requisition_id"), "requisitionline", ["requisition_id"])
    op.create_index(op.f("ix_requisitionline_item_id"), "requisitionline", ["item_id"])
    op.create_index(op.f("ix_requisitionline_supplier_id"), "requisitionline", ["supplier_id"])

    # ── supplieritem ──────────────────────────────────────────────────────
    op.create_table(
        "supplieritem",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("supplier_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.Column("price", sa.Numeric(precision=12, scale=4), nullable=True),
        sa.Column("moq", sa.Numeric(precision=12, scale=3), nullable=True),
        sa.Column("lead_time_days", sa.Integer(), nullable=True),
        sa.Column("is_preferred", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["supplier_id"], ["supplier.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["item_id"], ["item.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("supplier_id", "item_id", name="uq_supplieritem_supplier_item"),
    )
    op.create_index(op.f("ix_supplieritem_supplier_id"), "supplieritem", ["supplier_id"])
    op.create_index(op.f("ix_supplieritem_item_id"), "supplieritem", ["item_id"])

    # ── suppliermessage ───────────────────────────────────────────────────
    op.create_table(
        "suppliermessage",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("po_id", sa.Uuid(), nullable=False),
        sa.Column(
            "direction",
            postgresql.ENUM("outbound", "inbound", name="messagedirection", create_type=False),
            nullable=False,
        ),
        sa.Column(
            "channel",
            postgresql.ENUM("whatsapp", "in_app", name="messagechannel", create_type=False),
            nullable=False,
        ),
        sa.Column("payload", postgresql.JSONB(), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM(
                "draft", "ready", "sent", "delivered", "read", "failed",
                name="messagestatus", create_type=False,
            ),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["po_id"], ["purchaseorder.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_suppliermessage_po_id"), "suppliermessage", ["po_id"])
    op.create_index(op.f("ix_suppliermessage_channel"), "suppliermessage", ["channel"])
    op.create_index(op.f("ix_suppliermessage_status"), "suppliermessage", ["status"])


def downgrade() -> None:
    op.drop_index(op.f("ix_suppliermessage_status"), table_name="suppliermessage")
    op.drop_index(op.f("ix_suppliermessage_channel"), table_name="suppliermessage")
    op.drop_index(op.f("ix_suppliermessage_po_id"), table_name="suppliermessage")
    op.drop_table("suppliermessage")
    op.drop_index(op.f("ix_supplieritem_item_id"), table_name="supplieritem")
    op.drop_index(op.f("ix_supplieritem_supplier_id"), table_name="supplieritem")
    op.drop_table("supplieritem")
    op.drop_index(op.f("ix_requisitionline_supplier_id"), table_name="requisitionline")
    op.drop_index(op.f("ix_requisitionline_item_id"), table_name="requisitionline")
    op.drop_index(op.f("ix_requisitionline_requisition_id"), table_name="requisitionline")
    op.drop_table("requisitionline")
    op.drop_index(op.f("ix_requisition_idempotency_key"), table_name="requisition")
    op.drop_index(op.f("ix_requisition_store_id"), table_name="requisition")
    op.drop_index(op.f("ix_requisition_business_id"), table_name="requisition")
    op.drop_table("requisition")
    op.drop_column("purchaseorderline", "price_unconfirmed")
    op.drop_constraint("fk_purchaseorder_requisition_id", "purchaseorder", type_="foreignkey")
    op.drop_index(op.f("ix_purchaseorder_idempotency_key"), table_name="purchaseorder")
    op.drop_index(op.f("ix_purchaseorder_requisition_id"), table_name="purchaseorder")
    op.drop_column("purchaseorder", "idempotency_key")
    op.drop_column("purchaseorder", "requisition_id")
    op.drop_index(op.f("ix_supplier_is_active"), table_name="supplier")
    op.drop_column("supplier", "is_active")
    op.drop_column("supplier", "contact_person")
    op.drop_column("supplier", "whatsapp_number")
    op.execute("DROP TYPE IF EXISTS messagestatus")
    op.execute("DROP TYPE IF EXISTS messagechannel")
    op.execute("DROP TYPE IF EXISTS messagedirection")
    op.execute("DROP TYPE IF EXISTS assignmentsource")
    # NOTE: Postgres cannot drop enum VALUES; the five added
    # purchaseorderstatus values intentionally persist on downgrade.
