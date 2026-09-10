"""Finance domain models — ad-hoc "other expense" / "other income" entries.

═══════════════════════════════════════════════════════════════════════════
CROSS-SERVICE REFERENCE CONVENTION
═══════════════════════════════════════════════════════════════════════════

Same convention as ``app/models/pos.py``: ``business_id``, ``store_id``, and
``actor_id`` are plain indexed UUID columns with **no** foreign key
constraint, because the referenced rows live in Identity Service's
database. Referential integrity is enforced at the application layer via
the authenticated JWT. Do NOT add FK constraints to these columns.

``receipt_attachment_id`` IS a real FK — ``finance_attachments`` lives in
this same database.

═══════════════════════════════════════════════════════════════════════════
FINANCE ENTRIES ARE MUTABLE, SALES ARE NOT
═══════════════════════════════════════════════════════════════════════════

``Sale`` rows are never edited or hard-deleted — a correction is a new
void/refund transition, fully auditable via ``voided_at``/``refunded_at``.
Other-expense and other-income entries have no such offsetting-entry
workflow anywhere in the product: the restaurant app ships plain Edit and
Delete actions for a mis-keyed ad-hoc entry. These tables therefore carry
``updated_at`` (bumped on every edit) and a soft-delete triplet
(``is_deleted``/``deleted_at``/``deleted_by``) that ``Sale`` doesn't need.

═══════════════════════════════════════════════════════════════════════════
CATEGORY STORAGE — VARCHAR, NOT A POSTGRES ENUM
═══════════════════════════════════════════════════════════════════════════

Unlike ``PaymentMethod``/``SaleStatus`` (stable, rarely-changing sets),
expense/income categories are expected to grow as the product does. A
Postgres enum type would turn every new category into an ``ALTER TYPE``
migration. Validity is instead enforced at the Pydantic schema layer
(``ExpenseCategory``/``IncomeCategory`` below double as the source of truth
for both layers), leaving the column itself a plain ``VARCHAR(50)``.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from enum import Enum as PyEnum
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Numeric, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy import ForeignKey as SAForeignKey
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Column, Field, SQLModel

from app.models.pos import PaymentMethod

# ═══════════════════════════════════════════════════════════════════════
# Enums
# ═══════════════════════════════════════════════════════════════════════


class ExpenseCategory(str, PyEnum):
    """Canonical expense category ids — mirrored verbatim in the Flutter
    app's ``mock_finance.dart`` catalogue and the Drift table doc comments.
    """

    RENT = "rent"
    UTILITIES = "utilities"
    SALARIES = "salaries"
    REPAIRS = "repairs"
    SUPPLIES = "supplies"
    MARKETING = "marketing"
    INSURANCE = "insurance"
    PROFESSIONAL_FEES = "professional_fees"
    OTHER = "other"


class IncomeCategory(str, PyEnum):
    """Canonical income category ids — mirrored verbatim on the Flutter side."""

    CATERING = "catering"
    GRANTS = "grants"
    REBATES = "rebates"
    SPACE_RENTAL = "space_rental"
    EQUIPMENT_RENTAL = "equipment_rental"
    OTHER = "other"


# ═══════════════════════════════════════════════════════════════════════
# Tables
# ═══════════════════════════════════════════════════════════════════════


class FinanceAttachment(SQLModel, table=True):
    """A stored receipt file, uploaded independently of the entry it will
    end up attached to (the client uploads before the offline entry has a
    server id — see ``app/services/receipt_storage.py``).
    """

    __tablename__ = "finance_attachments"

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
    storage_key: str = Field(
        nullable=False,
        max_length=500,
        unique=True,
    )
    original_filename: str = Field(nullable=False, max_length=255)
    content_type: str = Field(nullable=False, max_length=100)
    byte_size: int = Field(nullable=False)
    checksum_sha256: str | None = Field(default=None, max_length=64)
    uploaded_by: UUID | None = Field(
        default=None,
        sa_type=PG_UUID,
    )
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )


class OtherExpense(SQLModel, table=True):
    """An ad-hoc expense entry outside normal POS sales/inventory (e.g. rent,
    utilities, repairs). See module docstring for the mutability/soft-delete
    design decision.
    """

    __tablename__ = "other_expenses"

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
    store_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    client_expense_id: str = Field(
        nullable=False,
        max_length=255,
        unique=True,
    )
    category: str = Field(nullable=False, max_length=50, index=True)
    amount: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=2),
    )
    description: str = Field(nullable=False, max_length=500)
    payee: str | None = Field(default=None, max_length=255)
    note: str | None = Field(default=None, max_length=1000)
    payment_method: PaymentMethod = Field(
        sa_column=Column(
            SAEnum(
                PaymentMethod,
                name="paymentmethod",
                values_callable=lambda x: [e.value for e in x],
            ),
            nullable=False,
        ),
    )
    receipt_attachment_id: UUID | None = Field(
        default=None,
        sa_column=Column(
            PG_UUID,
            SAForeignKey("finance_attachments.id", ondelete="SET NULL"),
            nullable=True,
        ),
    )
    actor_id: UUID | None = Field(
        default=None,
        index=True,
        sa_type=PG_UUID,
    )
    occurred_at: datetime = Field(
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


class OtherIncome(SQLModel, table=True):
    """An ad-hoc income entry outside normal POS sales (e.g. catering
    deposits, space rental). Mirror of ``OtherExpense`` with ``source``
    instead of ``payee``.
    """

    __tablename__ = "other_incomes"

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
    store_id: UUID = Field(
        nullable=False,
        index=True,
        sa_type=PG_UUID,
    )
    client_income_id: str = Field(
        nullable=False,
        max_length=255,
        unique=True,
    )
    category: str = Field(nullable=False, max_length=50, index=True)
    amount: Decimal = Field(
        nullable=False,
        sa_type=Numeric(precision=12, scale=2),
    )
    description: str = Field(nullable=False, max_length=500)
    source: str | None = Field(default=None, max_length=255)
    note: str | None = Field(default=None, max_length=1000)
    payment_method: PaymentMethod = Field(
        sa_column=Column(
            SAEnum(
                PaymentMethod,
                name="paymentmethod",
                values_callable=lambda x: [e.value for e in x],
            ),
            nullable=False,
        ),
    )
    receipt_attachment_id: UUID | None = Field(
        default=None,
        sa_column=Column(
            PG_UUID,
            SAForeignKey("finance_attachments.id", ondelete="SET NULL"),
            nullable=True,
        ),
    )
    actor_id: UUID | None = Field(
        default=None,
        index=True,
        sa_type=PG_UUID,
    )
    occurred_at: datetime = Field(
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
