"""Sales API endpoints — sync, read, and lookup."""

from __future__ import annotations

from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.db.session import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.pos import Sale, SaleLineItem
from app.schemas.line_items import SaleLineItemRead
from app.schemas.sales import (
    SaleRead,
    SaleSyncBatchRequest,
    SaleSyncBatchResponse,
)
from app.services.sale_service import sync_sale_batch

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["sales"])


@router.post(
    "/businesses/{business_id}/sales/sync",
    response_model=SaleSyncBatchResponse,
    status_code=status.HTTP_200_OK,
)
async def sync_sales(
    business_id: UUID,
    batch: SaleSyncBatchRequest,
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    _active_business: str = Depends(require_business_permission(PermissionCode.POS_WRITE)),
) -> SaleSyncBatchResponse:
    """Process a batch of offline-synced sales.

    Returns per-sale results (created / duplicate / failed) with HTTP 200.
    Partial success is first-class — one sale failure does NOT cause an
    HTTP error.
    """
    try:
        actor_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        actor_id = None
    response = await sync_sale_batch(session, business_id, actor_id, batch)

    created = sum(1 for r in response.results if r.status == "created")
    duplicate = sum(1 for r in response.results if r.status == "duplicate")
    failed = sum(1 for r in response.results if r.status == "failed")

    logger.info(
        "sales_sync_batch_processed",
        business_id=str(business_id),
        batch_size=len(batch.sales),
        created=created,
        duplicate=duplicate,
        failed=failed,
    )

    return response


@router.get(
    "/businesses/{business_id}/sales/{sale_id}",
    response_model=SaleRead,
)
async def get_sale(
    business_id: UUID,
    sale_id: UUID,
    session: AsyncSession = Depends(get_db),
    _active_business: str = Depends(require_business_permission(PermissionCode.POS_VIEW)),
) -> SaleRead:
    """Retrieve a single sale by server-assigned ID."""
    sale = (
        await session.exec(
            select(Sale).where(Sale.id == sale_id, Sale.business_id == business_id)
        )
    ).first()
    if sale is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale not found",
        )

    line_items = (
        await session.exec(
            select(SaleLineItem).where(SaleLineItem.sale_id == sale_id)
        )
    ).all()

    return _sale_to_read(sale, list(line_items))


@router.get(
    "/businesses/{business_id}/sales/by-client-id/{client_sale_id}",
    response_model=SaleRead,
)
async def get_sale_by_client_id(
    business_id: UUID,
    client_sale_id: str,
    session: AsyncSession = Depends(get_db),
    _active_business: str = Depends(require_business_permission(PermissionCode.POS_VIEW)),
) -> SaleRead:
    """Retrieve a single sale by client-generated idempotency key."""
    sale = (
        await session.exec(
            select(Sale).where(
                Sale.client_sale_id == client_sale_id,
                Sale.business_id == business_id,
            )
        )
    ).first()
    if sale is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale not found",
        )

    line_items = (
        await session.exec(
            select(SaleLineItem).where(SaleLineItem.sale_id == sale.id)
        )
    ).all()

    return _sale_to_read(sale, list(line_items))


def _sale_to_read(sale: Sale, line_items: list[SaleLineItem]) -> SaleRead:
    return SaleRead(
        id=sale.id,
        business_id=sale.business_id,
        business_location_id=sale.business_location_id,
        client_sale_id=sale.client_sale_id,
        status=sale.status.value,
        subtotal=sale.subtotal,
        discount_amount=sale.discount_amount,
        tax_amount=sale.tax_amount,
        total=sale.total,
        payment_method=sale.payment_method.value,
        actor_id=sale.actor_id,
        occurred_at=sale.occurred_at,
        synced_at=sale.synced_at,
        device_sequence=sale.device_sequence,
        is_time_suspect=sale.is_time_suspect,
        voided_at=sale.voided_at,
        refunded_at=sale.refunded_at,
        void_or_refund_reason=sale.void_or_refund_reason,
        created_at=sale.created_at,
        line_items=[
            SaleLineItemRead(
                id=li.id,
                sale_id=li.sale_id,
                item_id=li.item_id,
                quantity=li.quantity,
                unit_price=li.unit_price,
                discount_amount=li.discount_amount,
                line_total=li.line_total,
            )
            for li in line_items
        ],
    )
