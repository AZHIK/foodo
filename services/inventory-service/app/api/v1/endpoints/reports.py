"""Read-only reporting endpoints — stock levels and movement history.

Every endpoint requires ``INVENTORY_VIEW`` permission and returns
paginated results via the standard limit/offset convention.

═══════════════════════════════════════════════════════════════════════════
STAGE 3 OPEN QUESTION — denormalized item fields in StockLevelRead
═══════════════════════════════════════════════════════════════════════════

The original schema had only ``item_name`` and ``item_unit_of_measure``.
This stage adds ``item_category``, ``item_reorder_threshold``, and
``item_type`` so that the Business App can render a complete stock-level
card without a second round-trip per item.

The join is implemented here (the endpoint layer) rather than in a service
function because the endpoint is read-only — it doesn't need transactional
wrapping, and keeping the join visible at the API boundary makes it easy
to optimise later (e.g. add ``business_location_name`` when cross-service
lookups land).

═══════════════════════════════════════════════════════════════════════════
BELOW_THRESHOLD FILTER — shared logic, same predicate
═══════════════════════════════════════════════════════════════════════════

Stage 4's item-list endpoint uses ``StockLevel.current_quantity <=
Item.reorder_threshold`` inside a LEFT JOIN.  This endpoint uses the
**exact same predicate** — the difference is the base entity (StockLevel
here, Item in Stage 4).  Both code paths produce the same result for the
same data.  No duplication — the predicate is a one-line WHERE clause that
cannot meaningfully be extracted into a shared helper.
"""

from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Annotated
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import require_business_permission
from app.models.inventory import Item, MovementType, StockLevel, StockMovement
from app.schemas.movements import StockMovementRead
from app.schemas.stock_levels import StockLevelRead

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/businesses/{business_id}", tags=["reports"])


# ═══════════════════════════════════════════════════════════════════════
# Stock-level filters
# ═══════════════════════════════════════════════════════════════════════


class StockLevelFilters(BaseModel):
    business_location_id: UUID | None = None
    category: str | None = None
    below_threshold: bool | None = None


# ═══════════════════════════════════════════════════════════════════════
# GET /businesses/{business_id}/stock
# ═══════════════════════════════════════════════════════════════════════


@router.get("/stock", response_model=list[StockLevelRead])
async def get_stock_levels(
    business_id: UUID,
    filters: Annotated[StockLevelFilters, Depends()],
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.view"))],
    limit: int = Query(default=20, ge=1, le=100, description="Max items per page"),
    offset: int = Query(default=0, ge=0, description="Number of items to skip"),
    sort_by: str = Query(
        default="name",
        description="Sort field — name, current_quantity, or category",
    ),
) -> list[StockLevelRead]:
    """Current stock levels for the business, one row per item/location.

    Item details (name, unit_of_measure, category, reorder_threshold,
    item_type) are joined in so callers don't need a second round-trip
    per item.
    """
    if sort_by not in ("name", "current_quantity", "category"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid sort_by '{sort_by}' — must be name, current_quantity, or category",
        )

    # Join StockLevel → Item so we can filter/sort on item columns and
    # return denormalized item details — this is the single query that
    # resolves the Stage 3 open question.
    stmt = (
        select(StockLevel, Item)
        .join(Item, StockLevel.item_id == Item.id)
        .where(Item.business_id == business_id)
    )

    if filters.business_location_id is not None:
        stmt = stmt.where(StockLevel.business_location_id == filters.business_location_id)
    if filters.category is not None:
        stmt = stmt.where(Item.category == filters.category)
    if filters.below_threshold:
        stmt = stmt.where(StockLevel.current_quantity <= Item.reorder_threshold)

    sort_map = {
        "name": Item.name,
        "current_quantity": StockLevel.current_quantity,
        "category": Item.category,
    }
    stmt = stmt.order_by(sort_map[sort_by].asc().nullslast())
    stmt = stmt.offset(offset).limit(limit)

    result = await session.exec(stmt)
    rows = result.all()

    levels: list[StockLevelRead] = [
        StockLevelRead(
            item_id=sl.item_id,
            business_location_id=sl.business_location_id,
            current_quantity=sl.current_quantity,
            updated_at=sl.updated_at,
            item_name=item.name,
            item_unit_of_measure=item.unit_of_measure,
            item_category=item.category,
            item_reorder_threshold=item.reorder_threshold,
            item_type=item.item_type,
        )
        for sl, item in rows
    ]

    logger.info(
        "reports.stock_levels",
        business_id=str(business_id),
        count=len(levels),
        filters=filters.model_dump(exclude_none=True),
    )
    return levels


# ═══════════════════════════════════════════════════════════════════════
# GET /businesses/{business_id}/items/{item_id}/movements
# ═══════════════════════════════════════════════════════════════════════


@router.get("/items/{item_id}/movements", response_model=list[StockMovementRead])
async def get_item_movements(
    business_id: UUID,
    item_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("inventory.view"))],
    limit: int = Query(default=20, ge=1, le=100, description="Max items per page"),
    offset: int = Query(default=0, ge=0, description="Number of items to skip"),
    from_date: date | None = Query(default=None, alias="from", description="Start date (inclusive)"),
    to_date: date | None = Query(default=None, alias="to", description="End date (inclusive)"),
    movement_type: MovementType | None = Query(default=None, description="Filter by movement type"),
    business_location_id: UUID | None = Query(default=None, description="Filter by location"),
) -> list[StockMovementRead]:
    """Paginated movement history for one item, most recent first."""
    result = await session.exec(
        select(Item).where(Item.id == item_id, Item.business_id == business_id)
    )
    if result.one_or_none() is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")

    stmt = (
        select(StockMovement)
        .where(
            StockMovement.business_id == business_id,
            StockMovement.item_id == item_id,
        )
    )

    if from_date is not None:
        dt = datetime.combine(from_date, datetime.min.time(), tzinfo=timezone.utc)
        stmt = stmt.where(StockMovement.created_at >= dt)
    if to_date is not None:
        dt = datetime.combine(to_date, datetime.max.time(), tzinfo=timezone.utc)
        stmt = stmt.where(StockMovement.created_at <= dt)
    if movement_type is not None:
        stmt = stmt.where(StockMovement.movement_type == movement_type)
    if business_location_id is not None:
        stmt = stmt.where(StockMovement.business_location_id == business_location_id)

    stmt = stmt.order_by(StockMovement.created_at.desc())
    stmt = stmt.offset(offset).limit(limit)

    result = await session.exec(stmt)
    movements = list(result.all())

    logger.info(
        "reports.item_movements",
        business_id=str(business_id),
        item_id=str(item_id),
        count=len(movements),
    )
    return movements
