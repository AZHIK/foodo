"""Supplier management endpoints — CRUD, soft-delete only.

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   POST   /businesses/{business_id}/suppliers  → SUPPLIERS_CREATE         │
│   GET    /businesses/{business_id}/suppliers  → SUPPLIERS_VIEW           │
│   GET    /businesses/{business_id}/suppliers/{supplier_id} → SUPPLIERS_VIEW │
│   PATCH  /businesses/{business_id}/suppliers/{supplier_id} → SUPPLIERS_UPDATE │
│   DELETE /businesses/{business_id}/suppliers/{supplier_id} → SUPPLIERS_DELETE │
└──────────────────────────────────────────────────────────────────────────┘

Mirrors ``items.py``'s shape — plain CRUD directly in the endpoint layer,
same as this service's convention (a dedicated ``*_service.py`` file is
reserved for genuinely shared/transactional logic like
``stock_movement_service.py``, not simple single-table CRUD).
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated, Any
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel.sql.expression import SelectOfScalar

from app.core.database import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.suppliers import Supplier
from app.schemas.suppliers import (
    SupplierCreate,
    SupplierListFilters,
    SupplierListResponse,
    SupplierRead,
    SupplierUpdate,
)

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/businesses/{business_id}/suppliers", tags=["suppliers"])


def _extract_actor_id(claims: dict[str, Any]) -> UUID | None:
    raw = claims.get("sub")
    if not raw:
        return None
    try:
        return UUID(raw)
    except ValueError:
        return None


async def _get_supplier_or_404(
    business_id: UUID,
    supplier_id: UUID,
    session: AsyncSession,
) -> Supplier:
    stmt = select(Supplier).where(
        Supplier.id == supplier_id, Supplier.business_id == business_id
    )
    result = await session.exec(stmt)
    supplier = result.one_or_none()
    if supplier is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Supplier not found")
    return supplier


def _build_list_query(business_id: UUID, filters: SupplierListFilters) -> SelectOfScalar[Supplier]:
    stmt = select(Supplier).where(Supplier.business_id == business_id)
    if not filters.include_deleted:
        stmt = stmt.where(Supplier.is_deleted == False)  # noqa: E712
    if filters.search:
        pattern = f"%{filters.search}%"
        stmt = stmt.where(or_(Supplier.name.ilike(pattern), Supplier.phone.ilike(pattern)))
    return stmt.order_by(Supplier.name)


@router.post("", response_model=SupplierRead, status_code=status.HTTP_201_CREATED)
async def create_supplier(
    business_id: UUID,
    body: SupplierCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("suppliers.create"))],
) -> Supplier:
    supplier = Supplier(business_id=business_id, **body.model_dump())
    session.add(supplier)
    await session.commit()
    await session.refresh(supplier)

    logger.info("supplier.created", supplier_id=str(supplier.id), business_id=str(business_id))
    return supplier


@router.get("", response_model=SupplierListResponse)
async def list_suppliers(
    business_id: UUID,
    filters: Annotated[SupplierListFilters, Depends()],
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("suppliers.view"))],
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> SupplierListResponse:
    base_stmt = _build_list_query(business_id, filters)

    count_result = await session.exec(base_stmt)
    total = len(count_result.all())

    stmt = base_stmt.offset(offset).limit(limit)
    result = await session.exec(stmt)
    items = list(result.all())

    return SupplierListResponse(items=items, total=total, limit=limit, offset=offset)


@router.patch("/{supplier_id}", response_model=SupplierRead)
async def update_supplier(
    business_id: UUID,
    supplier_id: UUID,
    body: SupplierUpdate,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("suppliers.update"))],
) -> Supplier:
    supplier = await _get_supplier_or_404(business_id, supplier_id, session)
    update_data = body.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update",
        )

    for field, value in update_data.items():
        setattr(supplier, field, value)

    session.add(supplier)
    await session.commit()
    await session.refresh(supplier)

    logger.info(
        "supplier.updated",
        supplier_id=str(supplier.id),
        business_id=str(business_id),
        updated_fields=list(update_data.keys()),
    )
    return supplier


@router.delete("/{supplier_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_supplier(
    business_id: UUID,
    supplier_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("suppliers.delete"))],
) -> None:
    """Soft-delete a supplier. Past reorders keep their attribution — see
    ``app/models/suppliers.py``'s module docstring."""
    supplier = await _get_supplier_or_404(business_id, supplier_id, session)

    supplier.is_deleted = True
    supplier.deleted_at = datetime.now(UTC)
    supplier.deleted_by = _extract_actor_id(claims)

    session.add(supplier)
    await session.commit()

    logger.info("supplier.deleted", supplier_id=str(supplier.id), business_id=str(business_id))


@router.get("/{supplier_id}", response_model=SupplierRead)
async def get_supplier(
    business_id: UUID,
    supplier_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("suppliers.view"))],
) -> Supplier:
    """Declared last so the literal ``""`` list route above is never
    swallowed by this ``{supplier_id}`` matcher (same discipline as
    ``customers.py`` in pos-service, defensive even with no real collision
    risk today)."""
    return await _get_supplier_or_404(business_id, supplier_id, session)
