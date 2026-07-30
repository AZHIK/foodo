"""Inventory domain models — items, stock levels, movements, and related tables.

═══════════════════════════════════════════════════════════════════════════
CROSS-SERVICE REFERENCE CONVENTION
═══════════════════════════════════════════════════════════════════════════

Columns named ``business_id`` and ``business_location_id`` store UUIDs that
reference rows in Identity Service's database (``businesses`` and
``business_locations`` tables).  These are stored as **plain indexed UUID
columns with no foreign key constraint** because the referenced tables live
in a separate database (the Identity Service's Postgres instance).

This is the correct pattern in a microservices architecture — foreign keys
cannot span database boundaries.  Referential integrity is enforced at the
application layer (every request is scoped by an authenticated JWT that
already ties the caller to a specific business context).

Do NOT add FK constraints to these columns.  If you feel tempted, re-read
the line above about separate databases.

═══════════════════════════════════════════════════════════════════════════
IMMUTABLE TABLE CONVENTION
═══════════════════════════════════════════════════════════════════════════

``stock_movements`` is an **immutable audit trail**.  Rows in this table
must never be updated or deleted by application code — only inserted.
It intentionally has no ``updated_at`` column.  Violating this convention
will corrupt the audit trail and make financial reconciliation impossible.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from enum import Enum as PyEnum
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Numeric, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Column, Field, ForeignKey, SQLModel


# ═══════════════════════════════════════════════════════════════════════
# Enums
# ═══════════════════════════════════════════════════════════════════════


class UnitOfMeasure(str, PyEnum):
    """Measurement units supported for item quantities."""

    KG = "kg"
    G = "g"
    L = "l"
    ML = "ml"
    UNIT = "unit"
    PACK = "pack"


class ItemType(str, PyEnum):
    """Classification of an item's role in the business — determines which movement types affect it.

    Semantics that Stage 5's ``record_movement`` must enforce:

    * ``sellable``
        - Decremented by ``sale`` / ``order.confirmed`` events.
        - Never incremented by ``purchase_received`` (you don't purchase a
          menu item from a supplier).
        - Waste, manual_adjustment, transfer_in, transfer_out still apply
          (physical stock corrections are not purchase-or-sale transactions).

    * ``raw_material``
        - Incremented by ``purchase_received``.
        - Decremented by ``waste``, ``manual_adjustment``, ``transfer_out``.
        - Never touched by ``sale`` / ``order`` events directly (no recipe
          decomposition in MVP — see ``RecipeComponent``'s docstring).

    * ``both``
        - A physical item purchased AND sold as-is with no transformation
          (e.g. a bottled drink bought from a supplier and resold unchanged).
        - Accepts either ``purchase_received`` or ``sale`` / ``order`` events.

    ``waste``, ``manual_adjustment``, ``transfer_in``, and ``transfer_out``
    apply to **any** item_type — these represent physical stock corrections
    or movement, not a purchase-or-sale transaction, so they are never
    restricted by this field.
    """

    SELLABLE = "sellable"
    RAW_MATERIAL = "raw_material"
    BOTH = "both"


class MovementType(str, PyEnum):
    """Category of stock movement for audit trail classification.

    ``sale_reversal`` — stock came back due to a voided sale
    (POS Service's ``sale.voided`` event).  ``refund_reversal`` —
    stock came back due to a refunded sale (POS Service's
    ``sale.refunded`` event).  Both are semantically distinct from
    ``manual_adjustment`` — an audit report should be able to count
    reversal movements separately from manual corrections.
    """

    SALE = "sale"
    PURCHASE_RECEIVED = "purchase_received"
    MANUAL_ADJUSTMENT = "manual_adjustment"
    WASTE = "waste"
    TRANSFER_IN = "transfer_in"
    TRANSFER_OUT = "transfer_out"
    SALE_REVERSAL = "sale_reversal"
    REFUND_REVERSAL = "refund_reversal"


class ActorType(str, PyEnum):
    """Who or what caused a stock movement."""

    USER = "user"
    SYSTEM = "system"
    SERVICE = "service"


# ═══════════════════════════════════════════════════════════════════════
# Tables
# ═══════════════════════════════════════════════════════════════════════


class Item(SQLModel, table=True):
    """Master record for a single stock-keeping unit (SKU).

    ``business_id`` and ``business_location_id`` are cross-service
    references to Identity Service's ``businesses`` and
    ``business_locations`` tables (see module docstring for rationale).
    """

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
    business_location_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    name: str = Field(nullable=False, max_length=255)
    unit_of_measure: UnitOfMeasure = Field(nullable=False)
    category: str | None = Field(default=None, max_length=255)
    reorder_threshold: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=3),
    )
    reorder_quantity: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=3),
    )
    allow_negative_stock: bool = Field(default=False, nullable=False)
    item_type: ItemType = Field(nullable=False)
    is_active: bool = Field(default=True, nullable=False)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={
            "server_default": func.now(),
            "onupdate": func.now(),
        },
        nullable=False,
    )


class RecipeComponent(SQLModel, table=True):
    """Bill-of-materials relationship between a sellable item and its raw materials.

    **Deliberately unused in MVP.**  This table exists now so that
    bill-of-materials support (exploding a manufactured item into its
    component stock deductions) is additive later — a new service or
    endpoint that references this table, not a schema migration.  Do not
    seed, query, or reference this table from any business logic in
    Stage 1–5 of the Inventory Service build.
    """

    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        sa_type=PG_UUID,
    )
    sellable_item_id: UUID = Field(
        sa_column=Column(
            PG_UUID,
            ForeignKey("item.id", ondelete="CASCADE"),
            nullable=False,
        ),
    )
    raw_material_item_id: UUID = Field(
        sa_column=Column(
            PG_UUID,
            ForeignKey("item.id", ondelete="CASCADE"),
            nullable=False,
        ),
    )
    quantity_required: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=3),
    )


class StockLevel(SQLModel, table=True):
    """Current stock quantity for an item at a specific location.

    The (item_id, business_location_id) unique constraint is load-bearing
    for the upsert logic in Stage 5 — it enables an INSERT ... ON CONFLICT
    pattern that atomically creates-or-updates stock levels without a
    separate select-then-insert round trip.
    """

    __table_args__ = (
        UniqueConstraint(
            "item_id",
            "business_location_id",
            name="uq_stock_levels_item_location",
        ),
    )

    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        sa_type=PG_UUID,
    )
    item_id: UUID = Field(
        sa_column=Column(
            PG_UUID,
            ForeignKey("item.id", ondelete="CASCADE"),
            nullable=False,
        ),
    )
    business_location_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    current_quantity: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=3),
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={
            "server_default": func.now(),
            "onupdate": func.now(),
        },
        nullable=False,
    )


class StockMovement(SQLModel, table=True):
    """Immutable audit trail of every stock quantity change.

    **This table is append-only.**  Rows must never be updated or deleted
    by application code.  The absence of an ``updated_at`` column is
    intentional.
    """

    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        sa_type=PG_UUID,
    )
    item_id: UUID = Field(
        sa_column=Column(
            PG_UUID,
            ForeignKey("item.id", ondelete="CASCADE"),
            nullable=False,
        ),
    )
    business_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    business_location_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    quantity_delta: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=3),
    )
    movement_type: MovementType = Field(nullable=False)
    reference_type: str | None = Field(default=None, max_length=100)
    reference_id: UUID | None = Field(default=None, sa_type=PG_UUID)
    actor_type: ActorType = Field(nullable=False)
    actor_id: UUID | None = Field(default=None, sa_type=PG_UUID)
    reason: str | None = Field(default=None, max_length=500)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )


class ProcessedEvent(SQLModel, table=True):
    """Idempotency tracker for inbound events from the event bus.

    This table's only job is fast existence-checks via PRIMARY KEY lookup.
    Before processing an event, insert the event_id — if it already exists
    (unique violation), the event has already been processed and can be
    safely skipped.
    """

    event_id: str = Field(primary_key=True, nullable=False, max_length=255)
    processed_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )