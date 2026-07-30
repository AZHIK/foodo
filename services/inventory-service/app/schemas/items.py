"""Schemas for the Item model.

═══════════════════════════════════════════════════════════════════════════
ItemCreate includes business_id and business_location_id — why?
═══════════════════════════════════════════════════════════════════════════

Unlike Identity Service's BusinessCreateRequest (where owner_user_id is
derivable from the JWT's ``sub`` claim and is intentionally omitted from
the request body), an item's *business context* is NOT always derivable
from the JWT alone:

- A business user may hold access to multiple businesses through their
  ``other_businesses`` claim, and the ``active_business_id`` in the JWT
  reflects their *current switch*, not necessarily the business they want
  to create an item for.
- During automated / system-to-system creation (e.g. bulk import from a
  supplier catalog), no user JWT is involved at all.

Therefore the schema accepts these IDs explicitly.  The endpoint layer
MAY override them (e.g. force them to match the authenticated user's
context) but the schema itself is honest about what data it needs.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.inventory import ItemType, UnitOfMeasure


class ItemBase(BaseModel):
    """Shared fields for item schemas."""

    name: str
    unit_of_measure: UnitOfMeasure
    category: str | None = None
    reorder_threshold: Decimal
    reorder_quantity: Decimal
    allow_negative_stock: bool = False
    item_type: ItemType


class ItemCreate(ItemBase):
    """Fields required to create an item.

    ``business_id`` is intentionally absent — it is taken from the URL path
    (``/businesses/{business_id}/items``) and cross-validated against the
    JWT's ``active_business_id`` by the endpoint layer.

    ``business_location_id`` is required here because the caller knows which
    location within the business this item belongs to.  The endpoint layer
    does NOT override it.
    """

    business_location_id: UUID


class ItemUpdate(BaseModel):
    """Fields that may be updated on an item (partial update).

    Excludes business_id and business_location_id — an item's location
    should not change via a generic PATCH.  Transferring an item between
    locations is a separate operation handled by a dedicated endpoint in a
    later stage.
    """

    name: str | None = None
    unit_of_measure: UnitOfMeasure | None = None
    category: str | None = None
    reorder_threshold: Decimal | None = None
    reorder_quantity: Decimal | None = None
    allow_negative_stock: bool | None = None
    item_type: ItemType | None = None
    is_active: bool | None = None


class ItemRead(ItemBase):
    """Full item representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    business_location_id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime


class ItemListFilters(BaseModel):
    """Query-parameter schema for the list-items endpoint (Stage 4)."""

    category: str | None = None
    is_active: bool | None = None
    below_threshold: bool | None = None
    business_location_id: UUID | None = None