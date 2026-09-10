"""Schemas for the Supplier model."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class SupplierBase(BaseModel):
    """Shared fields for supplier schemas."""

    name: str
    phone: str | None = None
    email: str | None = None
    address_line1: str | None = None
    notes: str | None = None


class SupplierCreate(SupplierBase):
    """Fields required to create a supplier.

    ``business_id`` is intentionally absent — taken from the URL path
    (``/businesses/{business_id}/suppliers``), same convention as
    ``ItemCreate`` omitting it.
    """


class SupplierUpdate(BaseModel):
    """Partial update — every field optional."""

    name: str | None = None
    phone: str | None = None
    email: str | None = None
    address_line1: str | None = None
    notes: str | None = None


class SupplierRead(SupplierBase):
    """Full supplier representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    business_id: UUID
    created_at: datetime
    updated_at: datetime


class SupplierListFilters(BaseModel):
    """Query-parameter schema for the list-suppliers endpoint."""

    search: str | None = None
    include_deleted: bool = False


class SupplierListResponse(BaseModel):
    items: list[SupplierRead]
    total: int
    limit: int
    offset: int
