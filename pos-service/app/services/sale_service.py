from __future__ import annotations

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Any, Awaitable, Callable
from uuid import UUID

from sqlalchemy.exc import IntegrityError
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.events import publish_event
from app.core.exceptions import DomainError
from app.models.pos import PaymentMethod, Sale, SaleLineItem, SaleStatus
from app.schemas.line_items import SaleLineItemInput
from app.schemas.sales import (
    SaleSyncBatchRequest,
    SaleSyncBatchResponse,
    SaleSyncInput,
    SyncResult,
)
from app.schemas.void_refund import VoidRefundRequest


class SaleServiceError(DomainError):
    """Base for all sale service errors."""


class SaleValidationError(SaleServiceError):
    """A sale's input data fails business-rule validation."""


class InvalidSaleStateError(SaleServiceError):
    """Raised when attempting to void/refund a sale that is not in 'completed' status."""


def detect_time_drift(
    occurred_at: datetime,
    synced_at: datetime | None = None,
) -> bool:
    """Return True if *occurred_at* is suspicious relative to *synced_at*.

    Compares the device-reported timestamp against the server timestamp.
    A timestamp is considered suspicious (potentially clock-drifted) when:

    * It is more than ``time_drift_suspect_threshold_hours`` in the past, or
    * It is more than ``time_drift_future_tolerance_minutes`` in the future.
    """
    settings = get_settings()
    now = synced_at or datetime.now(UTC)

    if occurred_at < now - timedelta(hours=settings.time_drift_suspect_threshold_hours):
        return True
    if occurred_at > now + timedelta(minutes=settings.time_drift_future_tolerance_minutes):
        return True
    return False


async def sync_sale_batch(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    batch: SaleSyncBatchRequest,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> SaleSyncBatchResponse:
    """Process a batch of offline-synced sales.

    Each sale in the batch is processed independently within its own
    database savepoint.  One sale's failure does **not** abort the rest
    of the batch (partial success is a first-class design property).

    Idempotency is enforced by ``client_sale_id`` — sales whose idempotency
    key already exists in the database are reported as ``duplicate``.
    """
    results: list[SyncResult] = []

    async with session.begin():
        for sale_input in batch.sales:
            try:
                existing = await session.exec(
                    select(Sale).where(Sale.client_sale_id == sale_input.client_sale_id)
                )
                if existing.first() is not None:
                    results.append(
                        SyncResult(
                            client_sale_id=sale_input.client_sale_id,
                            status="duplicate",
                        )
                    )
                    continue

                async with session.begin_nested():
                    sale = await _create_sale_internal(
                        session, business_id, actor_id, sale_input,
                    )

                await _publish_sale_events(sale, sale_input, publish)

                results.append(
                    SyncResult(
                        client_sale_id=sale_input.client_sale_id,
                        status="created",
                    )
                )
            except SaleValidationError as exc:
                results.append(
                    SyncResult(
                        client_sale_id=sale_input.client_sale_id,
                        status="failed",
                        reason=str(exc),
                    )
                )
            except IntegrityError:
                results.append(
                    SyncResult(
                        client_sale_id=sale_input.client_sale_id,
                        status="duplicate",
                    )
                )

    return SaleSyncBatchResponse(results=results)


async def _create_sale_internal(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    sale_input: SaleSyncInput,
) -> Sale:
    if sale_input.status in ("voided", "refunded") and not sale_input.void_or_refund_reason:
        raise SaleValidationError(
            f"void_or_refund_reason is required when status is {sale_input.status}"
        )

    subtotal = sum(
        li.quantity * li.unit_price for li in sale_input.line_items
    )
    settings = get_settings()
    tax_amount = subtotal * settings.default_tax_rate
    total = subtotal - sale_input.discount_amount + tax_amount

    subtotal = subtotal.quantize(Decimal("0.01"))
    tax_amount = tax_amount.quantize(Decimal("0.01"))
    total = total.quantize(Decimal("0.01"))

    now = datetime.now(UTC)
    is_time_suspect = detect_time_drift(sale_input.occurred_at, now)
    status = SaleStatus(sale_input.status)

    sale = Sale(
        business_id=business_id,
        business_location_id=sale_input.business_location_id,
        client_sale_id=sale_input.client_sale_id,
        status=status,
        subtotal=subtotal,
        discount_amount=sale_input.discount_amount.quantize(Decimal("0.01")),
        tax_amount=tax_amount,
        total=total,
        payment_method=PaymentMethod(sale_input.payment_method),
        actor_id=actor_id,
        occurred_at=sale_input.occurred_at,
        device_sequence=sale_input.device_sequence,
        is_time_suspect=is_time_suspect,
    )

    if status == SaleStatus.VOIDED:
        sale.voided_at = sale_input.occurred_at
        sale.void_or_refund_reason = sale_input.void_or_refund_reason
    elif status == SaleStatus.REFUNDED:
        sale.refunded_at = sale_input.occurred_at
        sale.void_or_refund_reason = sale_input.void_or_refund_reason

    session.add(sale)
    await session.flush()

    for li_input in sale_input.line_items:
        line_total = li_input.quantity * li_input.unit_price - li_input.discount_amount
        line_total = line_total.quantize(Decimal("0.01"))
        line_item = SaleLineItem(
            sale_id=sale.id,
            item_id=li_input.item_id,
            quantity=li_input.quantity,
            unit_price=li_input.unit_price.quantize(Decimal("0.01")),
            discount_amount=li_input.discount_amount.quantize(Decimal("0.01")),
            line_total=line_total,
        )
        session.add(line_item)

    await session.flush()
    return sale


async def _publish_sale_events(
    sale: Sale,
    sale_input: SaleSyncInput,
    publish: Callable[..., Awaitable[None]],
) -> None:
    if sale.status == SaleStatus.COMPLETED:
        await publish(
            "sale.completed",
            {
                "event_id": str(sale.id),
                "business_id": str(sale.business_id),
                "business_location_id": str(sale.business_location_id),
                "sale_id": str(sale.id),
                "line_items": [
                    {"item_id": str(li.item_id), "quantity": str(li.quantity)}
                    for li in sale_input.line_items
                ],
            },
        )


async def void_or_refund_sale(
    session: AsyncSession,
    business_id: UUID,
    sale_id: UUID,
    actor_id: UUID | None,
    request: VoidRefundRequest,
    publish: Callable[..., Awaitable[None]] = publish_event,
) -> Sale:
    """Void or refund an already-synced completed sale.

    Publishes ``sale.voided`` / ``sale.refunded`` (for Inventory Service
    stock reversal — **not yet consumed**, see KNOWN_GAP) and
    ``audit.recorded`` (financially significant correction).

    Idempotent via ``client_action_id`` — repeated calls with the same
    action ID load and return the existing sale without side effects.
    """
    # -- Idempotency: client_action_id already processed? ---------------
    existing = (
        await session.exec(
            select(Sale).where(
                (Sale.void_client_action_id == request.client_action_id)
                | (Sale.refund_client_action_id == request.client_action_id)
            )
        )
    ).first()
    if existing is not None:
        return existing

    # -- Load & guard ---------------------------------------------------
    sale = (
        await session.exec(
            select(Sale).where(Sale.id == sale_id, Sale.business_id == business_id)
        )
    ).first()
    if sale is None:
        raise SaleValidationError(
            f"Sale {sale_id} not found for business {business_id}"
        )
    if sale.status != SaleStatus.COMPLETED:
        raise InvalidSaleStateError(
            f"Cannot {request.new_status} sale {sale_id}: "
            f"current status is '{sale.status.value}', expected 'completed'"
        )

    line_items = (
        await session.exec(
            select(SaleLineItem).where(SaleLineItem.sale_id == sale_id)
        )
    ).all()

    # -- Apply transition -----------------------------------------------
    now = datetime.now(UTC)
    new_status = SaleStatus(request.new_status)

    if new_status == SaleStatus.VOIDED:
        sale.status = SaleStatus.VOIDED
        sale.voided_at = now
        sale.void_client_action_id = request.client_action_id
    else:
        sale.status = SaleStatus.REFUNDED
        sale.refunded_at = now
        sale.refund_client_action_id = request.client_action_id

    sale.void_or_refund_reason = request.reason
    session.add(sale)
    await session.flush()

    # -- Publish reversal event -----------------------------------------
    event_name = f"sale.{request.new_status}"
    event_payload = {
        "event_id": request.client_action_id,
        "business_id": str(sale.business_id),
        "business_location_id": str(sale.business_location_id),
        "sale_id": str(sale.id),
            "line_items": [
                {
                    "item_id": str(li.item_id),
                    "quantity": str(li.quantity.normalize()),
                }
                for li in line_items
            ],
    }
    await publish(event_name, event_payload)

    # -- Publish audit event --------------------------------------------
    await publish(
        "audit.recorded",
        {
            "event_id": f"audit:{request.client_action_id}",
            "business_id": str(sale.business_id),
            "action": event_name,
            "sale_id": str(sale.id),
            "actor_id": str(actor_id) if actor_id else None,
            "reason": request.reason,
        },
    )

    await session.commit()
    return sale
