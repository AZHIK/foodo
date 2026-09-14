"""Schemas for Recipe / RecipeComponent (Stage 1: Recipe CRUD).

A recipe is a bill-of-materials for one sellable item — "Pilau = 200g rice
+ 100g meat + 20ml oil + 30g onions". Quantities are expressed in the raw
material item's own unit (the unit the stockroom counts it in), so no unit
conversion is part of this stage.

Update semantics are full-replace, not partial-patch: ``RecipeUpdate``
carries a complete component list and the endpoint deletes-then-inserts it.
A partial "add/remove one line" patch invites lost-update races between two
editors and complicates validation (e.g. "remove the last line" must still
be rejected as an empty recipe) — replace-the-set is the simplest correct
shape, matching how the owner thinks about a recipe card.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class RecipeComponentInput(BaseModel):
    """One ingredient line on a create/update payload.

    ``quantity_required`` is the amount of the raw material consumed to
    produce ONE unit of the sellable item, in the raw material's own unit.
    Strictly positive — a zero or negative ingredient line is meaningless.
    """

    raw_material_item_id: UUID
    quantity_required: Decimal = Field(gt=Decimal("0"))


class RecipeCreate(BaseModel):
    """Create a recipe for a sellable item.

    ``name`` defaults to the sellable item's own name when omitted. At least
    one component is required — a recipe with zero ingredients is meaningless
    and is rejected here, not at the database.
    """

    sellable_item_id: UUID
    name: str | None = Field(default=None, max_length=255)
    components: list[RecipeComponentInput] = Field(min_length=1)


class RecipeUpdate(BaseModel):
    """Replace a recipe's component list (full set) and optionally rename it.

    ``components`` is required and replaces the stored set entirely — lines
    absent from the payload are deleted. ``name=None`` keeps the existing
    name; pass a value to rename.
    """

    name: str | None = Field(default=None, max_length=255)
    components: list[RecipeComponentInput] = Field(min_length=1)


class RecipeComponentRead(BaseModel):
    """One stored ingredient line with resolved item details.

    IDs alone are not enough for the owner reading a recipe card — the read
    resolves the raw material's name and unit code ("200g Rice", not a
    ``raw_material_item_id``). ``raw_material_unit`` is ``""`` when the item
    has no unit assigned (nullable FK server-side), mirroring the stock-level
    read convention in ``reports.py``.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    recipe_id: UUID
    raw_material_item_id: UUID
    raw_material_name: str
    raw_material_unit: str
    quantity_required: Decimal


class RecipeRead(BaseModel):
    """A recipe header with its full resolved component list."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    sellable_item_id: UUID
    sellable_item_name: str
    name: str
    created_at: datetime
    updated_at: datetime
    components: list[RecipeComponentRead] = []
