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

from datetime import date
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
