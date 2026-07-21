"""Schemas for the BusinessLocation model.

location_type is validated by the LocationType enum at the schema level.
Cross-validation against business_type is business logic — out of scope here.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.business import LocationType


class BusinessLocationBase(BaseModel):
    """Shared fields for business location schemas."""

    business_id: UUID
    name: str
    location_type: LocationType
    country_code: str = "TZ"
    city: str | None = None
    address: str | None = None
    timezone: str = "Africa/Dar_es_Salaam"
    is_primary: bool = False


class BusinessLocationCreate(BusinessLocationBase):
    """Fields required to create a business location.

    location_type must be one of: head_office, restaurant_branch, kitchen,
    warehouse, farm, depot. Other values are rejected at the schema level.
    """


class BusinessLocationUpdate(BaseModel):
    """Fields that may be updated on a business location (partial update)."""

    name: str | None = None
    location_type: LocationType | None = None
    country_code: str | None = None
    city: str | None = None
    address: str | None = None
    timezone: str | None = None
    is_primary: bool | None = None


class BusinessLocationRead(BusinessLocationBase):
    """Full business location representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
