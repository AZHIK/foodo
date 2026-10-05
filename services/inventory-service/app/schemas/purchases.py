"""Schemas for the purchases module (multi-line POs, GRNs, returns, payables)."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.purchases import InvoiceStatus, PurchaseOrderStatus


class PurchaseOrderLineCreate(BaseModel):
    """One item line of a new purchase order.

    ``unit`` is deliberately absent: it is always denormalized server-side
    from the item's own ``unit_id`` (resolved to the referenced
    ``Unit.code``) at creation time (see ``app/models/purchases.py``), never
    client-supplied — same convention as ``ReorderCreate``.
    """

    item_id: UUID
    quantity_ordered: Decimal
    unit_cost: Decimal
    notes: str | None = None

    @field_validator("quantity_ordered")
    @classmethod
    def quantity_must_be_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Quantity must be a positive number")
        return v

    @field_validator("unit_cost")
    @classmethod
    def unit_cost_must_be_non_negative(cls, v: Decimal) -> Decimal:
        if v < 0:
            raise ValueError("Unit cost must not be negative")
        return v


class PurchaseOrderCreate(BaseModel):
    """Fields required to draft a purchase order.

    ``business_id`` comes from the URL path, same convention as
    ``ReorderCreate``. ``po_number`` is optional — when omitted the server
    assigns the next ``PO-0001``-style number scoped to the business.
    """

    store_id: UUID
    supplier_id: UUID
    po_number: str | None = None
    notes: str | None = None
    expected_at: datetime | None = None
    lines: list[PurchaseOrderLineCreate]

    @field_validator("lines")
    @classmethod
    def lines_must_not_be_empty(
        cls, v: list[PurchaseOrderLineCreate]
    ) -> list[PurchaseOrderLineCreate]:
        if not v:
            raise ValueError("A purchase order must contain at least one line")
        item_ids = [line.item_id for line in v]
        if len(set(item_ids)) != len(item_ids):
            raise ValueError("Duplicate item in purchase order lines")
        return v


class PurchaseOrderLineRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    purchase_order_id: UUID
    item_id: UUID
    quantity_ordered: Decimal
    quantity_received: Decimal
    unit: str
    unit_cost: Decimal
    notes: str | None


class PurchaseOrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    store_id: UUID
    supplier_id: UUID
    po_number: str
    status: PurchaseOrderStatus
    invoice_status: InvoiceStatus
    total_amount: Decimal
    notes: str | None
    ordered_at: datetime
    ordered_by: UUID | None
    approved_at: datetime | None
    approved_by: UUID | None
    expected_at: datetime | None
    received_at: datetime | None
    received_by: UUID | None
    cancelled_at: datetime | None
    cancelled_by: UUID | None
    created_at: datetime
    updated_at: datetime


class PurchaseOrderListFilters(BaseModel):
    """Query-parameter schema for the list-purchase-orders endpoint."""

    status: PurchaseOrderStatus | None = None
    invoice_status: InvoiceStatus | None = None
    supplier_id: UUID | None = None
    store_id: UUID | None = None


class PurchaseOrderListResponse(BaseModel):
    items: list[PurchaseOrderRead]
    total: int
    limit: int
    offset: int


# ── Goods receipts (partial GRNs) ──────────────────────────────────────


class GoodsReceiptLineCreate(BaseModel):
    purchase_order_line_id: UUID
    quantity_received: Decimal
    lot_no: str | None = Field(default=None, max_length=64)
    expiry_date: datetime | None = None

    @field_validator("quantity_received")
    @classmethod
    def quantity_must_be_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Quantity must be a positive number")
        return v


class GoodsReceiptCreate(BaseModel):
    """Receive one delivery against an approved purchase order.

    The PO id comes from the URL path. Each entry references a PO line;
    the server guards ``sum(received) <= ordered`` per line.
    """

    lines: list[GoodsReceiptLineCreate]
    notes: str | None = None

    @field_validator("lines")
    @classmethod
    def lines_must_not_be_empty(
        cls, v: list[GoodsReceiptLineCreate]
    ) -> list[GoodsReceiptLineCreate]:
        if not v:
            raise ValueError("A goods receipt must contain at least one line")
        line_ids = [line.purchase_order_line_id for line in v]
        if len(set(line_ids)) != len(line_ids):
            raise ValueError("Duplicate purchase order line in goods receipt")
        return v


class GoodsReceiptLineRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    goods_receipt_id: UUID
    purchase_order_line_id: UUID
    item_id: UUID
    quantity_received: Decimal
    lot_no: str | None = None
    expiry_date: datetime | None = None


class GoodsReceiptRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    store_id: UUID
    purchase_order_id: UUID
    grn_number: str
    notes: str | None
    received_at: datetime
    received_by: UUID | None
    created_at: datetime


class GoodsReceiptDetailRead(GoodsReceiptRead):
    lines: list[GoodsReceiptLineRead] = []


# ── Purchase returns ───────────────────────────────────────────────────


class PurchaseReturnCreate(BaseModel):
    """Return stock to a supplier.

    ``purchase_order_id`` / ``goods_receipt_id`` attribute the return;
    at least the item + quantity are required. The server guards
    ``quantity <= received - previously_returned``.
    """

    item_id: UUID
    quantity: Decimal
    purchase_order_id: UUID | None = None
    goods_receipt_id: UUID | None = None
    reason: str | None = None
    # Store that held the stock. Optional when ``purchase_order_id`` is
    # given (defaults to the PO's store, must match when both are passed);
    # required otherwise.
    store_id: UUID | None = None

    @field_validator("quantity")
    @classmethod
    def quantity_must_be_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Quantity must be a positive number")
        return v


class PurchaseReturnRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    store_id: UUID
    purchase_order_id: UUID | None
    goods_receipt_id: UUID | None
    item_id: UUID
    quantity: Decimal
    reason: str | None
    created_by: UUID | None
    created_at: datetime


# ── Supplier invoices & payments ───────────────────────────────────────


class SupplierInvoiceCreate(BaseModel):
    """Capture the supplier's bill for a purchase order.

    ``amount_total`` defaults to the PO's received value when omitted —
    pass an explicit value when the supplier's bill differs (tax, delivery).
    """

    purchase_order_id: UUID
    invoice_number: str
    amount_total: Decimal | None = None
    due_at: datetime | None = None

    @field_validator("amount_total")
    @classmethod
    def total_must_be_positive(cls, v: Decimal | None) -> Decimal | None:
        if v is not None and v <= 0:
            raise ValueError("Invoice total must be a positive number")
        return v


class SupplierInvoiceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    supplier_id: UUID
    purchase_order_id: UUID
    invoice_number: str
    amount_total: Decimal
    amount_paid: Decimal
    status: InvoiceStatus
    due_at: datetime | None
    created_by: UUID | None
    created_at: datetime


class SupplierPaymentCreate(BaseModel):
    """Record one payment against an invoice (online-only, direct API call)."""

    amount: Decimal
    method: str | None = None
    reference: str | None = None

    @field_validator("amount")
    @classmethod
    def amount_must_be_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Amount must be a positive number")
        return v


class SupplierPaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    invoice_id: UUID
    amount: Decimal
    method: str | None
    reference: str | None
    paid_at: datetime
    paid_by: UUID | None
    created_at: datetime


# ── Supplier statement ─────────────────────────────────────────────────


class PurchaseOrderDetailRead(PurchaseOrderRead):
    """Header plus lines, receipts and invoices for the detail view."""

    lines: list[PurchaseOrderLineRead] = []
    receipts: list[GoodsReceiptRead] = []
    invoices: list[SupplierInvoiceRead] = []


class SupplierStatementRead(BaseModel):
    """Open POs + unpaid invoices + outstanding balance for one supplier."""

    supplier_id: UUID
    business_id: UUID
    open_orders: list[PurchaseOrderRead] = []
    unpaid_invoices: list[SupplierInvoiceRead] = []
    outstanding_balance: Decimal = Decimal("0.00")
