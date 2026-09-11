"""Category listing endpoint — read-only, global (not business-scoped).

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   GET  /categories  → INVENTORY_VIEW                                    │
└──────────────────────────────────────────────────────────────────────────┘

Categories are a single platform-wide taxonomy shared by every business
(see ``app/models/categories.py``), not a per-business resource, so unlike
``suppliers.py``/``items.py`` this router has no ``{business_id}`` prefix
and uses ``require_permission`` rather than ``require_business_permission``.
Write endpoints (create/update/deactivate) are not part of this stage —
categories are managed via the seed migration for now.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_db
from app.deps.auth import require_permission
from app.models.categories import Category
from app.schemas.categories import CategoryRead

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryRead])
async def list_categories(
    session: Annotated[AsyncSession, Depends(get_db)],
    _claims: Annotated[dict, Depends(require_permission("inventory.view"))],
    include_inactive: bool = Query(default=False),
) -> list[Category]:
    stmt = select(Category)
    if not include_inactive:
        stmt = stmt.where(Category.is_active == True)  # noqa: E712
    stmt = stmt.order_by(Category.sort_order, Category.name)
    result = await session.exec(stmt)
    return list(result.all())
