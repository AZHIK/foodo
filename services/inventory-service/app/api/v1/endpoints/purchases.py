"""Purchases endpoints — multi-line POs, partial GRNs, returns, payables.

┌──────────────────────────────────────────────────────────────────────────┐
│ PERMISSION MODEL                                                         │
│                                                                          │
│   POST /orders                                  → PROCUREMENT_CREATE     │
│   GET  /orders  /orders/{id}                   → PROCUREMENT_VIEW       │
│   POST /orders/{id}/submit  /cancel            → PROCUREMENT_CREATE     │
│   POST /orders/{id}/approve                    → PROCUREMENT_APPROVE    │
│   POST /orders/{id}/receive  /returns          → PROCUREMENT_RECEIVE    │
│   POST /invoices  /invoices/{id}/payments      → PROCUREMENT_APPROVE    │
│   GET  /suppliers/{id}/statement               → PROCUREMENT_VIEW       │
└──────────────────────────────────────────────────────────────────────────┘

``receive_order`` is the non-trivial piece: it creates one ``GoodsReceipt``
+ ``GoodsReceiptLine`` rows and loops ``record_movement()`` (the same core
engine ``operations.py``/``reorders.py`` use) with
``movement_type=PURCHASE_RECEIVED`` and ``reference_type="goods_receipt"``,
updates each line's ``quantity_received`` counter and the item's weighted-
average ``unit_cost``, then flips the PO status — ALL in one transaction
(``commit=False`` on every movement call, one ``session.commit()`` at the
end), mirroring ``operations.py``'s ``transfer_stock`` pattern.

Returns deliberately reuse ``MANUAL_ADJUSTMENT`` (with
``reference_type="purchase_return"``) instead of a new movement type: the
audit trail stays queryable by reference, and no native-enum migration is
needed. The PO-scoped guard (``quantity <= received - returned``) is what
makes a return a return, not the movement type.

ONLINE-ONLY: every write is a direct single-transaction API call — there is
no offline outbox for purchases. The Flutter client gates these endpoints
on connectivity (see ``ConnectivityService``), mirroring the existing
supplier/reorder no-outbox convention.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from typing import Annotated, Any
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel.sql.expression import SelectOfScalar

from app.core.database import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.inventory import ActorType, Item, ItemType, MovementType, StockLevel
from app.models.purchases import (
    GoodsReceipt,
    GoodsReceiptLine,
    InvoiceStatus,
    PurchaseOrder,
    PurchaseOrderLine,
    PurchaseOrderStatus,
    PurchaseReturn,
    SupplierInvoice,
    SupplierPayment,
)
from app.models.suppliers import Supplier
from app.models.units import Unit
from app.schemas.purchases import (
    GoodsReceiptCreate,
    GoodsReceiptDetailRead,
    GoodsReceiptLineRead,
    GoodsReceiptRead,
    PurchaseOrderCreate,
    PurchaseOrderDetailRead,
    PurchaseOrderLineRead,
    PurchaseOrderListFilters,
    PurchaseOrderListResponse,
    PurchaseOrderRead,
    PurchaseReturnCreate,
    PurchaseReturnRead,
    SupplierInvoiceCreate,
    SupplierInvoiceRead,
    SupplierPaymentCreate,
    SupplierPaymentRead,
    SupplierStatementRead,
)
from app.services.stock_movement_service import (
    InsufficientStockError,
    ItemTypeMismatchError,
    record_movement,
)

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/businesses/{business_id}/purchases", tags=["purchases"])

_OPEN_ORDER_STATUSES = (
    PurchaseOrderStatus.SUBMITTED,
    PurchaseOrderStatus.APPROVED,
    PurchaseOrderStatus.PARTIALLY_RECEIVED,
)


def _extract_actor_id(claims: dict[str, Any]) -> UUID | None:
    raw = claims.get("sub")
    if not raw:
        return None
    try:
        return UUID(raw)
    except ValueError:
        return None


async def _get_po_or_404(
    business_id: UUID,
    order_id: UUID,
    session: AsyncSession,
) -> PurchaseOrder:
    stmt = select(PurchaseOrder).where(
        PurchaseOrder.id == order_id, PurchaseOrder.business_id == business_id
    )
    po = (await session.exec(stmt)).one_or_none()
    if po is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Purchase order not found"
        )
    return po


async def _get_supplier_or_404(
    business_id: UUID,
    supplier_id: UUID,
    session: AsyncSession,
    *,
    allow_deleted: bool = False,
) -> Supplier:
    stmt = select(Supplier).where(
        Supplier.id == supplier_id, Supplier.business_id == business_id
    )
    if not allow_deleted:
        stmt = stmt.where(Supplier.is_deleted == False)  # noqa: E712
    supplier = (await session.exec(stmt)).one_or_none()
    if supplier is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Supplier not found"
        )
    return supplier


async def _next_number(
    session: AsyncSession,
    model: type[PurchaseOrder] | type[GoodsReceipt],
    business_id: UUID,
    prefix: str,
) -> str:
    """Next ``PREFIX-0001``-style number scoped to the business."""
    count = (
        await session.exec(
            select(func.count())
            .select_from(model)
            .where(model.business_id == business_id)
        )
    ).one()
    return f"{prefix}-{int(count) + 1:04d}"


async def _build_detail(
    po: PurchaseOrder, session: AsyncSession
) -> PurchaseOrderDetailRead:
    lines = (
        await session.exec(
            select(PurchaseOrderLine).where(
                PurchaseOrderLine.purchase_order_id == po.id
            )
        )
    ).all()
    receipts = (
        await session.exec(
            select(GoodsReceipt)
            .where(GoodsReceipt.purchase_order_id == po.id)
            .order_by(GoodsReceipt.received_at)
        )
    ).all()
    invoices = (
        await session.exec(
            select(SupplierInvoice).where(SupplierInvoice.purchase_order_id == po.id)
        )
    ).all()
    header = PurchaseOrderRead.model_validate(po)
    return PurchaseOrderDetailRead(
        **header.model_dump(),
        lines=[PurchaseOrderLineRead.model_validate(line) for line in lines],
        receipts=[GoodsReceiptRead.model_validate(grn) for grn in receipts],
        invoices=[SupplierInvoiceRead.model_validate(inv) for inv in invoices],
    )


async def _refresh_po_invoice_status(
    session: AsyncSession, po: PurchaseOrder
) -> None:
    """Recompute ``po.invoice_status`` from the aggregate of its invoices."""
    invoices = (
        await session.exec(
            select(SupplierInvoice).where(SupplierInvoice.purchase_order_id == po.id)
        )
    ).all()
    if not invoices:
        po.invoice_status = InvoiceStatus.UNBILLED
    elif all(inv.status == InvoiceStatus.PAID for inv in invoices):
        po.invoice_status = InvoiceStatus.PAID
    elif any(inv.amount_paid > 0 for inv in invoices):
        po.invoice_status = InvoiceStatus.PARTIAL
    else:
        po.invoice_status = InvoiceStatus.UNPAID
    session.add(po)


def _build_list_query(
    business_id: UUID, filters: PurchaseOrderListFilters
) -> SelectOfScalar[PurchaseOrder]:
    stmt = select(PurchaseOrder).where(PurchaseOrder.business_id == business_id)
    if filters.status is not None:
        stmt = stmt.where(PurchaseOrder.status == filters.status)
    if filters.invoice_status is not None:
        stmt = stmt.where(PurchaseOrder.invoice_status == filters.invoice_status)
    if filters.supplier_id is not None:
        stmt = stmt.where(PurchaseOrder.supplier_id == filters.supplier_id)
    if filters.store_id is not None:
        stmt = stmt.where(PurchaseOrder.store_id == filters.store_id)
    return stmt.order_by(PurchaseOrder.ordered_at.desc())


# ═══════════════════════════════════════════════════════════════════════
# Purchase orders
# ═══════════════════════════════════════════════════════════════════════


@router.post("/orders", response_model=PurchaseOrderRead, status_code=status.HTTP_201_CREATED)
async def create_order(
    business_id: UUID,
    body: PurchaseOrderCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.create"))],
) -> PurchaseOrder:
    await _get_supplier_or_404(business_id, body.supplier_id, session)

    resolved: list[tuple[Item, str]] = []
    for line in body.lines:
        item = (
            await session.exec(
                select(Item).where(
                    Item.id == line.item_id, Item.business_id == business_id
                )
            )
        ).one_or_none()
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Item '{line.item_id}' not found",
            )
        if item.item_type == ItemType.SELLABLE:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    f"Cannot purchase sellable-only item '{item.name}' — it can "
                    "never be purchase-received. Order its raw-material "
                    "components instead."
                ),
            )
        if item.unit_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Item '{item.name}' has no unit assigned.",
            )
        unit = (
            await session.exec(select(Unit).where(Unit.id == item.unit_id))
        ).one_or_none()
        if unit is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Item '{item.name}' references a missing unit.",
            )
        resolved.append((item, unit.code))

    if body.po_number is not None:
        existing = (
            await session.exec(
                select(PurchaseOrder).where(
                    PurchaseOrder.business_id == business_id,
                    PurchaseOrder.po_number == body.po_number,
                )
            )
        ).one_or_none()
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"PO number '{body.po_number}' already exists",
            )
        po_number = body.po_number
    else:
        po_number = await _next_number(session, PurchaseOrder, business_id, "PO")

    total = sum(
        (line.quantity_ordered * line.unit_cost for line in body.lines),
        Decimal("0.00"),
    )
    po = PurchaseOrder(
        business_id=business_id,
        store_id=body.store_id,
        supplier_id=body.supplier_id,
        po_number=po_number,
        status=PurchaseOrderStatus.DRAFT,
        total_amount=total,
        notes=body.notes,
        ordered_at=datetime.now(UTC),
        ordered_by=_extract_actor_id(claims),
        expected_at=body.expected_at,
    )
    session.add(po)
    # Flush so the header row exists before its lines reference it.
    await session.flush()
    for line, (_item, unit_code) in zip(body.lines, resolved, strict=True):
        session.add(
            PurchaseOrderLine(
                purchase_order_id=po.id,
                item_id=line.item_id,
                quantity_ordered=line.quantity_ordered,
                quantity_received=Decimal("0.000"),
                unit=unit_code,
                unit_cost=line.unit_cost,
                notes=line.notes,
            )
        )
    try:
        await session.commit()
    except IntegrityError as exc:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="PO number already exists — retry without an explicit po_number",
        ) from exc
    await session.refresh(po)

    logger.info(
        "purchase.created",
        order_id=str(po.id),
        business_id=str(business_id),
        po_number=po_number,
    )
    return po


@router.get("/orders", response_model=PurchaseOrderListResponse)
async def list_orders(
    business_id: UUID,
    filters: Annotated[PurchaseOrderListFilters, Depends()],
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.view"))],
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> PurchaseOrderListResponse:
    base_stmt = _build_list_query(business_id, filters)
    total = len((await session.exec(base_stmt)).all())
    items = list((await session.exec(base_stmt.offset(offset).limit(limit))).all())
    return PurchaseOrderListResponse(
        items=items, total=total, limit=limit, offset=offset
    )


@router.post("/orders/{order_id}/submit", response_model=PurchaseOrderRead)
async def submit_order(
    business_id: UUID,
    order_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.create"))],
) -> PurchaseOrder:
    po = await _get_po_or_404(business_id, order_id, session)
    if po.status != PurchaseOrderStatus.DRAFT:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is {po.status.value}, only draft orders can be submitted",
        )
    po.status = PurchaseOrderStatus.SUBMITTED
    session.add(po)
    await session.commit()
    await session.refresh(po)
    logger.info("purchase.submitted", order_id=str(po.id), business_id=str(business_id))
    return po


@router.post("/orders/{order_id}/approve", response_model=PurchaseOrderRead)
async def approve_order(
    business_id: UUID,
    order_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.approve"))],
) -> PurchaseOrder:
    po = await _get_po_or_404(business_id, order_id, session)
    if po.status != PurchaseOrderStatus.SUBMITTED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is {po.status.value}, only submitted orders can be approved",
        )
    po.status = PurchaseOrderStatus.APPROVED
    po.approved_at = datetime.now(UTC)
    po.approved_by = _extract_actor_id(claims)
    session.add(po)
    await session.commit()
    await session.refresh(po)
    logger.info("purchase.approved", order_id=str(po.id), business_id=str(business_id))
    return po


@router.post("/orders/{order_id}/cancel", response_model=PurchaseOrderRead)
async def cancel_order(
    business_id: UUID,
    order_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.create"))],
) -> PurchaseOrder:
    po = await _get_po_or_404(business_id, order_id, session)
    if po.status in (
        PurchaseOrderStatus.PARTIALLY_RECEIVED,
        PurchaseOrderStatus.RECEIVED,
        PurchaseOrderStatus.CANCELLED,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is {po.status.value}, cannot cancel it",
        )
    po.status = PurchaseOrderStatus.CANCELLED
    po.cancelled_at = datetime.now(UTC)
    po.cancelled_by = _extract_actor_id(claims)
    session.add(po)
    await session.commit()
    await session.refresh(po)
    logger.info("purchase.cancelled", order_id=str(po.id), business_id=str(business_id))
    return po


@router.post("/orders/{order_id}/receive", response_model=GoodsReceiptDetailRead)
async def receive_order(
    business_id: UUID,
    order_id: UUID,
    body: GoodsReceiptCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.receive"))],
) -> GoodsReceiptDetailRead:
    po = await _get_po_or_404(business_id, order_id, session)
    if po.status not in (
        PurchaseOrderStatus.APPROVED,
        PurchaseOrderStatus.PARTIALLY_RECEIVED,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is {po.status.value}, only approved orders can be received",
        )
    actor_id = _extract_actor_id(claims)

    lines = (
        await session.exec(
            select(PurchaseOrderLine).where(PurchaseOrderLine.purchase_order_id == po.id)
        )
    ).all()
    lines_by_id = {line.id: line for line in lines}

    grn = GoodsReceipt(
        business_id=business_id,
        store_id=po.store_id,
        purchase_order_id=po.id,
        grn_number=await _next_number(session, GoodsReceipt, business_id, "GRN"),
        notes=body.notes,
        received_at=datetime.now(UTC),
        received_by=actor_id,
    )
    session.add(grn)

    try:
        for req in body.lines:
            pol = lines_by_id.get(req.purchase_order_line_id)
            if pol is None:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"PO line '{req.purchase_order_line_id}' is not on this order",
                )
            outstanding = pol.quantity_ordered - pol.quantity_received
            if req.quantity_received > outstanding:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=(
                        f"Over-receive on line '{pol.id}': ordered={pol.quantity_ordered}, "
                        f"already received={pol.quantity_received}, "
                        f"requested={req.quantity_received}"
                    ),
                )

            item_result = await session.exec(
                select(Item).where(
                    Item.id == pol.item_id, Item.business_id == business_id
                )
            )
            item = item_result.one_or_none()
            if item is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Item '{pol.item_id}' not found",
                )

            level = (
                await session.exec(
                    select(StockLevel).where(
                        StockLevel.item_id == item.id,
                        StockLevel.store_id == po.store_id,
                    )
                )
            ).one_or_none()
            old_qty: Decimal = level.current_quantity if level else Decimal("0.000")
            old_cost: Decimal = item.unit_cost if item.unit_cost is not None else pol.unit_cost

            await record_movement(
                db=session,
                item_id=item.id,
                business_id=business_id,
                store_id=po.store_id,
                quantity_delta=req.quantity_received,
                movement_type=MovementType.PURCHASE_RECEIVED,
                reference_type="goods_receipt",
                reference_id=grn.id,
                actor_type=ActorType.USER.value,
                actor_id=actor_id,
                reason=f"GRN {grn.grn_number} for PO {po.po_number}",
                commit=False,
            )

            # Weighted-average costing in the same transaction.
            denom = old_qty + req.quantity_received
            if denom > 0:
                new_cost = (
                    (old_qty * old_cost + req.quantity_received * pol.unit_cost) / denom
                ).quantize(Decimal("0.0001"))
            else:
                new_cost = pol.unit_cost
            item.unit_cost = new_cost
            session.add(item)

            pol.quantity_received = pol.quantity_received + req.quantity_received
            session.add(pol)
            session.add(
                GoodsReceiptLine(
                    goods_receipt_id=grn.id,
                    purchase_order_line_id=pol.id,
                    item_id=item.id,
                    quantity_received=req.quantity_received,
                    lot_no=req.lot_no,
                    expiry_date=req.expiry_date,
                )
            )

        refreshed = (
            await session.exec(
                select(PurchaseOrderLine).where(
                    PurchaseOrderLine.purchase_order_id == po.id
                )
            )
        ).all()
        if all(
            line.quantity_received >= line.quantity_ordered for line in refreshed
        ):
            po.status = PurchaseOrderStatus.RECEIVED
            po.received_at = datetime.now(UTC)
            po.received_by = actor_id
        else:
            po.status = PurchaseOrderStatus.PARTIALLY_RECEIVED
        session.add(po)

        await session.commit()
    except (ItemTypeMismatchError, InsufficientStockError) as exc:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    except HTTPException:
        await session.rollback()
        raise
    except IntegrityError as exc:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="GRN number already exists — retry the receive",
        ) from exc
    except Exception:
        await session.rollback()
        raise

    await session.refresh(grn)
    grn_lines = (
        await session.exec(
            select(GoodsReceiptLine).where(GoodsReceiptLine.goods_receipt_id == grn.id)
        )
    ).all()
    logger.info(
        "purchase.received",
        order_id=str(po.id),
        grn_id=str(grn.id),
        business_id=str(business_id),
    )
    header = GoodsReceiptRead.model_validate(grn)
    return GoodsReceiptDetailRead(
        **header.model_dump(),
        lines=[GoodsReceiptLineRead.model_validate(line) for line in grn_lines],
    )


@router.get("/orders/{order_id}", response_model=PurchaseOrderDetailRead)
async def get_order(
    business_id: UUID,
    order_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.view"))],
) -> PurchaseOrderDetailRead:
    """Declared after the literal ``/orders/{id}/…`` action routes so those
    sub-paths are never swallowed by this ``{order_id}`` matcher (same
    ordering discipline as ``reorders.py``)."""
    po = await _get_po_or_404(business_id, order_id, session)
    return await _build_detail(po, session)


# ═══════════════════════════════════════════════════════════════════════
# Purchase returns
# ═══════════════════════════════════════════════════════════════════════


@router.post("/returns", response_model=PurchaseReturnRead, status_code=status.HTTP_201_CREATED)
async def create_return(
    business_id: UUID,
    body: PurchaseReturnCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.receive"))],
) -> PurchaseReturn:
    item = (
        await session.exec(
            select(Item).where(Item.id == body.item_id, Item.business_id == business_id)
        )
    ).one_or_none()
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )

    store_id = body.store_id
    po: PurchaseOrder | None = None
    if body.purchase_order_id is not None:
        po = await _get_po_or_404(business_id, body.purchase_order_id, session)
        if po.status not in (
            PurchaseOrderStatus.APPROVED,
            PurchaseOrderStatus.PARTIALLY_RECEIVED,
            PurchaseOrderStatus.RECEIVED,
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Order is {po.status.value}, nothing has been received to return",
            )
        if store_id is not None and store_id != po.store_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Return store does not match the purchase order's store",
            )
        store_id = po.store_id
    if store_id is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="store_id is required when no purchase_order_id is given",
        )

    if body.goods_receipt_id is not None:
        grn = (
            await session.exec(
                select(GoodsReceipt).where(
                    GoodsReceipt.id == body.goods_receipt_id,
                    GoodsReceipt.business_id == business_id,
                )
            )
        ).one_or_none()
        if grn is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goods receipt not found",
            )
        if po is not None and grn.purchase_order_id != po.id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Goods receipt does not belong to the purchase order",
            )

    if po is not None:
        po_lines = (
            await session.exec(
                select(PurchaseOrderLine).where(
                    PurchaseOrderLine.purchase_order_id == po.id,
                    PurchaseOrderLine.item_id == item.id,
                )
            )
        ).all()
        received_for_item = sum(
            (line.quantity_received for line in po_lines), Decimal("0.000")
        )
        prior_returns = (
            await session.exec(
                select(func.coalesce(func.sum(PurchaseReturn.quantity), 0)).where(
                    PurchaseReturn.business_id == business_id,
                    PurchaseReturn.purchase_order_id == po.id,
                    PurchaseReturn.item_id == item.id,
                )
            )
        ).one()
        returnable = received_for_item - Decimal(prior_returns)
        if body.quantity > returnable:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Cannot return {body.quantity}: only {returnable} received "
                    f"and not yet returned for this item on order {po.po_number}"
                ),
            )

    ret = PurchaseReturn(
        business_id=business_id,
        store_id=store_id,
        purchase_order_id=body.purchase_order_id,
        goods_receipt_id=body.goods_receipt_id,
        item_id=item.id,
        quantity=body.quantity,
        reason=body.reason,
        created_by=_extract_actor_id(claims),
    )
    actor_id = _extract_actor_id(claims)
    session.add(ret)
    try:
        await record_movement(
            db=session,
            item_id=item.id,
            business_id=business_id,
            store_id=store_id,
            quantity_delta=-body.quantity,
            movement_type=MovementType.MANUAL_ADJUSTMENT,
            reference_type="purchase_return",
            reference_id=ret.id,
            actor_type=ActorType.USER.value,
            actor_id=actor_id,
            reason=body.reason or f"Purchase return {ret.id}",
            commit=False,
        )
        session.add(ret)
        await session.commit()
    except InsufficientStockError as exc:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(exc),
        ) from exc
    except Exception:
        await session.rollback()
        raise
    await session.refresh(ret)

    logger.info(
        "purchase.returned",
        return_id=str(ret.id),
        business_id=str(business_id),
        item_id=str(item.id),
        quantity=str(body.quantity),
    )
    return ret


# ═══════════════════════════════════════════════════════════════════════
# Supplier invoices & payments
# ═══════════════════════════════════════════════════════════════════════


@router.post("/invoices", response_model=SupplierInvoiceRead, status_code=status.HTTP_201_CREATED)
async def create_invoice(
    business_id: UUID,
    body: SupplierInvoiceCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.approve"))],
) -> SupplierInvoice:
    po = await _get_po_or_404(business_id, body.purchase_order_id, session)
    if po.status not in (
        PurchaseOrderStatus.APPROVED,
        PurchaseOrderStatus.PARTIALLY_RECEIVED,
        PurchaseOrderStatus.RECEIVED,
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is {po.status.value}, cannot invoice it",
        )

    if body.amount_total is not None:
        amount_total = body.amount_total
    else:
        po_lines = (
            await session.exec(
                select(PurchaseOrderLine).where(
                    PurchaseOrderLine.purchase_order_id == po.id
                )
            )
        ).all()
        amount_total = sum(
            (
                line.quantity_received * line.unit_cost
                for line in po_lines
            ),
            Decimal("0.00"),
        )
        if amount_total <= 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "Nothing has been received on this order yet — pass an "
                    "explicit amount_total or receive goods first"
                ),
            )

    invoice = SupplierInvoice(
        business_id=business_id,
        supplier_id=po.supplier_id,
        purchase_order_id=po.id,
        invoice_number=body.invoice_number,
        amount_total=amount_total,
        amount_paid=Decimal("0.00"),
        status=InvoiceStatus.UNPAID,
        due_at=body.due_at,
        created_by=_extract_actor_id(claims),
    )
    session.add(invoice)
    if po.invoice_status == InvoiceStatus.UNBILLED:
        po.invoice_status = InvoiceStatus.UNPAID
        session.add(po)
    await session.commit()
    await session.refresh(invoice)

    logger.info(
        "purchase.invoiced",
        invoice_id=str(invoice.id),
        order_id=str(po.id),
        business_id=str(business_id),
    )
    return invoice


@router.post(
    "/invoices/{invoice_id}/payments",
    response_model=SupplierPaymentRead,
    status_code=status.HTTP_201_CREATED,
)
async def record_payment(
    business_id: UUID,
    invoice_id: UUID,
    body: SupplierPaymentCreate,
    session: Annotated[AsyncSession, Depends(get_db)],
    claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.approve"))],
) -> SupplierPayment:
    invoice = (
        await session.exec(
            select(SupplierInvoice).where(
                SupplierInvoice.id == invoice_id,
                SupplierInvoice.business_id == business_id,
            )
        )
    ).one_or_none()
    if invoice is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found"
        )
    remaining = invoice.amount_total - invoice.amount_paid
    if body.amount > remaining:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Payment {body.amount} exceeds remaining balance {remaining}",
        )

    actor_id = _extract_actor_id(claims)
    payment = SupplierPayment(
        business_id=business_id,
        invoice_id=invoice.id,
        amount=body.amount,
        method=body.method,
        reference=body.reference,
        paid_at=datetime.now(UTC),
        paid_by=actor_id,
    )
    session.add(payment)
    invoice.amount_paid = invoice.amount_paid + body.amount
    invoice.status = (
        InvoiceStatus.PAID
        if invoice.amount_paid >= invoice.amount_total
        else InvoiceStatus.PARTIAL
    )
    session.add(invoice)
    await session.flush()

    po = await _get_po_or_404(business_id, invoice.purchase_order_id, session)
    await _refresh_po_invoice_status(session, po)
    await session.commit()
    await session.refresh(payment)

    logger.info(
        "purchase.paid",
        payment_id=str(payment.id),
        invoice_id=str(invoice.id),
        business_id=str(business_id),
    )
    return payment


# ═══════════════════════════════════════════════════════════════════════
# Supplier statement
# ═══════════════════════════════════════════════════════════════════════


@router.get(
    "/suppliers/{supplier_id}/statement", response_model=SupplierStatementRead
)
async def supplier_statement(
    business_id: UUID,
    supplier_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    _jwt_biz_id: Annotated[str, Depends(require_business_permission("procurement.view"))],
) -> SupplierStatementRead:
    # allow_deleted=True: history must still resolve after a supplier retires.
    supplier = await _get_supplier_or_404(
        business_id, supplier_id, session, allow_deleted=True
    )
    open_orders = list(
        (
            await session.exec(
                select(PurchaseOrder)
                .where(
                    PurchaseOrder.business_id == business_id,
                    PurchaseOrder.supplier_id == supplier.id,
                    PurchaseOrder.status.in_(_OPEN_ORDER_STATUSES),
                )
                .order_by(PurchaseOrder.ordered_at.desc())
            )
        ).all()
    )
    unpaid_invoices = list(
        (
            await session.exec(
                select(SupplierInvoice).where(
                    SupplierInvoice.business_id == business_id,
                    SupplierInvoice.supplier_id == supplier.id,
                    SupplierInvoice.status.in_(
                        (InvoiceStatus.UNPAID, InvoiceStatus.PARTIAL)
                    ),
                )
            )
        ).all()
    )
    outstanding = sum(
        (inv.amount_total - inv.amount_paid for inv in unpaid_invoices),
        Decimal("0.00"),
    )
    return SupplierStatementRead(
        supplier_id=supplier.id,
        business_id=business_id,
        open_orders=[PurchaseOrderRead.model_validate(po) for po in open_orders],
        unpaid_invoices=[
            SupplierInvoiceRead.model_validate(inv) for inv in unpaid_invoices
        ],
        outstanding_balance=outstanding,
    )
