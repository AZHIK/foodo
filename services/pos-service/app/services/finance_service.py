from __future__ import annotations

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy.exc import IntegrityError
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.events import publish_event
from app.core.exceptions import DomainError
from app.models.finance import FinanceAttachment, OtherExpense, OtherIncome
from app.models.pos import PaymentMethod
from app.schemas.finance import (
    FinanceSyncResult,
    OtherExpenseSyncBatchRequest,
    OtherExpenseSyncBatchResponse,
    OtherExpenseSyncInput,
    OtherExpenseUpdate,
    OtherIncomeSyncBatchRequest,
    OtherIncomeSyncBatchResponse,
    OtherIncomeSyncInput,
    OtherIncomeUpdate,
)
from app.services.sale_service import detect_time_drift


class FinanceServiceError(DomainError):
    """Base for all finance service errors."""


class FinanceValidationError(FinanceServiceError):
    """An entry's input data fails business-rule validation."""


class FinanceNotFoundError(FinanceServiceError):
    """Raised when an entry doesn't exist (or doesn't belong to the business)."""


class FinanceStateError(FinanceServiceError):
    """Raised when mutating an entry that is already soft-deleted."""


# ═══════════════════════════════════════════════════════════════════════
# Other expenses
# ═══════════════════════════════════════════════════════════════════════


async def sync_expense_batch(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    batch: OtherExpenseSyncBatchRequest,
) -> OtherExpenseSyncBatchResponse:
    """Process a batch of offline-synced expense entries.

    Mirrors ``sync_sale_batch`` exactly: one savepoint per entry, partial
    success across the batch, idempotency via ``client_expense_id``. Unlike
    a sale, creating an expense has no downstream event consumer (no stock
    impact), so this does not call ``publish_event`` — only the mutation
    paths (``update_expense``/``soft_delete_expense``) do, for the audit log.
    """
    results: list[FinanceSyncResult] = []

    async with session.begin():
        for expense_input in batch.expenses:
            try:
                existing = await session.exec(
                    select(OtherExpense).where(
                        OtherExpense.client_expense_id == expense_input.client_expense_id
                    )
                )
                if existing.first() is not None:
                    results.append(
                        FinanceSyncResult(
                            client_entry_id=expense_input.client_expense_id,
                            status="duplicate",
                        )
                    )
                    continue

                async with session.begin_nested():
                    await _create_expense_internal(
                        session, business_id, actor_id, expense_input,
                    )

                results.append(
                    FinanceSyncResult(
                        client_entry_id=expense_input.client_expense_id,
                        status="created",
                    )
                )
            except FinanceValidationError as exc:
                results.append(
                    FinanceSyncResult(
                        client_entry_id=expense_input.client_expense_id,
                        status="failed",
                        reason=str(exc),
                    )
                )
            except IntegrityError:
                results.append(
                    FinanceSyncResult(
                        client_entry_id=expense_input.client_expense_id,
                        status="duplicate",
                    )
                )

    return OtherExpenseSyncBatchResponse(results=results)


async def _create_expense_internal(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    expense_input: OtherExpenseSyncInput,
) -> OtherExpense:
    if expense_input.receipt_attachment_id is not None:
        await _validate_attachment_ownership(
            session, business_id, expense_input.receipt_attachment_id,
        )

    now = datetime.now(UTC)
    is_time_suspect = detect_time_drift(expense_input.occurred_at, now)

    expense = OtherExpense(
        business_id=business_id,
        store_id=expense_input.store_id,
        client_expense_id=expense_input.client_expense_id,
        category=expense_input.category,
        amount=expense_input.amount.quantize(Decimal("0.01")),
        description=expense_input.description,
        payee=expense_input.payee,
        note=expense_input.note,
        payment_method=PaymentMethod(expense_input.payment_method),
        receipt_attachment_id=expense_input.receipt_attachment_id,
        actor_id=actor_id,
        occurred_at=expense_input.occurred_at,
        device_sequence=expense_input.device_sequence,
        is_time_suspect=is_time_suspect,
    )
    session.add(expense)
    await session.flush()
    return expense


