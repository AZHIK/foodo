"""Finance schemas — sync input, batch envelope, read models, updates, filters.

Mirrors ``app/schemas/sales.py``'s structure and design decisions:

=============================================================================
PARTIAL-SUCCESS BATCH DESIGN  (same as sales)
=============================================================================
The batch sync endpoints return one result per submitted client id
(``created``, ``duplicate``, or ``failed``). A batch is NOT all-or-nothing
at the HTTP level — individual entries within a batch succeed or fail
independently, so the client can stop retrying successes without losing
visibility into failures.

=============================================================================
ENTRIES ARE MUTABLE  (unlike sales)
=============================================================================
Unlike a ``Sale``, an other-expense/other-income entry can be edited or
soft-deleted after it has synced — see ``OtherExpenseUpdate``/
``OtherIncomeUpdate`` and the DELETE endpoints in
``app/api/v1/endpoints/other_expenses.py``/``other_incomes.py``.

Category literals are hardcoded here (rather than derived from
``app.models.finance``'s enums) to match ``sales.py``'s existing convention
of spelling out ``Literal[...]`` values directly — keep the two lists in
sync with ``ExpenseCategory``/``IncomeCategory`` by hand.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator

ExpenseCategoryLiteral = Literal[
    "rent",
    "utilities",
    "salaries",
    "repairs",
    "supplies",
    "marketing",
    "insurance",
    "professional_fees",
    "other",
]

IncomeCategoryLiteral = Literal[
    "catering",
    "grants",
    "rebates",
    "space_rental",
    "equipment_rental",
    "other",
]


# ── Other expenses — sync input ────────────────────────────────────────


class OtherExpenseSyncInput(BaseModel):
    """One expense entry within a sync batch, submitted by the offline device."""

    client_expense_id: str
    store_id: UUID
    category: ExpenseCategoryLiteral
    amount: Decimal = Field(gt=Decimal("0"))
    description: str = Field(min_length=1, max_length=500)
    payment_method: Literal["cash", "mobile_money", "card", "other"]
    payee: str | None = None
    note: str | None = None
    receipt_attachment_id: UUID | None = None
    occurred_at: datetime
    device_sequence: int | None = None

    @field_validator("occurred_at")
    @classmethod
    def _assume_naive_is_utc(cls, value: datetime) -> datetime:
        """Treat a timezone-naive timestamp as UTC rather than crashing later.

        Copied from ``SaleSyncInput`` — a plain
        ``DateTime.now().toIso8601String()`` on the Dart side has no
        timezone marker, and comparing a naive timestamp against
        ``datetime.now(UTC)`` inside ``detect_time_drift`` raises
        ``TypeError`` rather than a usable error.
        """
        return value if value.tzinfo is not None else value.replace(tzinfo=UTC)


class OtherExpenseSyncBatchRequest(BaseModel):
    """Batch of offline-created expense entries from a device."""

    expenses: list[OtherExpenseSyncInput] = Field(min_length=1)


class FinanceSyncResult(BaseModel):
    """Outcome for a single client entry id within a batch sync.

    ``created`` — first time this client id has been seen.
    ``duplicate`` — already processed (idempotency key collision).
    ``failed`` — validation error (``reason`` contains details).
    """

    client_entry_id: str
    status: Literal["created", "duplicate", "failed"]
    reason: str | None = None


class OtherExpenseSyncBatchResponse(BaseModel):
    """Per-entry results for a batch sync. Not all-or-nothing."""

    results: list[FinanceSyncResult]


class OtherExpenseUpdate(BaseModel):
    """Partial update to an already-synced expense entry (PATCH body)."""

    category: ExpenseCategoryLiteral | None = None
    amount: Decimal | None = Field(default=None, gt=Decimal("0"))
    description: str | None = Field(default=None, min_length=1, max_length=500)
    payment_method: Literal["cash", "mobile_money", "card", "other"] | None = None
    payee: str | None = None
    note: str | None = None
    receipt_attachment_id: UUID | None = None
    occurred_at: datetime | None = None

    @field_validator("occurred_at")
    @classmethod
    def _assume_naive_is_utc(cls, value: datetime | None) -> datetime | None:
        if value is None or value.tzinfo is not None:
            return value
        return value.replace(tzinfo=UTC)

    @model_validator(mode="after")
    def _reject_empty_update(self) -> OtherExpenseUpdate:
        if not self.model_fields_set:
            raise ValueError("At least one field must be provided in an update")
        return self


class OtherExpenseRead(BaseModel):
    """Full server-side expense representation returned by GET endpoints."""

    id: UUID
    business_id: UUID
    store_id: UUID
    client_expense_id: str
    category: str
    amount: Decimal
    description: str
    payee: str | None = None
    note: str | None = None
    payment_method: str
    receipt_attachment_id: UUID | None = None
    actor_id: UUID | None = None
    occurred_at: datetime
    synced_at: datetime
    device_sequence: int | None = None
    is_time_suspect: bool = False
    updated_at: datetime
    is_deleted: bool = False
    created_at: datetime


class OtherExpenseListItem(OtherExpenseRead):
    """Compact expense representation for list endpoints (same shape as read;
    no nested detail exists)."""


class OtherExpenseListResponse(BaseModel):
    """Paginated list response for other expenses."""

    items: list[OtherExpenseListItem]
    total: int
    limit: int
    offset: int


class ExpenseCategorySummary(BaseModel):
    """Aggregate for a single category in the expense summary."""

    category: str
    count: int
    total: Decimal


class OtherExpenseSummaryResponse(BaseModel):
    """Lightweight aggregate response feeding the app's summary cards."""

    total_count: int
    total_amount: Decimal
    category_breakdown: list[ExpenseCategorySummary]


