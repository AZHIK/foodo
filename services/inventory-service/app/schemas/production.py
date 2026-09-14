"""Schemas for production events (Stage 2).

INPUT UX (drives this shape): the owner measures ONE leading ingredient
("2kg rice") — every other consumption follows from the recipe ratio, and
the output suggestion is pre-filled but owner-adjustable. The request
therefore carries only what the owner actually enters; the server computes
the rest.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ProduceRequest(BaseModel):
    """Record a production run against a recipe.

    ``leading_quantity_used`` is the measured amount of the leading
    ingredient, in that ingredient's own unit — strictly positive, since no
    ratio can be computed from zero. ``actual_output_quantity`` is optional:
    omit it and the server commits the computed suggestion (the common case
    where portions came out as planned).
    """

    leading_item_id: UUID
    leading_quantity_used: Decimal = Field(gt=Decimal("0"))
    actual_output_quantity: Decimal | None = Field(default=None, gt=Decimal("0"))


class ProductionComponentRead(BaseModel):
    """One ingredient consumed by the event, with its resolved item details."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    production_event_id: UUID
    raw_material_item_id: UUID
    raw_material_name: str
    raw_material_unit: str
    quantity_consumed: Decimal


class ProductionEventRead(BaseModel):
    """A recorded production run: measured input, suggested vs actual output.

    Both output quantities are returned — their gap is the over-portioning
    signal future AI insights consume, so the API never discards it.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    store_id: UUID
    recipe_id: UUID
    recipe_name: str
    sellable_item_id: UUID
    sellable_item_name: str
    leading_component_item_id: UUID
    leading_quantity_used: Decimal
    suggested_output_quantity: Decimal
    actual_output_quantity: Decimal
    actor_id: UUID | None = None
    occurred_at: datetime
    created_at: datetime
    components: list[ProductionComponentRead] = []
