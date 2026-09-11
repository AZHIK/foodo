"""Unit listing endpoint — read-only, global (not business-scoped).

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   GET  /units  → INVENTORY_VIEW                                         │
└──────────────────────────────────────────────────────────────────────────┘

Units are a single platform-wide taxonomy shared by every business (see
``app/models/units.py``), not a per-business resource, so — mirroring
``categories.py`` — this router has no ``{business_id}`` prefix and uses
``require_permission`` rather than ``require_business_permission``. Write
endpoints (create/update/deactivate) are not part of this stage — units are
managed via the seed script for now.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import require_permission
from app.models.units import Unit
from app.schemas.units import UnitRead

router = APIRouter(prefix="/units", tags=["units"])


@router.get("", response_model=list[UnitRead])
async def list_units(
    session: Annotated[AsyncSession, Depends(get_db)],
    _claims: Annotated[dict, Depends(require_permission("inventory.view"))],
    include_inactive: bool = Query(default=False),
) -> list[Unit]:
    stmt = select(Unit)
    if not include_inactive:
        stmt = stmt.where(Unit.is_active == True)  # noqa: E712
    stmt = stmt.order_by(Unit.sort_order, Unit.name)
    result = await session.exec(stmt)
    return list(result.all())
