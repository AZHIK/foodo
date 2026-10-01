"""Courier schemas — create/update payloads and read models."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class CourierCreate(BaseModel):
    """Create a courier within a business."""

    name: str = Field(min_length=1, max_length=255)
    phone: str = Field(min_length=1, max_length=50)
    vehicle: str | None = Field(default=None, max_length=255)
    is_active: bool = True


class CourierUpdate(BaseModel):
    """Partial update to an already-created courier (PATCH body)."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    phone: str | None = Field(default=None, min_length=1, max_length=50)
    vehicle: str | None = Field(default=None, max_length=255)
    is_active: bool | None = None

    @model_validator(mode="after")
    def _reject_empty_update(self) -> CourierUpdate:
        if not self.model_fields_set:
            raise ValueError("At least one field must be provided in an update")
        return self


class CourierRead(BaseModel):
    """Full server-side courier representation."""

    id: UUID
    business_id: UUID
    name: str
    phone: str
    vehicle: str | None = None
    is_active: bool = True
    actor_id: UUID | None = None
    created_at: datetime
    updated_at: datetime


class CourierListResponse(BaseModel):
    """Paginated list response for couriers."""

    items: list[CourierRead]
    total: int
    limit: int
    offset: int
