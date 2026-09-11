"""Schemas for the Category model — read-only for now.

No Create/Update/Delete schemas exist yet: categories are a global,
platform-seeded taxonomy (see ``app/models/categories.py``), managed via
migrations rather than a write API in this stage.
"""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CategoryRead(BaseModel):
    """Full category representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    sort_order: int
    is_active: bool