async def update_expense(
    session: AsyncSession,
    business_id: UUID,
    expense_id: UUID,
    actor_id: UUID | None,
    patch: OtherExpenseUpdate,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> OtherExpense:
    expense = (
        await session.exec(
            select(OtherExpense).where(
                OtherExpense.id == expense_id,
                OtherExpense.business_id == business_id,
            )
        )
    ).first()
    if expense is None:
        raise FinanceNotFoundError(f"Expense {expense_id} not found for business {business_id}")
    if expense.is_deleted:
        raise FinanceStateError(f"Expense {expense_id} has been deleted")

    if patch.receipt_attachment_id is not None and (
        patch.receipt_attachment_id != expense.receipt_attachment_id
    ):
        await _validate_attachment_ownership(session, business_id, patch.receipt_attachment_id)

    update_data = patch.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "amount" and value is not None:
            value = Decimal(value).quantize(Decimal("0.01"))
        elif field == "payment_method" and value is not None:
            value = PaymentMethod(value)
        setattr(expense, field, value)

    session.add(expense)
    await session.flush()

    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:expense-update:{expense.id}",
            "business_id": str(business_id),
            "action": "other_expense.updated",
            "expense_id": str(expense.id),
            "actor_id": str(actor_id) if actor_id else None,
        },
    )

    await session.commit()
    # `updated_at` is server-computed (onupdate=func.now()), so SQLAlchemy
    # expires it on commit — refresh here so the caller's later synchronous
    # attribute reads (e.g. Pydantic's model_validate) don't trigger an
    # implicit lazy-load outside the async context (MissingGreenlet).
    await session.refresh(expense)
    return expense


async def soft_delete_expense(
    session: AsyncSession,
    business_id: UUID,
    expense_id: UUID,
    actor_id: UUID | None,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> None:
    expense = (
        await session.exec(
            select(OtherExpense).where(
                OtherExpense.id == expense_id,
                OtherExpense.business_id == business_id,
            )
        )
    ).first()
    if expense is None:
        raise FinanceNotFoundError(f"Expense {expense_id} not found for business {business_id}")

    if expense.is_deleted:
        # Idempotent — a repeated DELETE is a no-op, not an error.
        return

    now = datetime.now(UTC)
    expense.is_deleted = True
    expense.deleted_at = now
    expense.deleted_by = actor_id
    session.add(expense)
    await session.flush()

    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:expense-delete:{expense.id}",
            "business_id": str(business_id),
            "action": "other_expense.deleted",
            "expense_id": str(expense.id),
            "actor_id": str(actor_id) if actor_id else None,
        },
    )

    await session.commit()


# ═══════════════════════════════════════════════════════════════════════
# Other incomes
# ═══════════════════════════════════════════════════════════════════════


async def sync_income_batch(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    batch: OtherIncomeSyncBatchRequest,
) -> OtherIncomeSyncBatchResponse:
    """Process a batch of offline-synced income entries. Mirrors ``sync_expense_batch``."""
    results: list[FinanceSyncResult] = []

    async with session.begin():
        for income_input in batch.incomes:
            try:
                existing = await session.exec(
                    select(OtherIncome).where(
                        OtherIncome.client_income_id == income_input.client_income_id
                    )
                )
                if existing.first() is not None:
                    results.append(
                        FinanceSyncResult(
                            client_entry_id=income_input.client_income_id,
                            status="duplicate",
                        )
                    )
                    continue

                async with session.begin_nested():
                    await _create_income_internal(
                        session, business_id, actor_id, income_input,
                    )

                results.append(
                    FinanceSyncResult(
                        client_entry_id=income_input.client_income_id,
                        status="created",
                    )
                )
            except FinanceValidationError as exc:
                results.append(
                    FinanceSyncResult(
                        client_entry_id=income_input.client_income_id,
                        status="failed",
                        reason=str(exc),
                    )
                )
            except IntegrityError:
                results.append(
                    FinanceSyncResult(
                        client_entry_id=income_input.client_income_id,
                        status="duplicate",
                    )
                )

    return OtherIncomeSyncBatchResponse(results=results)


