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
