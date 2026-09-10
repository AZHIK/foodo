"""Customers API endpoints — sync, list, mutations, detail.

Route declaration order matters: ``GET /{customer_id}`` is declared LAST so
a literal path segment is never accidentally matched as a UUID by FastAPI's
route-matching (mirrors the ordering discipline in ``other_expenses.py``,
even though no literal sub-path like `/summary` exists here today).
"""

from __future__ import annotations

from typing import Annotated
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.db.session import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.schemas.customers import (
    CustomerListResponse,
    CustomerRead,
    CustomerSyncBatchRequest,
    CustomerSyncBatchResponse,
    CustomerUpdate,
)
from app.services.customer_service import (
    CustomerNotFoundError,
    CustomerStateError,
    get_customer_with_totals,
    list_customers_with_totals,
    soft_delete_customer,
    sync_customer_batch,
    update_customer,
)

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["customers"])


@router.post(
    "/businesses/{business_id}/customers/sync",
    response_model=CustomerSyncBatchResponse,
    status_code=status.HTTP_200_OK,
)
async def sync_customers(
    business_id: UUID,
    batch: CustomerSyncBatchRequest,
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    _active_business: str = Depends(
        require_business_permission(PermissionCode.CUSTOMERS_CREATE)
    ),
) -> CustomerSyncBatchResponse:
    """Process a batch of offline-created customers.

    Returns per-customer results (created / duplicate / failed) with HTTP
    200. Partial success is first-class — one customer's failure does NOT
    cause an HTTP error.
    """
    try:
        actor_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        actor_id = None
    response = await sync_customer_batch(session, business_id, actor_id, batch)

    created = sum(1 for r in response.results if r.status == "created")
    duplicate = sum(1 for r in response.results if r.status == "duplicate")
    failed = sum(1 for r in response.results if r.status == "failed")

    logger.info(
        "customer_sync_batch_processed",
        business_id=str(business_id),
        batch_size=len(batch.customers),
        created=created,
        duplicate=duplicate,
        failed=failed,
    )

    return response


@router.get(
    "/businesses/{business_id}/customers",
    response_model=CustomerListResponse,
)
async def list_customers(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _active_business: str = Depends(require_business_permission(PermissionCode.CUSTOMERS_VIEW)),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    search: str | None = Query(default=None, description="Matches name or phone"),
    include_deleted: bool = Query(default=False, description="Include soft-deleted customers"),
) -> CustomerListResponse:
    """Paginated customer list, optionally searched by name/phone.

    Each item carries server-computed ``total_orders``/``total_spent``/
    ``last_order_at``, aggregated from completed sales — see
    ``app/services/customer_service.py``.

    ``include_deleted`` defaults to False for the app's normal list view,
    but the sync pull path calls this with ``include_deleted=true`` so a
    delete made on one device propagates to the local cache on others.
    """
    items, total = await list_customers_with_totals(
        session,
        business_id,
        limit=limit,
        offset=offset,
        search=search,
        include_deleted=include_deleted,
    )

    return CustomerListResponse(items=items, total=total, limit=limit, offset=offset)


@router.patch(
    "/businesses/{business_id}/customers/{customer_id}",
    response_model=CustomerRead,
)
async def patch_customer(
    business_id: UUID,
    customer_id: UUID,
    patch: CustomerUpdate,
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    _active_business: str = Depends(
        require_business_permission(PermissionCode.CUSTOMERS_UPDATE)
    ),
) -> CustomerRead:
    try:
        actor_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        actor_id = None
    try:
        await update_customer(session, business_id, customer_id, actor_id, patch)
    except CustomerNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except CustomerStateError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc

    totals = await get_customer_with_totals(session, business_id, customer_id)
    assert totals is not None  # just updated, must exist
    return CustomerRead(**totals.model_dump())


@router.delete(
    "/businesses/{business_id}/customers/{customer_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_customer(
    business_id: UUID,
    customer_id: UUID,
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    _active_business: str = Depends(
        require_business_permission(PermissionCode.CUSTOMERS_DELETE)
    ),
) -> None:
    try:
        actor_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        actor_id = None
    try:
        await soft_delete_customer(session, business_id, customer_id, actor_id)
    except CustomerNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc


@router.get(
    "/businesses/{business_id}/customers/{customer_id}",
    response_model=CustomerRead,
)
async def get_customer(
    business_id: UUID,
    customer_id: UUID,
    session: AsyncSession = Depends(get_db),
    _active_business: str = Depends(require_business_permission(PermissionCode.CUSTOMERS_VIEW)),
) -> CustomerRead:
    totals = await get_customer_with_totals(session, business_id, customer_id)
    if totals is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    return CustomerRead(**totals.model_dump())
