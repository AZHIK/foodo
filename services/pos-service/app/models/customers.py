"""Customer domain model — a business's own customer ledger.

═══════════════════════════════════════════════════════════════════════════
``id`` IS CLIENT-GENERATED  (design decision)
═══════════════════════════════════════════════════════════════════════════

Every other synced entity in this service (``Sale``, ``OtherExpense``, ...)
uses a dual identity: a client-generated idempotency key plus a separate
server-assigned UUID. That pattern cannot work here, because ``Sale.
customer_id`` (see ``app/models/pos.py``) is a REAL foreign key to this
table, and a sale rung up offline against an offline-created customer has
no server id to put in that column yet — and ``Sale`` rows are never
rewritten after creation.

So the device generates the customer's UUID itself and uses it as this
row's real primary key from the very first write. The PK's own uniqueness
constraint IS the idempotency check for sync — no separate client-id
column is needed. This is what makes a customer picked mid-checkout
immediately usable in a sale, fully offline, with no reconciliation step.

``default_factory=uuid4`` below exists only as a convenience for
constructing a ``Customer`` without an explicit id (e.g. in tests) — the
real creation path (``app/services/customer_service.py``'s
``_create_customer_internal``) always passes the client-supplied id
explicitly.

═══════════════════════════════════════════════════════════════════════════
BUSINESS-SCOPED, NOT STORE-SCOPED
═══════════════════════════════════════════════════════════════════════════

Unlike ``OtherExpense``/``OtherIncome`` (store-scoped), a ``Customer`` has
no ``store_id`` — a customer is shared across all of a business's stores.
``Sale.store_id`` still records which store rang up a given sale; the
customer relationship is business-wide.

═══════════════════════════════════════════════════════════════════════════
SOFT DELETE IS REQUIRED HERE, NOT JUST CONVENTIONAL
═══════════════════════════════════════════════════════════════════════════

``Sale.customer_id`` points at this table. A hard delete (even with
``ON DELETE SET NULL``) would still be reachable via an explicit ``DELETE``
that destroys the row while sales referencing it survive with a dangling
memory of "some customer, now gone." Soft-delete removes the customer from
every list view while every past sale's attribution — and every "Total
spent" figure — stays intact and correct.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Index, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Field, SQLModel


class Customer(SQLModel, table=True):
    """A business's own customer record — name/phone/email for order
    attribution and order-history lookups. Not an authenticating identity
    (contrast with Identity Service's ``UserCategory.CONSUMER``, a separate,
    unrelated concept: a marketplace self-service user, not a restaurant's
    own client ledger entry).
    """

    __tablename__ = "customers"
    __table_args__ = (
        Index("ix_customers_business_id_phone", "business_id", "phone"),
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
    email: str | None = Field(default=None, max_length=255)
    address_line1: str | None = Field(default=None, max_length=500)
    actor_id: UUID | None = Field(
        default=None,
        index=True,
        sa_type=PG_UUID,
    )
    joined_at: datetime = Field(
        nullable=False,
        sa_type=DateTime(timezone=True),
    )
    synced_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )
    device_sequence: int | None = Field(default=None)
    is_time_suspect: bool = Field(
        default=False,
        nullable=False,
        sa_column_kwargs={"server_default": "false"},
    )
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
