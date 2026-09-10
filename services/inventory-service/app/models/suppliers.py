"""Supplier domain model — a business's vendor directory for restocking.

``business_id`` is a cross-service reference to Identity Service's
``businesses`` table (see ``app/models/inventory.py``'s module docstring for
the cross-service-reference convention this follows).

Business-scoped, not store-scoped: a supplier is shared across all of a
business's stores, the same rationale as ``Customer`` in pos-service having
no ``store_id``.

Soft-delete (``is_deleted``/``deleted_at``/``deleted_by``) is required, not
just conventional: ``Reorder.supplier_id`` is a real FK to this table, and a
past purchase order must keep its supplier attribution even after that
supplier is retired.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Field, SQLModel


class Supplier(SQLModel, table=True):
    """A vendor a business orders restock inventory from."""

    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        sa_type=PG_UUID,
    )
    business_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    name: str = Field(nullable=False, max_length=255)
    phone: str | None = Field(default=None, max_length=64)
    email: str | None = Field(default=None, max_length=255)
    address_line1: str | None = Field(default=None, max_length=255)
    notes: str | None = Field(default=None, max_length=1000)
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now(), "onupdate": func.now()},
        nullable=False,
    )
    is_deleted: bool = Field(
        default=False,
        nullable=False,
        index=True,
        sa_column_kwargs={"server_default": "false"},
    )
    deleted_at: datetime | None = Field(
        default=None,
        sa_type=DateTime(timezone=True),
    )
    deleted_by: UUID | None = Field(
        default=None,
        sa_type=PG_UUID,
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )
