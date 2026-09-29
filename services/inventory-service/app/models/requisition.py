"""Requisition domain models — unified multi-supplier order cart.

A ``Requisition`` is ONE staff-built order containing lines from MULTIPLE
suppliers. On submission it splits into SEPARATE ``PurchaseOrder`` rows —
one per supplier — each with its own PO number, totals, and lifecycle.

Additive by design: ``PurchaseOrder``/``Supplier``/``Item`` tables are NOT
restructured. This module only ADDS tables and nullable FK columns:

* ``requisition`` — header (NO status column; status rolls up from child POs)
* ``requisitionline`` — cart line with per-line ``supplier_id`` +
  ``unit_price_snapshot`` + ``price_unconfirmed`` +
  ``supplier_assignment_source``
* ``supplieritem`` — supplier↔item price catalogue (MOQ, lead time,
  preferred flag). Previously only ``Item.supplier_id`` (single preferred
  supplier) existed; this table enables true multi-supplier pricing without
  breaking that column.
* ``suppliermessage`` — prepared WhatsApp payload per PO (status stays
  ``draft``/``ready`` in this pass; no API send).

``Supplier.whatsapp_number``/``contact_person``/``is_active`` live on the
``Supplier`` table itself (added additively — see migration); ``phone``
remains the legacy field and is used as a fallback for the WhatsApp number.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from enum import Enum as PyEnum
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, Numeric, UniqueConstraint, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Field, ForeignKey, SQLModel


def _enum_db_values(enum_class: type[PyEnum]) -> list[str]:
    return [member.value for member in enum_class]


class AssignmentSource(str, PyEnum):
    MANUAL_PER_ITEM = "manual_per_item"
    BULK_ALL = "bulk_all"


class MessageDirection(str, PyEnum):
    OUTBOUND = "outbound"
    INBOUND = "inbound"


class MessageChannel(str, PyEnum):
    WHATSAPP = "whatsapp"
    IN_APP = "in_app"


class MessageStatus(str, PyEnum):
    DRAFT = "draft"
    READY = "ready"
    SENT = "sent"
    DELIVERED = "delivered"
    READ = "read"
    FAILED = "failed"


class Requisition(SQLModel, table=True):
    """One unified staff order; splits into per-supplier POs on submit.

    NO status column — see ``rollup_requisition_status`` in the service
    layer. ``idempotency_key`` guards duplicate submit / double-tap:
    unique per business, client-supplied.
    """

    id: UUID = Field(default_factory=uuid4, primary_key=True, nullable=False, sa_type=PG_UUID)
    business_id: UUID = Field(nullable=False, index=True, sa_type=PG_UUID)
    store_id: UUID = Field(nullable=False, index=True, sa_type=PG_UUID)
    created_by: UUID | None = Field(default=None, sa_type=PG_UUID)
    notes: str | None = Field(default=None, max_length=1000)
    expected_at: datetime | None = Field(default=None, sa_type=DateTime(timezone=True))
    idempotency_key: str | None = Field(default=None, max_length=128, index=True)
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

    __table_args__ = (
        UniqueConstraint("business_id", "idempotency_key", name="uq_requisition_business_idem"),
    )


class RequisitionLine(SQLModel, table=True):
    """One cart line. ``supplier_id`` is written by BOTH per-item and bulk
    assignment — bulk is a convenience layer over this same field."""

    id: UUID = Field(default_factory=uuid4, primary_key=True, nullable=False, sa_type=PG_UUID)
    requisition_id: UUID = Field(
        sa_column=Column(
            PG_UUID, ForeignKey("requisition.id", ondelete="CASCADE"), nullable=False, index=True
        ),
    )
    item_id: UUID = Field(
        sa_column=Column(
            PG_UUID, ForeignKey("item.id", ondelete="RESTRICT"), nullable=False, index=True
        ),
    )
    qty: Decimal = Field(nullable=False, sa_type=Numeric(precision=12, scale=3))
    supplier_id: UUID | None = Field(
        default=None,
        sa_column=Column(
            PG_UUID, ForeignKey("supplier.id", ondelete="RESTRICT"), nullable=True, index=True
        ),
    )
    unit_price_snapshot: Decimal | None = Field(
        default=None, sa_type=Numeric(precision=12, scale=4)
    )
    price_unconfirmed: bool = Field(default=False, nullable=False)
    supplier_assignment_source: AssignmentSource | None = Field(
        default=None,
        sa_column=Column(
            SAEnum(AssignmentSource, values_callable=_enum_db_values, name="assignmentsource"),
            nullable=True,
        ),
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )


class SupplierItem(SQLModel, table=True):
    """Price catalogue row for a supplier+item pairing."""

    __table_args__ = (
        UniqueConstraint("supplier_id", "item_id", name="uq_supplieritem_supplier_item"),
    )

    id: UUID = Field(default_factory=uuid4, primary_key=True, nullable=False, sa_type=PG_UUID)
    supplier_id: UUID = Field(
        sa_column=Column(
            PG_UUID, ForeignKey("supplier.id", ondelete="CASCADE"), nullable=False, index=True
        ),
    )
    item_id: UUID = Field(
        sa_column=Column(
            PG_UUID, ForeignKey("item.id", ondelete="CASCADE"), nullable=False, index=True
        ),
    )
    price: Decimal | None = Field(default=None, sa_type=Numeric(precision=12, scale=4))
    moq: Decimal | None = Field(default=None, sa_type=Numeric(precision=12, scale=3))
    lead_time_days: int | None = Field(default=None)
    is_preferred: bool = Field(default=False, nullable=False)
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


class SupplierMessage(SQLModel, table=True):
    """Mirrored message record per PO. ``payload`` is the provider-agnostic
    WhatsApp JSON (see service ``build_whatsapp_payload``). Status stays
    ``draft``/``ready`` in this pass — never auto-advanced past ``ready``."""

    id: UUID = Field(default_factory=uuid4, primary_key=True, nullable=False, sa_type=PG_UUID)
    po_id: UUID = Field(
        sa_column=Column(
            PG_UUID, ForeignKey("purchaseorder.id", ondelete="CASCADE"), nullable=False, index=True
        ),
    )
    direction: MessageDirection = Field(
        default=MessageDirection.OUTBOUND,
        sa_column=Column(
            SAEnum(MessageDirection, values_callable=_enum_db_values, name="messagedirection"),
            nullable=False,
        ),
    )
    channel: MessageChannel = Field(
        default=MessageChannel.WHATSAPP,
        sa_column=Column(
            SAEnum(MessageChannel, values_callable=_enum_db_values, name="messagechannel"),
            nullable=False,
            index=True,
        ),
    )
    payload: dict = Field(default_factory=dict, sa_column=Column(JSONB, nullable=False))
    status: MessageStatus = Field(
        default=MessageStatus.READY,
        sa_column=Column(
            SAEnum(MessageStatus, values_callable=_enum_db_values, name="messagestatus"),
            nullable=False,
            index=True,
        ),
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )
    sent_at: datetime | None = Field(default=None, sa_type=DateTime(timezone=True))