async def _create_income_internal(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    income_input: OtherIncomeSyncInput,
) -> OtherIncome:
    if income_input.receipt_attachment_id is not None:
        await _validate_attachment_ownership(
            session, business_id, income_input.receipt_attachment_id,
        )

    now = datetime.now(UTC)
    is_time_suspect = detect_time_drift(income_input.occurred_at, now)

    income = OtherIncome(
        business_id=business_id,
        store_id=income_input.store_id,
        client_income_id=income_input.client_income_id,
        category=income_input.category,
        amount=income_input.amount.quantize(Decimal("0.01")),
        description=income_input.description,
        source=income_input.source,
        note=income_input.note,
        payment_method=PaymentMethod(income_input.payment_method),
        receipt_attachment_id=income_input.receipt_attachment_id,
        actor_id=actor_id,
        occurred_at=income_input.occurred_at,
        device_sequence=income_input.device_sequence,
        is_time_suspect=is_time_suspect,
    )
    session.add(income)
    await session.flush()
    return income


async def update_income(
    session: AsyncSession,
    business_id: UUID,
    income_id: UUID,
    actor_id: UUID | None,
    patch: OtherIncomeUpdate,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> OtherIncome:
    income = (
        await session.exec(
            select(OtherIncome).where(
                OtherIncome.id == income_id,
                OtherIncome.business_id == business_id,
            )
        )
    ).first()
    if income is None:
        raise FinanceNotFoundError(f"Income {income_id} not found for business {business_id}")
    if income.is_deleted:
        raise FinanceStateError(f"Income {income_id} has been deleted")

    if patch.receipt_attachment_id is not None and (
        patch.receipt_attachment_id != income.receipt_attachment_id
    ):
        await _validate_attachment_ownership(session, business_id, patch.receipt_attachment_id)

    update_data = patch.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "amount" and value is not None:
            value = Decimal(value).quantize(Decimal("0.01"))
        elif field == "payment_method" and value is not None:
            value = PaymentMethod(value)
        setattr(income, field, value)

    session.add(income)
    await session.flush()

    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:income-update:{income.id}",
            "business_id": str(business_id),
            "action": "other_income.updated",
            "income_id": str(income.id),
            "actor_id": str(actor_id) if actor_id else None,
        },
    )

    await session.commit()
    # See the matching comment in update_expense — updated_at is
    # server-computed and gets expired on commit.
    await session.refresh(income)
    return income


async def soft_delete_income(
    session: AsyncSession,
    business_id: UUID,
    income_id: UUID,
    actor_id: UUID | None,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> None:
    income = (
        await session.exec(
            select(OtherIncome).where(
                OtherIncome.id == income_id,
                OtherIncome.business_id == business_id,
            )
        )
    ).first()
    if income is None:
        raise FinanceNotFoundError(f"Income {income_id} not found for business {business_id}")

    if income.is_deleted:
        return

    now = datetime.now(UTC)
    income.is_deleted = True
    income.deleted_at = now
    income.deleted_by = actor_id
    session.add(income)
    await session.flush()

    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:income-delete:{income.id}",
            "business_id": str(business_id),
            "action": "other_income.deleted",
            "income_id": str(income.id),
            "actor_id": str(actor_id) if actor_id else None,
        },
    )

    await session.commit()


# ═══════════════════════════════════════════════════════════════════════
# Shared
# ═══════════════════════════════════════════════════════════════════════


async def _validate_attachment_ownership(
    session: AsyncSession,
    business_id: UUID,
    attachment_id: UUID,
) -> None:
    """A receipt_attachment_id must exist and belong to *business_id* —
    the one cross-row check that prevents an attachment id leaking across
    tenants."""
    attachment = (
        await session.exec(
            select(FinanceAttachment).where(FinanceAttachment.id == attachment_id)
        )
    ).first()
    if attachment is None or attachment.business_id != business_id:
        raise FinanceValidationError(
            "receipt_attachment_id does not exist for this business"
        )
