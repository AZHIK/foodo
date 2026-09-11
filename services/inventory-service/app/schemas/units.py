"""Schemas for the Unit model — read-only for now.

No Create/Update/Delete schemas exist yet: units are a global,
platform-seeded taxonomy (see ``app/models/units.py``), managed via
migrations/seeding rather than a write API in this stage — mirrors
``app/schemas/categories.py``.
"""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict


class UnitRead(BaseModel):
    """Full unit representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    abbreviation: str
    sort_order: int
    is_active: bool
