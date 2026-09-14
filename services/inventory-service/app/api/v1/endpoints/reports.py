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
to optimise later (e.g. add ``store_name`` when cross-service
lookups land).

``item_category`` is now sourced from a further ``Category`` join on
``Item.category_id`` (see ``app/models/categories.py``) rather than a raw
string column — the denormalization rationale above still holds, only the
source changed. ``item_unit_of_measure`` went through the same change:
it's now ``Unit.code`` from a further ``Unit`` join on ``Item.unit_id``
(see ``app/models/units.py``) rather than a Postgres enum column — an
unresolved (``NULL`` FK) unit reads as ``""`` rather than ``None`` since
the field's type predates this change and is still a plain ``str``.

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
from decimal import Decimal
from typing import Annotated
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func as sa_func
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import require_business_permission
from app.models.categories import Category
from app.models.inventory import (
    Item,
    MovementType,
    ProductionEvent,
    ProductionEventComponent,
    StockLevel,
    StockMovement,
)
from app.models.units import Unit
from app.schemas.analytics import (
    IngredientConsumption,
    ProductionSummaryResponse,
    StockValuationLine,
    StockValuationResponse,
    WasteLine,
    WasteSummaryResponse,
)
from app.schemas.movements import StockMovementRead
from app.schemas.stock_levels import StockLevelRead

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/businesses/{business_id}", tags=["reports"])


# ═══════════════════════════════════════════════════════════════════════
# Stock-level filters
# ═══════════════════════════════════════════════════════════════════════


