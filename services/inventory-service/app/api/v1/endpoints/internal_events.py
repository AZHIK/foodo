"""Internal stock-events endpoint — service-to-service only, not for end users.

POS Service calls this synchronously (see
``services/pos-service/app/core/events.py``'s ``publish_event``) instead of
publishing to a message broker — no broker exists in this repo yet, and the
handler functions below are already written and tested. This endpoint is
just an HTTP-shaped call site for them.

Each line item is dispatched to the handler **individually** (rather than
letting the handler process the whole batch in one call) so that one bad
line item — most commonly a menu item whose linked inventory item was
deleted after the sale was rung up but before it synced — can't abort stock
deduction for the rest of a multi-item sale. ``event_handlers._process_line_items``
itself has no such per-item isolation, so it lives here instead of being
added to that shared, already-tested function.
"""

from __future__ import annotations

from typing import Annotated

import structlog
from fastapi import APIRouter, Depends
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import require_internal_service_token
from app.schemas.internal_events import (
    LineItemResult,
    StockEventRequest,
    StockEventResponse,
)
from app.services.event_handlers import (
    handle_sale_completed,
    handle_sale_refunded,
    handle_sale_voided,
)
from app.services.stock_movement_service import InsufficientStockError, ItemTypeMismatchError

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/internal/businesses/{business_id}", tags=["internal-events"])

_HANDLERS = {
    "sale.completed": handle_sale_completed,
    "sale.voided": handle_sale_voided,
    "sale.refunded": handle_sale_refunded,
}


@router.post("/stock-events", response_model=StockEventResponse)
async def receive_stock_event(
    business_id: str,
    body: StockEventRequest,
    session: Annotated[AsyncSession, Depends(get_db)],
    _service: Annotated[None, Depends(require_internal_service_token)],
) -> StockEventResponse:
    """Apply one sale-related stock event, one line item at a time.

    Returns HTTP 200 with a per-line-item result even when some (or all)
    lines fail or are skipped — the caller (POS Service) treats this whole
    call as best-effort and never fails a sale sync on its account, so
    there is no value in a non-2xx status here beyond auth/validation
    errors, which FastAPI/pydantic already handle before this body runs.
    """
    handler = _HANDLERS[body.event_type]
    results: list[LineItemResult] = []

    for line_item in body.line_items:
        single_item_payload = {
            "event_id": body.event_id,
            "business_id": business_id,
            "store_id": str(body.store_id),
            "sale_id": str(body.sale_id),
            "line_items": [
                {"item_id": str(line_item.item_id), "quantity": str(line_item.quantity)}
            ],
        }
        try:
            await handler(session, single_item_payload)
            results.append(LineItemResult(item_id=line_item.item_id, status="applied"))
        except (ItemTypeMismatchError, InsufficientStockError) as exc:
            results.append(
                LineItemResult(item_id=line_item.item_id, status="failed", reason=str(exc))
            )
        except ValueError as exc:
            # record_movement raises a plain ValueError (not one of the two
            # subclasses above) when the item id doesn't exist — an
            # unlinked/deleted catalog item, not a hard failure.
            results.append(
                LineItemResult(item_id=line_item.item_id, status="skipped", reason=str(exc))
            )
        except Exception as exc:  # noqa: BLE001 — must never 500 on POS Service
            await session.rollback()
            logger.exception(
                "internal_stock_event_line_item_failed",
                event_type=body.event_type,
                event_id=body.event_id,
                item_id=str(line_item.item_id),
            )
            results.append(
                LineItemResult(item_id=line_item.item_id, status="failed", reason=str(exc))
            )

    logger.info(
        "internal_stock_event_processed",
        event_type=body.event_type,
        event_id=body.event_id,
        business_id=business_id,
        applied=sum(1 for r in results if r.status == "applied"),
        skipped=sum(1 for r in results if r.status == "skipped"),
        failed=sum(1 for r in results if r.status == "failed"),
    )

    return StockEventResponse(results=results)
