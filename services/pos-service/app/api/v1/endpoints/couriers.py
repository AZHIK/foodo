"""Couriers API endpoints — CRUD plus delivery-status transitions.

Route declaration order matters: ``GET /{courier_id}`` is declared LAST so
a literal path segment is never accidentally matched as a UUID by FastAPI's
route-matching (mirrors the ordering discipline in ``customers.py``).
"""

from __future__ import annotations

from typing import Annotated
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.api.v1.endpoints.sales import _sale_to_read
from app.core.permission_codes import PermissionCode
from app.db.session import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.pos import DeliveryStatus, SaleLineItem
from app.schemas.couriers import (
    CourierCreate,
    CourierListResponse,
    CourierRead,
    CourierUpdate,
)
from app.schemas.sales import DeliveryStatusUpdate, SaleRead
from app.services.courier_service import (
    CourierConflictError,
    CourierNotFoundError,
    create_courier,
    delete_courier,
    get_courier,
    list_couriers,
    update_courier,
)
from app.services.sale_service import SaleValidationError, update_delivery_status

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["couriers"])


def _courier_to_read(courier) -> CourierRead:
    return CourierRead(
        id=courier.id,
        business_id=courier.business_id,
        name=courier.name,
        phone=courier.phone,
        vehicle=courier.vehicle,
        is_active=courier.is_active,
        actor_id=courier.actor_id,
        created_at=courier.created_at,
        updated_at=courier.updated_at,
    )


@router.post(
    "/businesses/{business_id}/couriers",
    response_model=CourierRead,
    status_code=status.HTTP_201_CREATED,
)
async def post_courier(
    business_id: UUID,
    payload: CourierCreate,
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    _active_business: str = Depends(require_business_permission(PermissionCode.COURIERS_CREATE)),
) -> CourierRead:
    """Create a courier within the business."""
    try:
        actor_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        actor_id = None
    try:
        courier = await create_courier(session, business_id, actor_id, payload)
    except CourierConflictError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    logger.info("courier_created", business_id=str(business_id), courier_id=str(courier.id))
    return _courier_to_read(courier)


@router.get(
    "/businesses/{business_id}/couriers",
    response_model=CourierListResponse,
)
async def get_couriers(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _active_business: str = Depends(require_business_permission(PermissionCode.COURIERS_VIEW)),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    search: str | None = Query(default=None, description="Matches name or phone"),
    active_only: bool = Query(default=False, description="Only active couriers"),
) -> CourierListResponse:
    """Paginated courier list, optionally searched by name/phone."""
    return await list_couriers(
        session,
        business_id,
        limit=limit,
        offset=offset,
        search=search,
        active_only=active_only,
    )


@router.patch(
    "/businesses/{business_id}/couriers/{courier_id}",
    response_model=CourierRead,
)
async def patch_courier(
    business_id: UUID,
    courier_id: UUID,
    patch: CourierUpdate,
    session: AsyncSession = Depends(get_db),
    _active_business: str = Depends(require_business_permission(PermissionCode.COURIERS_UPDATE)),
) -> CourierRead:
    """Partial update to a courier."""
    try:
        courier = await update_courier(session, business_id, courier_id, patch)
    except CourierNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except CourierConflictError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    return _courier_to_read(courier)


@router.delete(
    "/businesses/{business_id}/couriers/{courier_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_courier(
    business_id: UUID,
    courier_id: UUID,
    session: AsyncSession = Depends(get_db),
    _active_business: str = Depends(require_business_permission(PermissionCode.COURIERS_DELETE)),
) -> None:
    """Delete a courier; linked sales keep their rows with courier_id=NULL."""
    try:
        await delete_courier(session, business_id, courier_id)
    except CourierNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc


@router.patch(
    "/businesses/{business_id}/sales/{sale_id}/delivery-status",
    response_model=SaleRead,
)
async def patch_delivery_status(
    business_id: UUID,
    sale_id: UUID,
    patch: DeliveryStatusUpdate,
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    _active_business: str = Depends(require_business_permission(PermissionCode.POS_WRITE)),
) -> SaleRead:
    """Advance a delivery sale's fulfilment state.

    Linear transitions only: pending → assigned → out_for_delivery →
    delivered (``failed`` reachable from any non-terminal step). Moving to
    ``assigned`` requires a courier (existing or supplied in the body).
    """
    try:
        actor_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        actor_id = None
    try:
        sale = await update_delivery_status(
            session,
            business_id,
            sale_id,
            actor_id,
            DeliveryStatus(patch.delivery_status),
            courier_id=patch.courier_id,
        )
    except SaleValidationError as exc:
        message = str(exc)
        if "not found" in message:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message) from exc
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=message) from exc

    line_items = (
        await session.exec(select(SaleLineItem).where(SaleLineItem.sale_id == sale.id))
    ).all()
    return _sale_to_read(sale, list(line_items))


@router.get(
    "/businesses/{business_id}/couriers/{courier_id}",
    response_model=CourierRead,
)
async def get_courier_detail(
    business_id: UUID,
    courier_id: UUID,
    session: AsyncSession = Depends(get_db),
    _active_business: str = Depends(require_business_permission(PermissionCode.COURIERS_VIEW)),
) -> CourierRead:
    """Retrieve a single courier by ID."""
    try:
        courier = await get_courier(session, business_id, courier_id)
    except CourierNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return _courier_to_read(courier)
