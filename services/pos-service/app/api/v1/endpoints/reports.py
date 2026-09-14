"""Aggregated reporting endpoints — daily takings, item mix, staff
performance, and finance summary.

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   All four endpoints → REPORTS_VIEW (the code the app's Reports nav      │
│   gates on). The older `GET /sales/summary` keeps its POS_VIEW gate —    │
│   it predates this surface and stays untouched.                          │
│                                                                          │
│ Business-context binding is enforced at the shared dependency level      │
│ (``require_business_permission``), not per-endpoint.                     │
│                                                                          │
│ Every query is a single SQL aggregation (no Python-side rollups),        │
│ business-scoped first, so one business can never see another's           │
│ numbers. Read-only: no endpoint here writes.                             │
└──────────────────────────────────────────────────────────────────────────┘
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Annotated
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, Query
from sqlalchemy import case as sa_case
from sqlalchemy import func as sa_func
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.db.session import get_db
from app.deps.auth import require_business_permission
from app.models.finance import OtherExpense, OtherIncome
from app.models.pos import Sale, SaleLineItem, SaleStatus
from app.schemas.reports import (
    DailyTakingsDay,
    DailyTakingsResponse,
    FinanceCategoryTotal,
    FinanceSummaryResponse,
    ItemMixLine,
    ItemMixResponse,
    StaffPerformanceLine,
    StaffPerformanceResponse,
)

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["reports"])


def _sale_filters(
    business_id: UUID,
    from_date: datetime | None,
    to_date: datetime | None,
    store_id: UUID | None,
) -> list:
    """Shared WHERE clauses: business scope plus the optional window."""
    filters = [Sale.business_id == business_id]
    if from_date is not None:
        filters.append(Sale.occurred_at >= from_date)
    if to_date is not None:
        filters.append(Sale.occurred_at <= to_date)
    if store_id is not None:
        filters.append(Sale.store_id == store_id)
    return filters


@router.get("/businesses/{business_id}/reports/daily-takings")
async def daily_takings(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _active_business: str = Depends(require_business_permission(PermissionCode.REPORTS_VIEW)),
    from_date: datetime | None = Query(default=None, description="Start (inclusive) for occurred_at"),
    to_date: datetime | None = Query(default=None, description="End (inclusive) for occurred_at"),
    store_id: UUID | None = Query(default=None, description="Filter by store"),
) -> DailyTakingsResponse:
    """Per-day revenue, ticket count, average ticket, and void/refund counts.

    Days bucket by UTC date of ``occurred_at``. Days with no sales simply
    do not appear — the client, not this endpoint, decides whether to render
    zero-filled gaps.
    """
    day = sa_func.date(Sale.occurred_at).label("day")
    stmt = (
        select(
            day,
            sa_func.sum(
                sa_case((Sale.status == SaleStatus.COMPLETED, Sale.total), else_=Decimal("0"))
            ).label("revenue"),
            sa_func.count(Sale.id).label("sales_count"),
            sa_func.sum(sa_case((Sale.status == SaleStatus.VOIDED, 1), else_=0)).label("voided_count"),
            sa_func.sum(sa_case((Sale.status == SaleStatus.REFUNDED, 1), else_=0)).label("refunded_count"),
        )
        .where(*_sale_filters(business_id, from_date, to_date, store_id))
        .group_by(day)
        .order_by(day)
    )
    rows = (await session.exec(stmt)).all()

    days = [
        DailyTakingsDay(
            date=row.day,
            revenue=row.revenue or Decimal("0"),
            sales_count=row.sales_count,
            avg_ticket=(row.revenue / row.sales_count)
            if row.sales_count and row.revenue
            else Decimal("0"),
            voided_count=row.voided_count or 0,
            refunded_count=row.refunded_count or 0,
        )
        for row in rows
    ]
    logger.info("reports.daily_takings", business_id=str(business_id), days=len(days))
    return DailyTakingsResponse(days=days)


@router.get("/businesses/{business_id}/reports/item-mix")
async def item_mix(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _active_business: str = Depends(require_business_permission(PermissionCode.REPORTS_VIEW)),
    from_date: datetime | None = Query(default=None, description="Start (inclusive) for occurred_at"),
    to_date: datetime | None = Query(default=None, description="End (inclusive) for occurred_at"),
    store_id: UUID | None = Query(default=None, description="Filter by store"),
    limit: int = Query(default=50, ge=1, le=200, description="Max items, top revenue first"),
) -> ItemMixResponse:
    """What sold, by menu item: quantity, revenue, and line count.

    Completed sales only. Item names are deliberately NOT resolved here —
    ``item_id`` is Inventory Service's key and the app joins its catalog.
    """
    filters = _sale_filters(business_id, from_date, to_date, store_id)
    filters.append(Sale.status == SaleStatus.COMPLETED)
    stmt = (
        select(
            SaleLineItem.item_id,
            sa_func.sum(SaleLineItem.quantity).label("quantity"),
            sa_func.sum(SaleLineItem.line_total).label("revenue"),
            sa_func.count(SaleLineItem.id).label("lines"),
        )
        .join(Sale, SaleLineItem.sale_id == Sale.id)
        .where(*filters)
        .group_by(SaleLineItem.item_id)
        .order_by(sa_func.sum(SaleLineItem.line_total).desc())
        .limit(limit)
    )
    rows = (await session.exec(stmt)).all()

    lines = [
        ItemMixLine(
            item_id=row.item_id,
            quantity=row.quantity or Decimal("0"),
            revenue=row.revenue or Decimal("0"),
            lines=row.lines,
        )
        for row in rows
    ]
    logger.info("reports.item_mix", business_id=str(business_id), lines=len(lines))
    return ItemMixResponse(lines=lines)


@router.get("/businesses/{business_id}/reports/staff-performance")
async def staff_performance(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _active_business: str = Depends(require_business_permission(PermissionCode.REPORTS_VIEW)),
    from_date: datetime | None = Query(default=None, description="Start (inclusive) for occurred_at"),
    to_date: datetime | None = Query(default=None, description="End (inclusive) for occurred_at"),
    store_id: UUID | None = Query(default=None, description="Filter by store"),
) -> StaffPerformanceResponse:
    """Per-actor sales: count, revenue, and void/refund counts.

    SQL groups NULL ``actor_id``s into one row, which surfaces as the
    explicit unknown bucket rather than vanishing from the report.
    """
    stmt = (
        select(
            Sale.actor_id,
            sa_func.count(Sale.id).label("sales_count"),
            sa_func.sum(
                sa_case((Sale.status == SaleStatus.COMPLETED, Sale.total), else_=Decimal("0"))
            ).label("revenue"),
            sa_func.sum(sa_case((Sale.status == SaleStatus.VOIDED, 1), else_=0)).label("voided_count"),
            sa_func.sum(sa_case((Sale.status == SaleStatus.REFUNDED, 1), else_=0)).label("refunded_count"),
        )
        .where(*_sale_filters(business_id, from_date, to_date, store_id))
        .group_by(Sale.actor_id)
        .order_by(sa_func.sum(
            sa_case((Sale.status == SaleStatus.COMPLETED, Sale.total), else_=Decimal("0"))
        ).desc())
    )
    rows = (await session.exec(stmt)).all()

    lines = [
        StaffPerformanceLine(
            actor_id=row.actor_id,
            sales_count=row.sales_count,
            revenue=row.revenue or Decimal("0"),
            voided_count=row.voided_count or 0,
            refunded_count=row.refunded_count or 0,
        )
        for row in rows
    ]
    logger.info("reports.staff_performance", business_id=str(business_id), lines=len(lines))
    return StaffPerformanceResponse(lines=lines)


def _finance_filters(model, business_id: UUID, from_date, to_date, store_id) -> list:
    """Shared clauses for finance tables: scope, window, live rows only."""
    filters = [
        model.business_id == business_id,
        model.is_deleted == False,  # noqa: E712
    ]
    if from_date is not None:
        filters.append(model.occurred_at >= from_date)
    if to_date is not None:
        filters.append(model.occurred_at <= to_date)
    if store_id is not None:
        filters.append(model.store_id == store_id)
    return filters


@router.get("/businesses/{business_id}/reports/finance-summary")
async def finance_summary(
    business_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _active_business: str = Depends(require_business_permission(PermissionCode.REPORTS_VIEW)),
    from_date: datetime | None = Query(default=None, description="Start (inclusive) for occurred_at"),
    to_date: datetime | None = Query(default=None, description="End (inclusive) for occurred_at"),
    store_id: UUID | None = Query(default=None, description="Filter by store"),
) -> FinanceSummaryResponse:
    """Money in vs money out: completed sales revenue, ad-hoc incomes and
    expenses by category, and the net. Deleted finance entries are excluded.
    """
    revenue_row = (
        await session.exec(
            select(
                sa_func.sum(
                    sa_case((Sale.status == SaleStatus.COMPLETED, Sale.total), else_=Decimal("0"))
                )
            ).where(*_sale_filters(business_id, from_date, to_date, store_id))
        )
    ).one()
    sales_revenue = revenue_row or Decimal("0")

    async def _category_totals(model) -> list[FinanceCategoryTotal]:
        rows = (
            await session.exec(
                select(model.category, sa_func.sum(model.amount))
                .where(*_finance_filters(model, business_id, from_date, to_date, store_id))
                .group_by(model.category)
                .order_by(sa_func.sum(model.amount).desc())
            )
        ).all()
        return [
            FinanceCategoryTotal(category=row[0], total=row[1] or Decimal("0"))
            for row in rows
        ]

    expenses = await _category_totals(OtherExpense)
    incomes = await _category_totals(OtherIncome)
    expense_total = sum((line.total for line in expenses), Decimal("0"))
    income_total = sum((line.total for line in incomes), Decimal("0"))

    response = FinanceSummaryResponse(
        sales_revenue=sales_revenue,
        income_total=income_total,
        expense_total=expense_total,
        net=sales_revenue + income_total - expense_total,
        expenses_by_category=expenses,
        incomes_by_category=incomes,
    )
    logger.info(
        "reports.finance_summary",
        business_id=str(business_id),
        net=str(response.net),
    )
    return response
