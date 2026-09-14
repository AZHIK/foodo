"""Production endpoints — record runs and read history (Stage 2).

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   POST /businesses/{id}/recipes/{rid}/produce       → PRODUCTION_CREATE  │
│   GET  /businesses/{id}/production-events           → PRODUCTION_VIEW    │
│   GET  /businesses/{id}/production-events/{eid}     → PRODUCTION_VIEW    │
│                                                                          │
│ Business-context binding is enforced at the shared dependency level      │
│ (``require_business_permission``), not per-endpoint.                     │
│                                                                          │
│ Error mapping for the service's domain errors: not-found → 404,          │
│ malformed input → 422, any-ingredient shortfall → 409 with the whole     │
│ event rejected (``record_production_event`` writes nothing before its    │
│ sufficiency check, so a 409 always means zero side effects).             │
└──────────────────────────────────────────────────────────────────────────┘
"""

from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Annotated, Any
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.inventory import (
    Item,
    ProductionEvent,
    ProductionEventComponent,
    Recipe,
)
from app.models.units import Unit
from app.schemas.production import (
    ProduceRequest,
    ProductionComponentRead,
    ProductionEventRead,
)
from app.services.production_service import (
    InsufficientStockError,
    InvalidProductionInputError,
    RecipeNotFoundError,
    record_production_event,
)

logger = structlog.get_logger(__name__)

produce_router = APIRouter(
    prefix="/businesses/{business_id}/recipes/{recipe_id}", tags=["production"]
)
history_router = APIRouter(
    prefix="/businesses/{business_id}/production-events", tags=["production"]
)


async def _read_events(
    events: list[ProductionEvent],
    session: AsyncSession,
) -> list[ProductionEventRead]:
    """Build full read payloads with resolved names/units in bulk.

    One constant-size query pass (components → recipes/items → units) no
    matter how many events are listed — the same no-N+1 discipline as the
    recipes endpoint's reader.
    """
    if not events:
        return []

    event_ids = [e.id for e in events]
    comp_result = await session.exec(
        select(ProductionEventComponent).where(
            ProductionEventComponent.production_event_id.in_(event_ids)
        )
    )
    components = list(comp_result.all())

    recipe_ids = {e.recipe_id for e in events}
    recipe_result = await session.exec(
        select(Recipe).where(Recipe.id.in_(list(recipe_ids)))
    )
    recipes = {r.id: r for r in recipe_result.all()}

    item_ids = {e.leading_component_item_id for e in events} | {
        c.raw_material_item_id for c in components
    } | {r.sellable_item_id for r in recipes.values()}
    item_result = await session.exec(select(Item).where(Item.id.in_(list(item_ids))))
    items = {item.id: item for item in item_result.all()}

    unit_ids = {item.unit_id for item in items.values() if item.unit_id is not None}
    units: dict[UUID, str] = {}
    if unit_ids:
        unit_result = await session.exec(
            select(Unit).where(Unit.id.in_(list(unit_ids)))
        )
        units = {unit.id: unit.code for unit in unit_result.all()}

    comps_by_event: dict[UUID, list[ProductionComponentRead]] = {
        e.id: [] for e in events
    }
    for comp in components:
        raw = items[comp.raw_material_item_id]
        comps_by_event[comp.production_event_id].append(
            ProductionComponentRead(
                id=comp.id,
                production_event_id=comp.production_event_id,
                raw_material_item_id=comp.raw_material_item_id,
                raw_material_name=raw.name,
                raw_material_unit=units.get(raw.unit_id) if raw.unit_id else "",
                quantity_consumed=comp.quantity_consumed,
            )
        )

    reads = []
    for e in events:
        recipe = recipes[e.recipe_id]
        sellable = items[recipe.sellable_item_id]
        reads.append(
            ProductionEventRead(
                id=e.id,
                business_id=e.business_id,
                store_id=e.store_id,
                recipe_id=e.recipe_id,
                recipe_name=recipe.name,
                sellable_item_id=recipe.sellable_item_id,
                sellable_item_name=sellable.name,
                leading_component_item_id=e.leading_component_item_id,
                leading_quantity_used=e.leading_quantity_used,
                suggested_output_quantity=e.suggested_output_quantity,
                actual_output_quantity=e.actual_output_quantity,
                actor_id=e.actor_id,
                occurred_at=e.occurred_at,
                created_at=e.created_at,
                components=comps_by_event[e.id],
            )
        )
    return reads


@produce_router.post(
    "/produce", response_model=ProductionEventRead, status_code=status.HTTP_201_CREATED
)
async def produce(
    business_id: UUID,
    recipe_id: UUID,
    body: ProduceRequest,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("production.create"))],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
) -> ProductionEventRead:
    """Record a production run: consume by ratio, stock the confirmed output.

    ``actual_output_quantity`` may be omitted — the server then commits the
    computed suggestion (plan-met portions, the common case).
    """
    raw_sub = claims.get("sub")
    try:
        actor_id = UUID(raw_sub) if raw_sub else None
    except ValueError:
        actor_id = None

    try:
        event = await record_production_event(
            db=session,
            business_id=business_id,
            recipe_id=recipe_id,
            leading_item_id=body.leading_item_id,
            leading_quantity_used=body.leading_quantity_used,
            actual_output_quantity=body.actual_output_quantity,
            actor_id=actor_id,
        )
    except RecipeNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)
        ) from exc
    except InvalidProductionInputError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)
        ) from exc
    except InsufficientStockError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail=str(exc)
        ) from exc

    logger.info(
        "production.endpoint_recorded",
        event_id=str(event.id),
        business_id=str(business_id),
        recipe_id=str(recipe_id),
    )
    return (await _read_events([event], session))[0]


@history_router.get("", response_model=list[ProductionEventRead])
async def list_production_events(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("production.view"))],
    from_date: date | None = Query(
        default=None, alias="from", description="Start date (inclusive)"
    ),
    to_date: date | None = Query(
        default=None, alias="to", description="End date (inclusive)"
    ),
    limit: int = Query(default=20, ge=1, le=100, description="Max events per page"),
    offset: int = Query(default=0, ge=0, description="Number of events to skip"),
) -> list[ProductionEventRead]:
    """Production history for the business, newest first, filterable by date."""
    stmt = select(ProductionEvent).where(
        ProductionEvent.business_id == business_id
    )
    if from_date is not None:
        dt = datetime.combine(from_date, datetime.min.time(), tzinfo=timezone.utc)
        stmt = stmt.where(ProductionEvent.occurred_at >= dt)
    if to_date is not None:
        dt = datetime.combine(to_date, datetime.max.time(), tzinfo=timezone.utc)
        stmt = stmt.where(ProductionEvent.occurred_at <= dt)

    stmt = stmt.order_by(ProductionEvent.occurred_at.desc()).offset(offset).limit(limit)
    result = await session.exec(stmt)
    events = list(result.all())

    logger.info(
        "production.listed", business_id=str(business_id), count=len(events)
    )
    return await _read_events(events, session)


@history_router.get("/{event_id}", response_model=ProductionEventRead)
async def get_production_event(
    business_id: UUID,
    event_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("production.view"))],
) -> ProductionEventRead:
    """Full detail for one production event."""
    result = await session.exec(
        select(ProductionEvent).where(
            ProductionEvent.id == event_id,
            ProductionEvent.business_id == business_id,
        )
    )
    event = result.one_or_none()
    if event is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Production event not found",
        )
    return (await _read_events([event], session))[0]
