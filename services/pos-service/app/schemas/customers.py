"""Customer schemas — sync input, batch envelope, read models, updates, filters.

Mirrors ``app/schemas/finance.py``'s structure and design decisions
(partial-success batch sync, mutable-with-soft-delete entries). One
divergence: ``CustomerSyncInput.id`` is the CLIENT-GENERATED UUID that
becomes the row's real primary key — see ``app/models/customers.py``'s
module docstring for why. There is no separate ``client_customer_id``
column; the id itself is the idempotency key.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator

# ── Sync input ──────────────────────────────────────────────────────────


class CustomerSyncInput(BaseModel):
    """One customer within a sync batch, submitted by the offline device.

    ``id`` is generated on-device and IS the customer's permanent identity
    — not an idempotency key for a separately-assigned server id.
    """

    id: UUID
    name: str = Field(min_length=1, max_length=255)
    phone: str = Field(min_length=1, max_length=50)
    email: str | None = Field(default=None, max_length=255)
    address_line1: str | None = Field(default=None, max_length=500)
    joined_at: datetime
    device_sequence: int | None = None

    @field_validator("joined_at")
    @classmethod
    def _assume_naive_is_utc(cls, value: datetime) -> datetime:
        """Treat a timezone-naive timestamp as UTC rather than crashing later.

        Copied from ``SaleSyncInput`` — a plain
        ``DateTime.now().toIso8601String()`` on the Dart side has no
        timezone marker.
        """
        return value if value.tzinfo is not None else value.replace(tzinfo=UTC)


class CustomerSyncBatchRequest(BaseModel):
    """Batch of offline-created customers from a device."""

    customers: list[CustomerSyncInput] = Field(min_length=1)


class CustomerSyncResult(BaseModel):
    """Outcome for a single customer id within a batch sync.

    ``created`` — first time this id has been seen.
    ``duplicate`` — already exists, owned by the SAME business (a benign
    retry — e.g. the client resent a batch it never got a response for).
    ``failed`` — validation error, or the id is already owned by a
    DIFFERENT business (never reported as ``duplicate`` — that would let
    the client mark the row synced and reference a customer it does not
    own).
    """

    client_customer_id: str
    status: Literal["created", "duplicate", "failed"]
    reason: str | None = None


class CustomerSyncBatchResponse(BaseModel):
    """Per-customer results for a batch sync. Not all-or-nothing."""

    results: list[CustomerSyncResult]


class CustomerUpdate(BaseModel):
    """Partial update to an already-synced customer (PATCH body)."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    phone: str | None = Field(default=None, min_length=1, max_length=50)
    email: str | None = Field(default=None, max_length=255)
    address_line1: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def _reject_empty_update(self) -> CustomerUpdate:
        if not self.model_fields_set:
            raise ValueError("At least one field must be provided in an update")
        return self


class CustomerRead(BaseModel):
    """Full server-side customer representation, including server-computed
    order aggregates (never stored — see ``app/services/customer_service.py``).
    """

    id: UUID
    business_id: UUID
    name: str
    phone: str
    email: str | None = None
    address_line1: str | None = None
    actor_id: UUID | None = None
    joined_at: datetime
    synced_at: datetime
    device_sequence: int | None = None
    is_time_suspect: bool = False
    updated_at: datetime
    is_deleted: bool = False
    created_at: datetime
    total_orders: int
    total_spent: Decimal
    last_order_at: datetime | None = None


class CustomerListItem(CustomerRead):
    """Compact customer representation for list endpoints (same shape as read)."""


class CustomerListResponse(BaseModel):
    """Paginated list response for customers."""

    items: list[CustomerListItem]
    total: int
    limit: int
    offset: int


class CustomerListFilters(BaseModel):
    """Query-parameter schema for listing customers. All filters optional."""

    search: str | None = None
    include_deleted: bool = False
