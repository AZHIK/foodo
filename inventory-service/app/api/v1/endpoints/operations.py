"""Manual operation endpoints — adjust, waste, and transfer stock.

Every endpoint calls ``record_movement()`` (Stage 5) and returns the
resulting ``StockMovementRead``.

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   POST  /businesses/{business_id}/items/{item_id}/adjust   → ADJUST     │
│   POST  /businesses/{business_id}/items/{item_id}/waste    → ADJUST     │
│   POST  /businesses/{business_id}/items/{item_id}/transfer → ADJUST     │
│                                                                          │
│ All three use the same coarse-grained INVENTORY_ADJUST permission.       │
│ If finer-grained control is needed later, split into                   │
│ INVENTORY_ADJUST / INVENTORY_WASTE / INVENTORY_TRANSFER.                 │
└──────────────────────────────────────────────────────────────────────────┘
"""

from __future__ import annotations

from decimal import Decimal
from typing import Annotated, Any
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.inventory import ActorType, Item, MovementType
from app.schemas.movements import StockMovementRead
from app.schemas.operations import AdjustStockRequest, RecordWasteRequest, TransferStockRequest
from app.services.stock_movement_service import (
    InsufficientStockError,
    ItemTypeMismatchError,
    record_movement,
)

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/businesses/{business_id}/items/{item_id}", tags=["operations"])


def _verify_biz_match(path_biz_id: UUID, jwt_biz_id: str) -> None:
    if str(path_biz_id) != jwt_biz_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Business ID in path does not match authenticated business context",
        )


def _extract_actor_id(claims: dict[str, Any]) -> UUID | None:
    raw = claims.get("sub")
    if not raw:
        return None
    try:
        return UUID(raw)
    except ValueError:
        return None


async def _get_item_or_404(
    business_id: UUID,
    item_id: UUID,
    session: AsyncSession,
) -> Item:
    stmt = select(Item).where(Item.id == item_id, Item.business_id == business_id)
    result = await session.exec(stmt)
    item = result.one_or_none()
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    return item


async def _call_movement(
    db: AsyncSession,
    business_id: UUID,
    business_location_id: UUID,
    item_id: UUID,
    quantity_delta: Decimal,
    movement_type: MovementType,
    claims: dict[str, Any],
    reason: str | None = None,
    commit: bool = True,
) -> Any:
    """Thin wrapper: calls ``record_movement`` and maps domain exceptions to HTTP."""
    actor_id = _extract_actor_id(claims)

    try:
        return await record_movement(
            db=db,
            item_id=item_id,
            business_id=business_id,
            business_location_id=business_location_id,
            quantity_delta=quantity_delta,
            movement_type=movement_type,
            actor_type=ActorType.USER.value,
            actor_id=actor_id,
            reason=reason,
            commit=commit,
        )
    except ItemTypeMismatchError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc
    except InsufficientStockError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc


@router.post("/adjust", response_model=StockMovementRead, status_code=status.HTTP_201_CREATED)
async def adjust_stock(
    business_id: UUID,
    item_id: UUID,
    body: AdjustStockRequest,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.adjust"))],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
) -> Any:
    """Manually adjust stock for an item by a positive or negative delta."""
    _verify_biz_match(business_id, _jwt_biz_id)
    item = await _get_item_or_404(business_id, item_id, session)

    movement = await _call_movement(
        db=session,
        business_id=business_id,
        business_location_id=item.business_location_id,
        item_id=item_id,
        quantity_delta=body.quantity_delta,
        movement_type=MovementType.MANUAL_ADJUSTMENT,
        claims=claims,
        reason=body.reason,
    )

    logger.info(
        "operation.adjust",
        item_id=str(item_id),
        business_id=str(business_id),
        delta=str(body.quantity_delta),
        reason=body.reason,
    )
    return movement


@router.post("/waste", response_model=StockMovementRead, status_code=status.HTTP_201_CREATED)
async def record_waste(
    business_id: UUID,
    item_id: UUID,
    body: RecordWasteRequest,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.adjust"))],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
) -> Any:
    """Record wasted/spoiled stock (quantity is a positive number, negated internally)."""
    _verify_biz_match(business_id, _jwt_biz_id)
    item = await _get_item_or_404(business_id, item_id, session)

    movement = await _call_movement(
        db=session,
        business_id=business_id,
        business_location_id=item.business_location_id,
        item_id=item_id,
        quantity_delta=-body.quantity,
        movement_type=MovementType.WASTE,
        claims=claims,
        reason=body.reason,
    )

    logger.info(
        "operation.waste",
        item_id=str(item_id),
        business_id=str(business_id),
        quantity=str(body.quantity),
        reason=body.reason,
    )
    return movement


@router.post("/transfer", response_model=StockMovementRead, status_code=status.HTTP_201_CREATED)
async def transfer_stock(
    business_id: UUID,
    item_id: UUID,
    body: TransferStockRequest,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.adjust"))],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
) -> Any:
    """Transfer stock from one location to another within the same business.

    Both movements (TRANSFER_OUT at source, TRANSFER_IN at destination)
    happen in a single transaction so that a failure in either leg rolls
    back both.
    """
    _verify_biz_match(business_id, _jwt_biz_id)

    if body.item_id != item_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Item ID in path must match item_id in request body",
        )

    try:
        actor_id = _extract_actor_id(claims)
        movement_out = await record_movement(
            db=session,
            item_id=item_id,
            business_id=business_id,
            business_location_id=body.source_location_id,
            quantity_delta=-body.quantity,
            movement_type=MovementType.TRANSFER_OUT,
            actor_type=ActorType.USER.value,
            actor_id=actor_id,
            reason=f"Transfer to location {body.destination_location_id}",
            commit=False,
        )
        movement_in = await record_movement(
            db=session,
            item_id=item_id,
            business_id=business_id,
            business_location_id=body.destination_location_id,
            quantity_delta=body.quantity,
            movement_type=MovementType.TRANSFER_IN,
            actor_type=ActorType.USER.value,
            actor_id=actor_id,
            reason=f"Transfer from location {body.source_location_id}",
            commit=False,
        )
        await session.commit()
        await session.refresh(movement_out)
        await session.refresh(movement_in)
    except (ItemTypeMismatchError, InsufficientStockError) as exc:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc

    logger.info(
        "operation.transfer",
        item_id=str(item_id),
        business_id=str(business_id),
        quantity=str(body.quantity),
        source=str(body.source_location_id),
        destination=str(body.destination_location_id),
    )

    return movement_out