"""Item management endpoints — full CRUD, soft-delete only.

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   POST   /businesses/{business_id}/items  → INVENTORY_ADJUST             │
│   GET    /businesses/{business_id}/items  → INVENTORY_VIEW               │
│   GET    /businesses/{business_id}/items/{item_id} → INVENTORY_VIEW      │
│   PATCH  /businesses/{business_id}/items/{item_id} → INVENTORY_ADJUST    │
│   DELETE /businesses/{business_id}/items/{item_id} → INVENTORY_ADJUST    │
│                                                                          │
│ Note: there is currently no INVENTORY_CREATE / INVENTORY_UPDATE /        │
│ INVENTORY_DELETE split in PermissionCode.  The existing coarse-grained   │
│ INVENTORY_ADJUST covers all mutation operations.  If finer-grained       │
│ control is needed later (e.g. a cashier can adjust stock but not create  │
│ new items), add dedicated codes to Identity Service and narrow the deps. │
└──────────────────────────────────────────────────────────────────────────┘
"""

from __future__ import annotations

from typing import Annotated
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel.sql.expression import SelectOfScalar

from app.core.database import get_db
from app.deps.auth import require_business_permission
from app.models.inventory import Item, StockLevel
from app.schemas.items import ItemCreate, ItemListFilters, ItemRead, ItemUpdate

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/businesses/{business_id}/items", tags=["items"])


def _verify_biz_match(path_biz_id: UUID, jwt_biz_id: str) -> None:
    """Validate the path ``business_id`` matches the JWT's ``active_business_id``."""
    if str(path_biz_id) != jwt_biz_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Business ID in path does not match authenticated business context",
        )


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


async def _build_list_query(
    business_id: UUID,
    filters: ItemListFilters,
) -> SelectOfScalar[Item]:
    stmt = select(Item).where(Item.business_id == business_id)

    if filters.category is not None:
        stmt = stmt.where(Item.category == filters.category)
    if filters.is_active is not None:
        stmt = stmt.where(Item.is_active == filters.is_active)
    if filters.business_location_id is not None:
        stmt = stmt.where(Item.business_location_id == filters.business_location_id)
    if filters.below_threshold:
        stmt = (
            select(Item)
            .join(StockLevel, StockLevel.item_id == Item.id, isouter=True)
            .where(
                Item.business_id == business_id,
                StockLevel.current_quantity <= Item.reorder_threshold,
            )
        )
        if filters.business_location_id is not None:
            stmt = stmt.where(StockLevel.business_location_id == filters.business_location_id)

    stmt = stmt.order_by(Item.created_at.desc())
    return stmt


@router.post("", response_model=ItemRead, status_code=status.HTTP_201_CREATED)
async def create_item(
    business_id: UUID,
    body: ItemCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.adjust"))],
) -> Item:
    """Create a new item for the business.

    ═══════════════════════════════════════════════════════════════════
    CROSS-SERVICE VALIDATION GAP (deferred)
    ═══════════════════════════════════════════════════════════════════

    ``business_location_id`` is accepted as-given without verifying that
    the location actually belongs to ``business_id``.  Ideally this
    endpoint would call Identity Service's ``GET /business-locations/:id``
    (or equivalent) to confirm the location is valid for this business,
    but that cross-service call is out of scope for this stage.

    For now we trust the caller (who is already authenticated and
    authorized via JWT).  A follow-up should add a gRPC or HTTP call to
    Identity Service to validate the location before persisting.
    """
    _verify_biz_match(business_id, _jwt_biz_id)

    item = Item(
        business_id=business_id,
        business_location_id=body.business_location_id,
        name=body.name,
        unit_of_measure=body.unit_of_measure,
        category=body.category,
        reorder_threshold=body.reorder_threshold,
        reorder_quantity=body.reorder_quantity,
        allow_negative_stock=body.allow_negative_stock,
        item_type=body.item_type,
    )
    session.add(item)
    await session.commit()
    await session.refresh(item)

    logger.info(
        "item.created",
        item_id=str(item.id),
        business_id=str(business_id),
        business_location_id=str(body.business_location_id),
        name=item.name,
        item_type=str(item.item_type),
    )
    return item


@router.get("", response_model=list[ItemRead])
async def list_items(
    business_id: UUID,
    filters: Annotated[ItemListFilters, Depends()],
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.view"))],
    limit: int = Query(default=20, ge=1, le=100, description="Max items per page"),
    offset: int = Query(default=0, ge=0, description="Number of items to skip"),
) -> list[Item]:
    """List items for the business with filtering and pagination.

    Pagination is simple limit/offset, consistent with Identity Service's
    admin CRUD convention.  ``below_threshold=true`` joins against
    ``stock_levels`` and returns only items whose ``current_quantity``
    is at or below their ``reorder_threshold``.
    """
    _verify_biz_match(business_id, _jwt_biz_id)

    stmt = await _build_list_query(business_id, filters)
    stmt = stmt.offset(offset).limit(limit)
    result = await session.exec(stmt)
    return list(result.all())


@router.get("/{item_id}", response_model=ItemRead)
async def get_item(
    business_id: UUID,
    item_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.view"))],
) -> Item:
    """Get a single item by ID.

    Returns the item even if ``is_active`` is False.  Deactivation is a
    status field, not an existence flag — downstream operations (e.g.
    historical movement lookups) need to reference deactivated items.
    """
    _verify_biz_match(business_id, _jwt_biz_id)
    return await _get_item_or_404(business_id, item_id, session)


@router.patch("/{item_id}", response_model=ItemRead)
async def update_item(
    business_id: UUID,
    item_id: UUID,
    body: ItemUpdate,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.adjust"))],
) -> Item:
    """Update an item's mutable fields.

    ``business_id`` and ``business_location_id`` cannot be changed via
    this endpoint (``ItemUpdate`` excludes them by design).  Relocating
    an item is a transfer operation handled in a later stage.
    """
    _verify_biz_match(business_id, _jwt_biz_id)

    item = await _get_item_or_404(business_id, item_id, session)
    update_data = body.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update",
        )

    for field, value in update_data.items():
        setattr(item, field, value)

    session.add(item)
    await session.commit()
    await session.refresh(item)

    logger.info(
        "item.updated",
        item_id=str(item.id),
        business_id=str(business_id),
        updated_fields=list(update_data.keys()),
    )
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def deactivate_item(
    business_id: UUID,
    item_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.adjust"))],
) -> None:
    """Soft-deactivate an item (sets ``is_active=False``).

    ┌─────────────────────────────────────────────────────────────────────┐
    │ SOFT DELETE POLICY                                                   │
    │                                                                      │
    │ • This is a soft deactivation only — the row is NOT removed.         │
    │ • Deactivating an item with nonzero stock levels IS allowed.         │
    │   "Deactivation" means "stop transacting this item," not             │
    │   "this item must have zero stock."  Those are separate concerns.   │
    │ • Historical stock_movements referencing this item are preserved.    │
    │                                                                      │
    │ This matches Identity Service's admin user deactivation pattern.     │
    └─────────────────────────────────────────────────────────────────────┘
    """
    _verify_biz_match(business_id, _jwt_biz_id)

    item = await _get_item_or_404(business_id, item_id, session)
    if not item.is_active:
        logger.warning(
            "item.deactivate_skipped",
            item_id=str(item.id),
            business_id=str(business_id),
            reason="already inactive",
        )
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Item is already inactive",
        )

    item.is_active = False
    session.add(item)
    await session.commit()

    logger.info(
        "item.deactivated",
        item_id=str(item.id),
        business_id=str(business_id),
    )