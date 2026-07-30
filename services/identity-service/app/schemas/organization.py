"""Schemas for the Organization model."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class OrganizationBase(BaseModel):
    """Shared fields for organization schemas."""

    name: str
    legal_name: str | None = None
    country_code: str = "TZ"
    default_timezone: str = "Africa/Dar_es_Salaam"
    owner_user_id: UUID


class OrganizationCreate(OrganizationBase):
    """Fields required to create an organization."""


class OrganizationUpdate(BaseModel):
    """Fields that may be updated on an organization (partial update)."""

    name: str | None = None
    legal_name: str | None = None
    country_code: str | None = None
    default_timezone: str | None = None


class OrganizationRead(OrganizationBase):
    """Full organization representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
