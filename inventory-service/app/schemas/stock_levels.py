"""Schemas for StockLevel — read-only.

═══════════════════════════════════════════════════════════════════════════
StockLevelRead includes denormalized item_name and item_unit_of_measure
═══════════════════════════════════════════════════════════════════════════

These fields are populated by a JOIN in the service layer so that callers
can display "12 kg of Rice" without a second lookup.  Implementing the
JOIN now (in the ``get_stock_levels`` / ``get_stock_level`` service
methods, Stage 5+) rather than deferring to Stage 8 minimizes coupling
between the API and internal representation and avoids a
backwards-incompatible schema change later.

No Create / Update / Delete schemas exist — stock_levels is never written
directly via a generic API.  The only way to modify a stock level is
through ``record_movement`` (Stage 5).
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StockLevelRead(BaseModel):
    """Current stock level for an item at a specific location, with denormalized item info."""

    model_config = ConfigDict(from_attributes=True)

    item_id: UUID
    business_location_id: UUID
    current_quantity: Decimal
    updated_at: datetime
    item_name: str
    item_unit_of_measure: str