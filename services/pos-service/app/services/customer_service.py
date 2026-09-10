from __future__ import annotations

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func as sa_func
from sqlalchemy import or_ as sa_or
from sqlalchemy.exc import IntegrityError
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.events import publish_event
from app.core.exceptions import DomainError
from app.models.customers import Customer
from app.models.pos import Sale, SaleStatus
from app.schemas.customers import (
    CustomerListItem,
    CustomerSyncBatchRequest,
    CustomerSyncBatchResponse,
    CustomerSyncInput,
    CustomerSyncResult,
    CustomerUpdate,
)
from app.services.sale_service import detect_time_drift


class CustomerServiceError(DomainError):
    """Base for all customer service errors."""


class CustomerValidationError(CustomerServiceError):
    """A customer's input data fails business-rule validation."""


class CustomerNotFoundError(CustomerServiceError):
    """Raised when a customer doesn't exist (or doesn't belong to the business)."""


class CustomerStateError(CustomerServiceError):
    """Raised when mutating a customer that is already soft-deleted."""


async def sync_customer_batch(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    batch: CustomerSyncBatchRequest,
) -> CustomerSyncBatchResponse:
    """Process a batch of offline-created customers.

    Mirrors ``sync_expense_batch``'s savepoint/partial-success shape, with
    one divergence: ``CustomerSyncInput.id`` is client-generated and IS the
    row's real primary key (see ``app/models/customers.py``), so the
    pre-existence check must also verify ownership — an id already used by
    a DIFFERENT business is reported ``failed``, never ``duplicate``.
    ``duplicate`` would let the client mark the row synced and then
    reference a customer it does not own.
    """
    results: list[CustomerSyncResult] = []

    async with session.begin():
        for customer_input in batch.customers:
            try:
                existing = (
                    await session.exec(
                        select(Customer).where(Customer.id == customer_input.id)
                    )
                ).first()
                if existing is not None:
                    if existing.business_id != business_id:
                        results.append(
                            CustomerSyncResult(
                                client_customer_id=str(customer_input.id),
                                status="failed",
                                reason="customer id is already in use",
                            )
                        )
                    else:
                        results.append(
                            CustomerSyncResult(
                                client_customer_id=str(customer_input.id),
                                status="duplicate",
                            )
                        )
                    continue

                async with session.begin_nested():
                    await _create_customer_internal(
                        session, business_id, actor_id, customer_input,
                    )

                results.append(
                    CustomerSyncResult(
                        client_customer_id=str(customer_input.id),
                        status="created",
                    )
                )
            except CustomerValidationError as exc:
                results.append(
                    CustomerSyncResult(
                        client_customer_id=str(customer_input.id),
                        status="failed",
                        reason=str(exc),
                    )
                )
            except IntegrityError:
                results.append(
                    CustomerSyncResult(
                        client_customer_id=str(customer_input.id),
                        status="duplicate",
                    )
                )

    return CustomerSyncBatchResponse(results=results)


async def _create_customer_internal(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    customer_input: CustomerSyncInput,
) -> Customer:
    now = datetime.now(UTC)
    is_time_suspect = detect_time_drift(customer_input.joined_at, now)

    customer = Customer(
        id=customer_input.id,
        business_id=business_id,
        name=customer_input.name,
        phone=customer_input.phone,
        email=customer_input.email,
        address_line1=customer_input.address_line1,
        actor_id=actor_id,
        joined_at=customer_input.joined_at,
        device_sequence=customer_input.device_sequence,
        is_time_suspect=is_time_suspect,
    )
    session.add(customer)
    await session.flush()
    return customer


async def update_customer(
    session: AsyncSession,
    business_id: UUID,
    customer_id: UUID,
    actor_id: UUID | None,
    patch: CustomerUpdate,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> Customer:
    customer = (
        await session.exec(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.business_id == business_id,
            )
        )
    ).first()
    if customer is None:
        raise CustomerNotFoundError(
            f"Customer {customer_id} not found for business {business_id}"
        )
    if customer.is_deleted:
        raise CustomerStateError(f"Customer {customer_id} has been deleted")

    update_data = patch.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(customer, field, value)

    session.add(customer)
    await session.flush()

    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:customer-update:{customer.id}",
            "business_id": str(business_id),
            "action": "customer.updated",
            "customer_id": str(customer.id),
            "actor_id": str(actor_id) if actor_id else None,
        },
    )

    await session.commit()
    # `updated_at` is server-computed (onupdate=func.now()), so SQLAlchemy
    # expires it on commit — refresh here so the caller's later synchronous
    # attribute reads (e.g. Pydantic's model_validate) don't trigger an
    # implicit lazy-load outside the async context (MissingGreenlet).
    await session.refresh(customer)
    return customer


