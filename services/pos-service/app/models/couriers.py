"""Courier domain model — a business's delivery-rider ledger.

Couriers are a simple business-scoped ledger (like ``Customer``): name,
phone, vehicle, and an ``is_active`` availability flag. They are NOT login
accounts — contrast with Identity Service's ``UserCategory.DRIVER``, a
separate marketplace concept with its own JWT + ``delivery.*`` permissions.

``Sale.courier_id`` (see ``app/models/pos.py``) is a REAL foreign key to
this table with ``ON DELETE SET NULL``: deleting a courier never orphans a
sale, the sale simply loses its assignment. Phone uniqueness is scoped per
business via a composite unique constraint — the same phone may exist in
two different businesses, but never twice in one.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Field, SQLModel


class Courier(SQLModel, table=True):
    """A delivery courier owned by one business, shared across its stores."""

    __tablename__ = "couriers"
    __table_args__ = (
        UniqueConstraint("business_id", "phone", name="uq_couriers_business_id_phone"),
    )

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
    name: str = Field(nullable=False, max_length=255, index=True)
    phone: str = Field(nullable=False, max_length=50, index=True)
    vehicle: str | None = Field(default=None, max_length=255)
    is_active: bool = Field(
        default=True,
        nullable=False,
        index=True,
        sa_column_kwargs={"server_default": "true"},
    )
    actor_id: UUID | None = Field(
        default=None,
        index=True,
        sa_type=PG_UUID,
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now(), "onupdate": func.now()},
        nullable=False,
    )
