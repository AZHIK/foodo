"""Schemas for inventory analytics endpoints (waste, production, valuation).

Same read-only conventions as ``reports.py``: business-scoped, computed in
SQL, and denormalized just enough (item names, unit codes) that callers
render without a second round-trip per row.
"""

from __future__ import annotations

from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class WasteLine(BaseModel):
    """One item's recorded waste in the window — quantity and cost."""

    item_id: UUID
    item_name: str
    item_unit: str
    quantity_wasted: Decimal
    cost_wasted: Decimal


class WasteSummaryResponse(BaseModel):
    lines: list[WasteLine]
    total_cost_wasted: Decimal


class IngredientConsumption(BaseModel):
    raw_material_item_id: UUID
    raw_material_name: str
    raw_material_unit: str
    quantity_consumed: Decimal


class ProductionSummaryResponse(BaseModel):
    """Production runs in the window, with the portioning signal kept.

    ``suggested_total`` vs ``actual_total`` is the same gap the event
    payloads carry per run, summed here so the report answers "are we
    over-portioning" at a glance. Positive ``over_portioned_by`` means
    more was stocked than recipes suggested.
    """

    runs: int
    suggested_total: Decimal
    actual_total: Decimal
    over_portioned_by: Decimal
    ingredients_consumed: list[IngredientConsumption]


class StockValuationLine(BaseModel):
    category: str | None
    item_count: int
    total_value: Decimal


class StockValuationResponse(BaseModel):
    total_value: Decimal
    lines: list[StockValuationLine]


# ── Product purchase report: what was bought, from whom ───────────────────


class ProductPurchaseLine(BaseModel):
    """One item+supplier bucket of purchasing.

    Maps to the on-screen **Product Purchase Report**.
    """

    item_id: UUID
    item_name: str
    item_unit: str
    supplier_id: UUID | None
    supplier_name: str
    quantity_ordered: Decimal
    quantity_received: Decimal
    total_cost: Decimal


class ProductPurchaseResponse(BaseModel):
    lines: list[ProductPurchaseLine]
    total_cost: Decimal


# ── Purchase payment report: what was paid to suppliers ───────────────────


class PurchasePaymentLine(BaseModel):
    """One supplier (+method) bucket of supplier payments.

    Maps to the on-screen **Purchase Payment Report**.
    """

    supplier_id: UUID
    supplier_name: str
    method: str | None = None
    payments_count: int
    total_paid: Decimal


class PurchasePaymentResponse(BaseModel):
    lines: list[PurchasePaymentLine]
    total_paid: Decimal


# ── Stock adjustment report: manual corrections business-wide ─────────────


class StockAdjustmentLine(BaseModel):
    """One manual-adjustment movement with item context.

    Maps to the on-screen **Stock Adjustment Report**. The existing
    per-item ``movements`` endpoint stays; this is the business-wide view
    the report screen needs.
    """

    id: UUID
    item_id: UUID
    item_name: str
    store_id: UUID
    quantity_delta: Decimal
    reason: str | None = None
    actor_id: UUID | None = None
    created_at: str


class StockAdjustmentResponse(BaseModel):
    lines: list[StockAdjustmentLine]
    total: int


# ── Lot report: goods receipts as traceable lots ──────────────────────────


class LotLine(BaseModel):
    """One goods receipt treated as a lot.

    Maps to the on-screen **Lot Report**. ``lot_no`` defaults to the GRN
    number; per-batch ``lot_no``/``expiry_date`` on the receipt line are
    surfaced when present (see ``p8q9r0s1t2u3`` migration).
    """

    goods_receipt_id: UUID
    lot_no: str
    item_id: UUID
    item_name: str
    quantity_received: Decimal
    supplier_name: str | None = None
    expiry_date: str | None = None
    received_at: str


class LotReportResponse(BaseModel):
    lines: list[LotLine]


# ── Stock expiry report: lots expiring in the window ──────────────────────


class ExpiryLine(BaseModel):
    """One receipt line with an expiry date inside the window.

    Maps to the on-screen **Stock Expiry Report**. Lines without an
    expiry date never appear here — unknown expiry is not "expiring".
    """

    goods_receipt_id: UUID
    lot_no: str
    item_id: UUID
    item_name: str
    quantity_received: Decimal
    expiry_date: str
    received_at: str


class ExpiryReportResponse(BaseModel):
    lines: list[ExpiryLine]


# ── Supplier & customer: supplier-purchases leg ───────────────────────────


class SupplierPurchaseLine(BaseModel):
    """One supplier's purchase + payment position.

    Supplier leg of the **Supplier & Customer Report** (the customer-spend
    leg lives in POS Service's ``customer-spend`` report).
    """

    supplier_id: UUID
    supplier_name: str
    orders_count: int
    total_ordered: Decimal
    total_paid: Decimal
    balance: Decimal


class SupplierPurchaseResponse(BaseModel):
    lines: list[SupplierPurchaseLine]


# ── Activity log: recent stock movements as the audit trail ────────────────


class ActivityLogLine(BaseModel):
    """One auditable event (any movement type), newest first.

    Maps to the on-screen **Activity Log** (inventory leg — sales-side
    activity lives in POS Service's sales list).
    """

    id: UUID
    item_id: UUID
    item_name: str
    movement_type: str
    quantity_delta: Decimal
    store_id: UUID
    actor_id: UUID | None = None
    reason: str | None = None
    created_at: str


class ActivityLogResponse(BaseModel):
    lines: list[ActivityLogLine]
    total: int