async def soft_delete_customer(
    session: AsyncSession,
    business_id: UUID,
    customer_id: UUID,
    actor_id: UUID | None,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> None:
    customer = (
        await session.exec(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.business_id == business_id,
            )
        )
    ).first()
    if customer is None:
        raise CustomerNotFoundError(
            f"Customer {customer_id} not found for business {business_id}"
        )

    if customer.is_deleted:
        # Idempotent — a repeated DELETE is a no-op, not an error.
        return

    now = datetime.now(UTC)
    customer.is_deleted = True
    customer.deleted_at = now
    customer.deleted_by = actor_id
    session.add(customer)
    await session.flush()

    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:customer-delete:{customer.id}",
            "business_id": str(business_id),
            "action": "customer.deleted",
            "customer_id": str(customer.id),
            "actor_id": str(actor_id) if actor_id else None,
        },
    )

    await session.commit()


# ═══════════════════════════════════════════════════════════════════════
# Aggregates — total_orders / total_spent / last_order_at computed on read
# ═══════════════════════════════════════════════════════════════════════


def _sales_aggregate_subquery(business_id: UUID):
    """One subquery, reused by list and detail, so the two can never
    disagree. Only ``completed`` sales count — a void/refund excludes a
    sale from both the order count and the spend total, self-correcting on
    the very next read with no stored counter to maintain.
    """
    return (
        select(
            Sale.customer_id.label("customer_id"),
            sa_func.count(Sale.id).label("total_orders"),
            sa_func.coalesce(sa_func.sum(Sale.total), 0).label("total_spent"),
            sa_func.max(Sale.occurred_at).label("last_order_at"),
        )
        .where(
            Sale.business_id == business_id,
            Sale.status == SaleStatus.COMPLETED,
            Sale.customer_id.is_not(None),
        )
        .group_by(Sale.customer_id)
        .subquery()
    )


def _row_to_list_item(row) -> CustomerListItem:
    customer: Customer = row[0]
    return CustomerListItem(
        id=customer.id,
        business_id=customer.business_id,
        name=customer.name,
        phone=customer.phone,
        email=customer.email,
        address_line1=customer.address_line1,
        actor_id=customer.actor_id,
        joined_at=customer.joined_at,
        synced_at=customer.synced_at,
        device_sequence=customer.device_sequence,
        is_time_suspect=customer.is_time_suspect,
        updated_at=customer.updated_at,
        is_deleted=customer.is_deleted,
        created_at=customer.created_at,
        total_orders=row.total_orders,
        total_spent=row.total_spent,
        last_order_at=row.last_order_at,
    )


async def list_customers_with_totals(
    session: AsyncSession,
    business_id: UUID,
    *,
    limit: int,
    offset: int,
    search: str | None = None,
    include_deleted: bool = False,
) -> tuple[list[CustomerListItem], int]:
    sales_agg = _sales_aggregate_subquery(business_id)

    where_clauses = [Customer.business_id == business_id]
    if not include_deleted:
        where_clauses.append(Customer.is_deleted.is_(False))  # type: ignore[attr-defined]
    if search:
        pattern = f"%{search}%"
        where_clauses.append(
            sa_or(Customer.name.ilike(pattern), Customer.phone.ilike(pattern))
        )

    base_stmt = (
        select(
            Customer,
            sa_func.coalesce(sales_agg.c.total_orders, 0).label("total_orders"),
            sa_func.coalesce(sales_agg.c.total_spent, 0).label("total_spent"),
            sales_agg.c.last_order_at,
        )
        .outerjoin(sales_agg, sales_agg.c.customer_id == Customer.id)
        .where(*where_clauses)
    )

    count_stmt = select(sa_func.count()).select_from(
        select(Customer.id).where(*where_clauses).subquery()
    )
    total = (await session.exec(count_stmt)).one()

    stmt = (
        base_stmt.order_by(Customer.name.asc()).offset(offset).limit(limit)
    )
    rows = (await session.exec(stmt)).all()

    return [_row_to_list_item(row) for row in rows], total


async def get_customer_with_totals(
    session: AsyncSession,
    business_id: UUID,
    customer_id: UUID,
) -> CustomerListItem | None:
    sales_agg = _sales_aggregate_subquery(business_id)

    stmt = (
        select(
            Customer,
            sa_func.coalesce(sales_agg.c.total_orders, 0).label("total_orders"),
            sa_func.coalesce(sales_agg.c.total_spent, 0).label("total_spent"),
            sales_agg.c.last_order_at,
        )
        .outerjoin(sales_agg, sales_agg.c.customer_id == Customer.id)
        .where(Customer.id == customer_id, Customer.business_id == business_id)
    )
    row = (await session.exec(stmt)).first()
    if row is None:
        return None
    return _row_to_list_item(row)