# ── Other incomes — mirror of the expense schemas, with `source` instead
#    of `payee` and the income category list ─────────────────────────────


class OtherIncomeSyncInput(BaseModel):
    """One income entry within a sync batch, submitted by the offline device."""

    client_income_id: str
    store_id: UUID
    category: IncomeCategoryLiteral
    amount: Decimal = Field(gt=Decimal("0"))
    description: str = Field(min_length=1, max_length=500)
    payment_method: Literal["cash", "mobile_money", "card", "other"]
    source: str | None = None
    note: str | None = None
    receipt_attachment_id: UUID | None = None
    occurred_at: datetime
    device_sequence: int | None = None

    @field_validator("occurred_at")
    @classmethod
    def _assume_naive_is_utc(cls, value: datetime) -> datetime:
        return value if value.tzinfo is not None else value.replace(tzinfo=UTC)


class OtherIncomeSyncBatchRequest(BaseModel):
    """Batch of offline-created income entries from a device."""

    incomes: list[OtherIncomeSyncInput] = Field(min_length=1)


class OtherIncomeSyncBatchResponse(BaseModel):
    """Per-entry results for a batch sync. Not all-or-nothing."""

    results: list[FinanceSyncResult]


class OtherIncomeUpdate(BaseModel):
    """Partial update to an already-synced income entry (PATCH body)."""

    category: IncomeCategoryLiteral | None = None
    amount: Decimal | None = Field(default=None, gt=Decimal("0"))
    description: str | None = Field(default=None, min_length=1, max_length=500)
    payment_method: Literal["cash", "mobile_money", "card", "other"] | None = None
    source: str | None = None
    note: str | None = None
    receipt_attachment_id: UUID | None = None
    occurred_at: datetime | None = None

    @field_validator("occurred_at")
    @classmethod
    def _assume_naive_is_utc(cls, value: datetime | None) -> datetime | None:
        if value is None or value.tzinfo is not None:
            return value
        return value.replace(tzinfo=UTC)

    @model_validator(mode="after")
    def _reject_empty_update(self) -> OtherIncomeUpdate:
        if not self.model_fields_set:
            raise ValueError("At least one field must be provided in an update")
        return self


class OtherIncomeRead(BaseModel):
    """Full server-side income representation returned by GET endpoints."""

    id: UUID
    business_id: UUID
    store_id: UUID
    client_income_id: str
    category: str
    amount: Decimal
    description: str
    source: str | None = None
    note: str | None = None
    payment_method: str
    receipt_attachment_id: UUID | None = None
    actor_id: UUID | None = None
    occurred_at: datetime
    synced_at: datetime
    device_sequence: int | None = None
    is_time_suspect: bool = False
    updated_at: datetime
    is_deleted: bool = False
    created_at: datetime


class OtherIncomeListItem(OtherIncomeRead):
    """Compact income representation for list endpoints (same shape as read)."""


class OtherIncomeListResponse(BaseModel):
    """Paginated list response for other incomes."""

    items: list[OtherIncomeListItem]
    total: int
    limit: int
    offset: int


class IncomeCategorySummary(BaseModel):
    """Aggregate for a single category in the income summary."""

    category: str
    count: int
    total: Decimal


class OtherIncomeSummaryResponse(BaseModel):
    """Lightweight aggregate response feeding the app's summary cards."""

    total_count: int
    total_amount: Decimal
    category_breakdown: list[IncomeCategorySummary]


# ── Finance attachments ────────────────────────────────────────────────


class FinanceAttachmentRead(BaseModel):
    """Server representation of an uploaded receipt attachment."""

    id: UUID
    original_filename: str
    content_type: str
    byte_size: int
    created_at: datetime


# ── Query filters ───────────────────────────────────────────────────────


class OtherExpenseListFilters(BaseModel):
    """Query-parameter schema for listing other expenses. All filters optional."""

    from_date: datetime | None = None
    to_date: datetime | None = None
    category: ExpenseCategoryLiteral | None = None
    payment_method: Literal["cash", "mobile_money", "card", "other"] | None = None
    store_id: UUID | None = None
    include_deleted: bool = False


class OtherIncomeListFilters(BaseModel):
    """Query-parameter schema for listing other incomes. All filters optional."""

    from_date: datetime | None = None
    to_date: datetime | None = None
    category: IncomeCategoryLiteral | None = None
    payment_method: Literal["cash", "mobile_money", "card", "other"] | None = None
    store_id: UUID | None = None
    include_deleted: bool = False
