"""Schemas for aggregated reporting endpoints (daily takings, item mix,
staff performance, finance summary).

All aggregates share two conventions, matching ``GET /sales/summary``:

* Revenue counts ``completed`` sales only. Voided/refunded sales are
  reported as separate counts — a takings figure that silently includes
  reversed sales is the exact lie these endpoints exist to prevent.
* Date filters apply to ``occurred_at`` (when the sale happened on the
  device), not ``synced_at`` (when the server saw it).
"""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class DailyTakingsDay(BaseModel):
    """One calendar day (UTC) of takings."""

    date: date
    revenue: Decimal
    sales_count: int
    avg_ticket: Decimal
    voided_count: int
    refunded_count: int


class DailyTakingsResponse(BaseModel):
    days: list[DailyTakingsDay]


class ItemMixLine(BaseModel):
    """One menu item's share of sales in the window.

    ``item_id`` is a cross-service reference — names resolve in Inventory
    Service's catalog (the app joins them client-side), so this endpoint
    never duplicates the catalog.
    """

    item_id: UUID
    quantity: Decimal
    revenue: Decimal
    lines: int


class ItemMixResponse(BaseModel):
    lines: list[ItemMixLine]


class StaffPerformanceLine(BaseModel):
    """One actor's sales in the window. ``actor_id`` is null for sales
    recorded without an attributable staff member (e.g. legacy imports) —
    they still count, under an explicit unknown bucket, rather than being
    silently dropped.
    """

    actor_id: UUID | None
    sales_count: int
    revenue: Decimal
    voided_count: int
    refunded_count: int


class StaffPerformanceResponse(BaseModel):
    lines: list[StaffPerformanceLine]


class FinanceCategoryTotal(BaseModel):
    category: str
    total: Decimal


class FinanceSummaryResponse(BaseModel):
    """Money in vs money out for the window.

    ``sales_revenue`` (completed sales) plus ad-hoc incomes, minus ad-hoc
    expenses. Soft-deleted finance entries are excluded — a deleted entry
    is a correction, not spend.
    """

    sales_revenue: Decimal
    income_total: Decimal
    expense_total: Decimal
    net: Decimal
    expenses_by_category: list[FinanceCategoryTotal]
    incomes_by_category: list[FinanceCategoryTotal]


# ── Sell payments: revenue grouped by payment method ──────────────────────


class SellPaymentLine(BaseModel):
    """Completed-sales revenue for one payment method.

    Maps to the on-screen **Sell Payment Report**.
    """

    payment_method: str
    sales_count: int
    revenue: Decimal


class SellPaymentsResponse(BaseModel):
    lines: list[SellPaymentLine]
    total_revenue: Decimal


# ── Tax report: tax collected per day ─────────────────────────────────────


class TaxDay(BaseModel):
    """One calendar day (UTC) of collected tax.

    Maps to the on-screen **Tax Report**. ``taxable_revenue`` counts
    completed sales only; voided/refunded sales contribute counts, never
    revenue or tax.
    """

    date: date
    taxable_revenue: Decimal
    tax_collected: Decimal
    sales_count: int


class TaxReportResponse(BaseModel):
    days: list[TaxDay]
    total_tax: Decimal
    total_taxable_revenue: Decimal


# ── Register report: per-day takings split by payment method ──────────────


class RegisterDayMethod(BaseModel):
    payment_method: str
    sales_count: int
    revenue: Decimal


class RegisterDay(BaseModel):
    """One calendar day of register activity.

    Maps to the on-screen **Register Report** — the shift-close view:
    revenue + ticket counts + void/refund counts, with the per-method
    split a cashier needs to reconcile the drawer.
    """

    date: date
    revenue: Decimal
    sales_count: int
    voided_count: int
    refunded_count: int
    by_method: list[RegisterDayMethod]


class RegisterReportResponse(BaseModel):
    days: list[RegisterDay]


# ── Expense report: ad-hoc spend, detail + category totals ────────────────


class ExpenseReportLine(BaseModel):
    id: UUID
    category: str
    amount: Decimal
    description: str
    payment_method: str
    store_id: UUID
    occurred_at: datetime
    actor_id: UUID | None = None


class ExpenseReportResponse(BaseModel):
    """Maps to the on-screen **Expense Report**."""

    lines: list[ExpenseReportLine]
    total: Decimal
    by_category: list[FinanceCategoryTotal]


# ── Profit / loss: sales + incomes − expenses ─────────────────────────────


class ProfitLossResponse(BaseModel):
    """Maps to the on-screen **Profit / Loss Report** (POS-side leg).

    Purchase costs live in Inventory Service (separate database, no
    cross-service JOIN) — the app subtracts
    ``purchase_cost + waste_cost`` client-side for the full P&L, or a
    dedicated BFF composes them. This endpoint reports the POS-side net
    so the number here can never disagree with ``finance-summary``.
    """

    sales_revenue: Decimal
    income_total: Decimal
    expense_total: Decimal
    gross_profit: Decimal
    net: Decimal
    expenses_by_category: list[FinanceCategoryTotal]
    incomes_by_category: list[FinanceCategoryTotal]


# ── Customer groups: spend grouped by customer group tag ──────────────────


class CustomerGroupLine(BaseModel):
    """One customer group bucket.

    Maps to the on-screen **Customer Groups Report**. Customers without a
    group land in the ``ungrouped`` bucket rather than vanishing.
    """

    group: str
    customer_count: int
    sales_count: int
    revenue: Decimal


class CustomerGroupsResponse(BaseModel):
    lines: list[CustomerGroupLine]


# ── Supplier & customer: customer-spend leg (supplier leg is inventory) ────


class CustomerSpendLine(BaseModel):
    customer_id: UUID | None
    customer_name: str
    sales_count: int
    total_spent: Decimal


class CustomerSpendResponse(BaseModel):
    """Customer-spend leg of the **Supplier & Customer Report**.

    A null ``customer_id`` row is the walk-in bucket (sales with no
    attributed customer). The supplier-purchases leg lives in Inventory
    Service's ``product-purchases`` report — the app renders both legs
    side by side for the combined screen.
    """

    lines: list[CustomerSpendLine]