class StockLevelFilters(BaseModel):
    store_id: UUID | None = None
    category_id: UUID | None = None
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
    """Current stock levels for the business, one row per item/store.

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
    # resolves the Stage 3 open question. Category and Unit are further
    # outer joins (item.category_id / item.unit_id are both nullable) so
    # item_category / item_unit_of_measure can be resolved to human-readable
    # strings without a second round-trip per row.
    stmt = (
        select(StockLevel, Item, Category, Unit)
        .join(Item, StockLevel.item_id == Item.id)
        .join(Category, Item.category_id == Category.id, isouter=True)
        .join(Unit, Item.unit_id == Unit.id, isouter=True)
        .where(Item.business_id == business_id)
    )

    if filters.store_id is not None:
        stmt = stmt.where(StockLevel.store_id == filters.store_id)
    if filters.category_id is not None:
        stmt = stmt.where(Item.category_id == filters.category_id)
    if filters.below_threshold:
        stmt = stmt.where(StockLevel.current_quantity <= Item.reorder_threshold)

    sort_map = {
        "name": Item.name,
        "current_quantity": StockLevel.current_quantity,
        "category": Category.name,
    }
    stmt = stmt.order_by(sort_map[sort_by].asc().nullslast())
    stmt = stmt.offset(offset).limit(limit)

    result = await session.exec(stmt)
    rows = result.all()

    levels: list[StockLevelRead] = [
        StockLevelRead(
            item_id=sl.item_id,
            store_id=sl.store_id,
            current_quantity=sl.current_quantity,
            updated_at=sl.updated_at,
            item_name=item.name,
            item_unit_of_measure=unit.code if unit else "",
            item_category=category.name if category else None,
            item_reorder_threshold=item.reorder_threshold,
            item_type=item.item_type,
        )
        for sl, item, category, unit in rows
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
    store_id: UUID | None = Query(default=None, description="Filter by store"),
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
    if store_id is not None:
        stmt = stmt.where(StockMovement.store_id == store_id)

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


# ═══════════════════════════════════════════════════════════════════════
# Analytics (waste / production / valuation) — REPORTS_VIEW
#
# These three are newer than the stock/movement reads above, so they gate
# on the dedicated REPORTS_VIEW code (the one the app's Reports nav
# checks) rather than the older INVENTORY_VIEW the reads above predate.
# ═══════════════════════════════════════════════════════════════════════


def _day_bounds(
    from_date: date | None, to_date: date | None
) -> tuple[datetime | None, datetime | None]:
    """Inclusive UTC day bounds, mirroring the movement-history filters."""
    start = (
        datetime.combine(from_date, datetime.min.time(), tzinfo=timezone.utc)
        if from_date is not None
        else None
    )
    end = (
        datetime.combine(to_date, datetime.max.time(), tzinfo=timezone.utc)
        if to_date is not None
        else None
    )
    return start, end


@router.get("/waste-summary", response_model=WasteSummaryResponse)
async def waste_summary(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("reports.view"))],
    from_date: date | None = Query(default=None, alias="from", description="Start date (inclusive)"),
    to_date: date | None = Query(default=None, alias="to", description="End date (inclusive)"),
    store_id: UUID | None = Query(default=None, description="Filter by store"),
) -> WasteSummaryResponse:
    """Waste recorded in the window, per item, with cost.

    Waste movements store negative deltas, so quantities are negated back
    to positive "wasted" amounts. Cost multiplies by the item's current
    ``unit_cost`` — an item with no cost basis contributes quantity but zero
    cost, rather than being dropped from the report.
    """
    start, end = _day_bounds(from_date, to_date)

    stmt = (
        select(
            StockMovement.item_id,
            Item.name,
            Unit.code,
            Item.unit_cost,
            sa_func.sum(-StockMovement.quantity_delta).label("quantity"),
        )
        .join(Item, StockMovement.item_id == Item.id)
        .join(Unit, Item.unit_id == Unit.id, isouter=True)
        .where(
            StockMovement.business_id == business_id,
            StockMovement.movement_type == MovementType.WASTE,
        )
    )
    if start is not None:
        stmt = stmt.where(StockMovement.created_at >= start)
    if end is not None:
        stmt = stmt.where(StockMovement.created_at <= end)
    if store_id is not None:
        stmt = stmt.where(StockMovement.store_id == store_id)
    stmt = stmt.group_by(
        StockMovement.item_id, Item.name, Unit.code, Item.unit_cost
    ).order_by(sa_func.sum(-StockMovement.quantity_delta).desc())

    rows = (await session.exec(stmt)).all()

    lines = [
        WasteLine(
            item_id=row.item_id,
            item_name=row.name,
            item_unit=row.code or "",
            quantity_wasted=row.quantity or Decimal("0"),
            cost_wasted=(row.quantity or Decimal("0"))
            * (row.unit_cost or Decimal("0")),
        )
        for row in rows
    ]
    total = sum((line.cost_wasted for line in lines), Decimal("0"))

    logger.info(
        "reports.waste_summary", business_id=str(business_id), lines=len(lines)
    )
    return WasteSummaryResponse(lines=lines, total_cost_wasted=total)


@router.get("/production-summary", response_model=ProductionSummaryResponse)
async def production_summary(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("reports.view"))],
    from_date: date | None = Query(default=None, alias="from", description="Start date (inclusive)"),
    to_date: date | None = Query(default=None, alias="to", description="End date (inclusive)"),
    store_id: UUID | None = Query(default=None, description="Filter by store"),
) -> ProductionSummaryResponse:
    """Production runs in the window: counts, suggested-vs-actual totals,
    and per-ingredient consumption.

    ``over_portioned_by`` is actual minus suggested — positive means the
    kitchen stocked more than recipes called for. Same gap the per-event
    payloads carry, summed for the window.
    """
    start, end = _day_bounds(from_date, to_date)

    base = [ProductionEvent.business_id == business_id]
    if start is not None:
        base.append(ProductionEvent.occurred_at >= start)
    if end is not None:
        base.append(ProductionEvent.occurred_at <= end)
    if store_id is not None:
        base.append(ProductionEvent.store_id == store_id)

    agg = (
        await session.exec(
            select(
                sa_func.count(ProductionEvent.id),
                sa_func.sum(ProductionEvent.suggested_output_quantity),
                sa_func.sum(ProductionEvent.actual_output_quantity),
            ).where(*base)
        )
    ).one()
    runs = agg[0] or 0
    suggested = agg[1] or Decimal("0")
    actual = agg[2] or Decimal("0")

    comp_stmt = (
        select(
            ProductionEventComponent.raw_material_item_id,
            Item.name,
            Unit.code,
            sa_func.sum(ProductionEventComponent.quantity_consumed).label(
                "quantity"
            ),
        )
        .join(
            ProductionEvent,
            ProductionEventComponent.production_event_id == ProductionEvent.id,
        )
        .join(Item, ProductionEventComponent.raw_material_item_id == Item.id)
        .join(Unit, Item.unit_id == Unit.id, isouter=True)
        .where(*base)
        .group_by(
            ProductionEventComponent.raw_material_item_id, Item.name, Unit.code
        )
        .order_by(sa_func.sum(ProductionEventComponent.quantity_consumed).desc())
    )
    comp_rows = (await session.exec(comp_stmt)).all()

    logger.info(
        "reports.production_summary", business_id=str(business_id), runs=runs
    )
    return ProductionSummaryResponse(
        runs=runs,
        suggested_total=suggested,
        actual_total=actual,
        over_portioned_by=actual - suggested,
        ingredients_consumed=[
            IngredientConsumption(
                raw_material_item_id=row.raw_material_item_id,
                raw_material_name=row.name,
                raw_material_unit=row.code or "",
                quantity_consumed=row.quantity or Decimal("0"),
            )
            for row in comp_rows
        ],
    )


@router.get("/stock-valuation", response_model=StockValuationResponse)
async def stock_valuation(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("reports.view"))],
    store_id: UUID | None = Query(default=None, description="Filter by store"),
) -> StockValuationResponse:
    """Current inventory value (on-hand × unit cost), total and by category.

    A point-in-time snapshot, not a windowed report — stock levels only know
    the present. Items without a cost basis contribute quantity but zero
    value rather than vanishing from the total.
    """
    stmt = (
        select(
            Category.name,
            sa_func.count(StockLevel.item_id).label("items"),
            sa_func.sum(
                StockLevel.current_quantity
                * sa_func.coalesce(Item.unit_cost, Decimal("0"))
            ).label("value"),
        )
        .join(Item, StockLevel.item_id == Item.id)
        .join(Category, Item.category_id == Category.id, isouter=True)
        .where(Item.business_id == business_id)
    )
    if store_id is not None:
        stmt = stmt.where(StockLevel.store_id == store_id)
    stmt = stmt.group_by(Category.name).order_by(
        sa_func.sum(
            StockLevel.current_quantity
            * sa_func.coalesce(Item.unit_cost, Decimal("0"))
        ).desc()
    )

    rows = (await session.exec(stmt)).all()
    lines = [
        StockValuationLine(
            category=row[0],
            item_count=row[1],
            total_value=row[2] or Decimal("0"),
        )
        for row in rows
    ]
    total = sum((line.total_value for line in lines), Decimal("0"))

    logger.info(
        "reports.stock_valuation", business_id=str(business_id), total=str(total)
    )
    return StockValuationResponse(total_value=total, lines=lines)
