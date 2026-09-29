"""Create purchases module tables (multi-line POs, GRNs, returns, payables).

Creates ``purchaseorder`` + ``purchaseorderline`` (multi-line PO header with
one supplier per order), ``goodsreceipt`` + ``goodsreceiptline`` (partial
GRNs — each line produces one PURCHASE_RECEIVED movement), ``purchasereturn``
(supplier returns), and ``supplierinvoice`` + ``supplierpayment`` (minimal
payables ledger). All FKs to ``item``/``supplier``/parent rows are real
constraints since every table lives in this same database (see
``app/models/purchases.py``).

Native enums ``purchaseorderstatus`` / ``invoicestatus`` follow the
``e4f5a6b7c8d9`` convention (raw CREATE TYPE, lowercase values matching the
Python members).

Revision ID: m1a2b3c4d5e6
Revises: l9a0b1c2d3e4
Create Date: 2026-09-25
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "m1a2b3c4d5e6"
down_revision: Union[str, None] = "l9a0b1c2d3e4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_PO_STATUS_VALUES = (
    "draft",
    "submitted",
    "approved",
    "partially_received",
    "received",
    "cancelled",
)
_INVOICE_STATUS_VALUES = ("unbilled", "unpaid", "partial", "paid")


def upgrade() -> None:
    op.execute(
        "CREATE TYPE purchaseorderstatus AS ENUM "
        f"({', '.join(repr(v) for v in _PO_STATUS_VALUES)})"
    )
    op.execute(
        "CREATE TYPE invoicestatus AS ENUM "
        f"({', '.join(repr(v) for v in _INVOICE_STATUS_VALUES)})"
    )

    # ── purchaseorder ──────────────────────────────────────────────────
    op.create_table(
        "purchaseorder",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("supplier_id", sa.Uuid(), nullable=False),
        sa.Column("po_number", sa.String(32), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM(
                *_PO_STATUS_VALUES, name="purchaseorderstatus", create_type=False
            ),
            nullable=False,
            server_default="draft",
        ),
        sa.Column(
            "invoice_status",
            postgresql.ENUM(
                *_INVOICE_STATUS_VALUES, name="invoicestatus", create_type=False
            ),
            nullable=False,
            server_default="unbilled",
        ),
        sa.Column(
            "total_amount",
            sa.Numeric(precision=12, scale=2),
            nullable=False,
            server_default="0.00",
        ),
        sa.Column("notes", sa.String(1000), nullable=True),
        sa.Column("ordered_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ordered_by", sa.Uuid(), nullable=True),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("approved_by", sa.Uuid(), nullable=True),
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
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["supplier_id"], ["supplier.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "business_id", "po_number", name="uq_purchaseorder_business_po_number"
        ),
    )
    op.create_index(
        op.f("ix_purchaseorder_business_id"), "purchaseorder", ["business_id"]
    )
    op.create_index(op.f("ix_purchaseorder_store_id"), "purchaseorder", ["store_id"])
    op.create_index(
        op.f("ix_purchaseorder_supplier_id"), "purchaseorder", ["supplier_id"]
    )
    op.create_index(op.f("ix_purchaseorder_status"), "purchaseorder", ["status"])
    op.create_index(
        op.f("ix_purchaseorder_invoice_status"), "purchaseorder", ["invoice_status"]
    )

    # ── purchaseorderline ──────────────────────────────────────────────
    op.create_table(
        "purchaseorderline",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("purchase_order_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.Column("quantity_ordered", sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column(
            "quantity_received",
            sa.Numeric(precision=12, scale=3),
            nullable=False,
            server_default="0.000",
        ),
        sa.Column("unit", sa.String(16), nullable=False),
        sa.Column("unit_cost", sa.Numeric(precision=12, scale=4), nullable=False),
        sa.Column("notes", sa.String(500), nullable=True),
        sa.ForeignKeyConstraint(
            ["purchase_order_id"], ["purchaseorder.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["item_id"], ["item.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "purchase_order_id", "item_id", name="uq_purchaseorderline_order_item"
        ),
    )
    op.create_index(
        op.f("ix_purchaseorderline_purchase_order_id"),
        "purchaseorderline",
        ["purchase_order_id"],
    )
    op.create_index(
        op.f("ix_purchaseorderline_item_id"), "purchaseorderline", ["item_id"]
    )

    # ── goodsreceipt ───────────────────────────────────────────────────
    op.create_table(
        "goodsreceipt",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("purchase_order_id", sa.Uuid(), nullable=False),
        sa.Column("grn_number", sa.String(32), nullable=False),
        sa.Column("notes", sa.String(1000), nullable=True),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("received_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["purchase_order_id"], ["purchaseorder.id"], ondelete="RESTRICT"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "business_id", "grn_number", name="uq_goodsreceipt_business_grn_number"
        ),
    )
    op.create_index(
        op.f("ix_goodsreceipt_business_id"), "goodsreceipt", ["business_id"]
    )
    op.create_index(op.f("ix_goodsreceipt_store_id"), "goodsreceipt", ["store_id"])
    op.create_index(
        op.f("ix_goodsreceipt_purchase_order_id"),
        "goodsreceipt",
        ["purchase_order_id"],
    )

    # ── goodsreceiptline ───────────────────────────────────────────────
    op.create_table(
        "goodsreceiptline",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("goods_receipt_id", sa.Uuid(), nullable=False),
        sa.Column("purchase_order_line_id", sa.Uuid(), nullable=False),
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.Column(
            "quantity_received", sa.Numeric(precision=12, scale=3), nullable=False
        ),
        sa.ForeignKeyConstraint(
            ["goods_receipt_id"], ["goodsreceipt.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["purchase_order_line_id"],
            ["purchaseorderline.id"],
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(["item_id"], ["item.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_goodsreceiptline_goods_receipt_id"),
        "goodsreceiptline",
        ["goods_receipt_id"],
    )
    op.create_index(
        op.f("ix_goodsreceiptline_purchase_order_line_id"),
        "goodsreceiptline",
        ["purchase_order_line_id"],
    )
    op.create_index(
        op.f("ix_goodsreceiptline_item_id"), "goodsreceiptline", ["item_id"]
    )

    # ── purchasereturn ─────────────────────────────────────────────────
    op.create_table(
        "purchasereturn",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("purchase_order_id", sa.Uuid(), nullable=True),
        sa.Column("goods_receipt_id", sa.Uuid(), nullable=True),
        sa.Column("item_id", sa.Uuid(), nullable=False),
        sa.Column("quantity", sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column("reason", sa.String(500), nullable=True),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["purchase_order_id"], ["purchaseorder.id"], ondelete="RESTRICT"
        ),
        sa.ForeignKeyConstraint(
            ["goods_receipt_id"], ["goodsreceipt.id"], ondelete="RESTRICT"
        ),
        sa.ForeignKeyConstraint(["item_id"], ["item.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_purchasereturn_business_id"), "purchasereturn", ["business_id"]
    )
    op.create_index(
        op.f("ix_purchasereturn_store_id"), "purchasereturn", ["store_id"]
    )
    op.create_index(
        op.f("ix_purchasereturn_purchase_order_id"),
        "purchasereturn",
        ["purchase_order_id"],
    )
    op.create_index(
        op.f("ix_purchasereturn_goods_receipt_id"),
        "purchasereturn",
        ["goods_receipt_id"],
    )
    op.create_index(op.f("ix_purchasereturn_item_id"), "purchasereturn", ["item_id"])

    # ── supplierinvoice ────────────────────────────────────────────────
    op.create_table(
        "supplierinvoice",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("supplier_id", sa.Uuid(), nullable=False),
        sa.Column("purchase_order_id", sa.Uuid(), nullable=False),
        sa.Column("invoice_number", sa.String(64), nullable=False),
        sa.Column(
            "amount_total", sa.Numeric(precision=12, scale=2), nullable=False
        ),
        sa.Column(
            "amount_paid",
            sa.Numeric(precision=12, scale=2),
            nullable=False,
            server_default="0.00",
        ),
        sa.Column(
            "status",
            postgresql.ENUM(
                *_INVOICE_STATUS_VALUES, name="invoicestatus", create_type=False
            ),
            nullable=False,
            server_default="unpaid",
        ),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["supplier_id"], ["supplier.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(
            ["purchase_order_id"], ["purchaseorder.id"], ondelete="RESTRICT"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_supplierinvoice_business_id"), "supplierinvoice", ["business_id"]
    )
    op.create_index(
        op.f("ix_supplierinvoice_supplier_id"), "supplierinvoice", ["supplier_id"]
    )
    op.create_index(
        op.f("ix_supplierinvoice_purchase_order_id"),
        "supplierinvoice",
        ["purchase_order_id"],
    )
    op.create_index(op.f("ix_supplierinvoice_status"), "supplierinvoice", ["status"])

    # ── supplierpayment ────────────────────────────────────────────────
    op.create_table(
        "supplierpayment",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("invoice_id", sa.Uuid(), nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("method", sa.String(32), nullable=True),
        sa.Column("reference", sa.String(128), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("paid_by", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["invoice_id"], ["supplierinvoice.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_supplierpayment_business_id"), "supplierpayment", ["business_id"]
    )
    op.create_index(
        op.f("ix_supplierpayment_invoice_id"), "supplierpayment", ["invoice_id"]
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_supplierpayment_invoice_id"), table_name="supplierpayment")
    op.drop_index(op.f("ix_supplierpayment_business_id"), table_name="supplierpayment")
    op.drop_table("supplierpayment")
    op.drop_index(op.f("ix_supplierinvoice_status"), table_name="supplierinvoice")
    op.drop_index(
        op.f("ix_supplierinvoice_purchase_order_id"), table_name="supplierinvoice"
    )
    op.drop_index(op.f("ix_supplierinvoice_supplier_id"), table_name="supplierinvoice")
    op.drop_index(op.f("ix_supplierinvoice_business_id"), table_name="supplierinvoice")
    op.drop_table("supplierinvoice")
    op.drop_index(op.f("ix_purchasereturn_item_id"), table_name="purchasereturn")
    op.drop_index(
        op.f("ix_purchasereturn_goods_receipt_id"), table_name="purchasereturn"
    )
    op.drop_index(
        op.f("ix_purchasereturn_purchase_order_id"), table_name="purchasereturn"
    )
    op.drop_index(op.f("ix_purchasereturn_store_id"), table_name="purchasereturn")
    op.drop_index(op.f("ix_purchasereturn_business_id"), table_name="purchasereturn")
    op.drop_table("purchasereturn")
    op.drop_index(op.f("ix_goodsreceiptline_item_id"), table_name="goodsreceiptline")
    op.drop_index(
        op.f("ix_goodsreceiptline_purchase_order_line_id"),
        table_name="goodsreceiptline",
    )
    op.drop_index(
        op.f("ix_goodsreceiptline_goods_receipt_id"), table_name="goodsreceiptline"
    )
    op.drop_table("goodsreceiptline")
    op.drop_index(
        op.f("ix_goodsreceipt_purchase_order_id"), table_name="goodsreceipt"
    )
    op.drop_index(op.f("ix_goodsreceipt_store_id"), table_name="goodsreceipt")
    op.drop_index(op.f("ix_goodsreceipt_business_id"), table_name="goodsreceipt")
    op.drop_table("goodsreceipt")
    op.drop_index(op.f("ix_purchaseorderline_item_id"), table_name="purchaseorderline")
    op.drop_index(
        op.f("ix_purchaseorderline_purchase_order_id"),
        table_name="purchaseorderline",
    )
    op.drop_table("purchaseorderline")
    op.drop_index(op.f("ix_purchaseorder_invoice_status"), table_name="purchaseorder")
    op.drop_index(op.f("ix_purchaseorder_status"), table_name="purchaseorder")
    op.drop_index(op.f("ix_purchaseorder_supplier_id"), table_name="purchaseorder")
    op.drop_index(op.f("ix_purchaseorder_store_id"), table_name="purchaseorder")
    op.drop_index(op.f("ix_purchaseorder_business_id"), table_name="purchaseorder")
    op.drop_table("purchaseorder")
    op.execute("DROP TYPE IF EXISTS invoicestatus")
    op.execute("DROP TYPE IF EXISTS purchaseorderstatus")
