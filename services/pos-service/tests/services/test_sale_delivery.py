from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from unittest.mock import AsyncMock
from uuid import UUID, uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.pos import DeliveryStatus, OrderType, Sale
from app.schemas.couriers import CourierCreate
from app.schemas.line_items import SaleLineItemInput
from app.schemas.sales import SaleSyncBatchRequest, SaleSyncInput
from app.services.courier_service import create_courier
from app.services.sale_service import (
    SaleValidationError,
    sync_sale_batch,
    update_delivery_status,
)


def _delivery_input(**overrides: object) -> SaleSyncInput:
    kwargs: dict = {
        "client_sale_id": f"del-{uuid4()}",
        "status": "completed",
        "store_id": uuid4(),
        "line_items": [
            SaleLineItemInput(
                item_id=uuid4(),
                quantity=Decimal("1"),
                unit_price=Decimal("10.00"),
            )
        ],
        "discount_amount": Decimal("0"),
        "payment_method": "cash",
        "occurred_at": datetime.now(UTC),
        "order_type": "delivery",
        "delivery_address_line1": "123 Main St, Dar es Salaam",
        "delivery_fee": Decimal("2.50"),
    }
    kwargs.update(overrides)
    return SaleSyncInput(**kwargs)


def _dine_in_input(**overrides: object) -> SaleSyncInput:
    kwargs: dict = {
        "client_sale_id": f"dine-{uuid4()}",
        "status": "completed",
        "store_id": uuid4(),
        "line_items": [
            SaleLineItemInput(
                item_id=uuid4(),
                quantity=Decimal("1"),
                unit_price=Decimal("10.00"),
            )
        ],
        "discount_amount": Decimal("0"),
        "payment_method": "cash",
        "occurred_at": datetime.now(UTC),
    }
    kwargs.update(overrides)
    return SaleSyncInput(**kwargs)


class TestDeliverySaleSync:
    async def test_delivery_sale_persists_fee_and_pending_status(
        self, db_session: AsyncSession
    ) -> None:
        bid = uuid4()
        courier = await create_courier(
            db_session,
            bid,
            None,
            CourierCreate(name="James", phone="p-1", vehicle=None),
        )
        batch = SaleSyncBatchRequest(
            sales=[_delivery_input(client_sale_id="del-fee-1", courier_id=courier.id)]
        )
        mock_publish = AsyncMock()
        response = await sync_sale_batch(db_session, bid, None, batch, publish=mock_publish)
        assert response.results[0].status == "created"

        sale = (await db_session.exec(select(Sale).where(Sale.client_sale_id == "del-fee-1"))).one()
        assert sale.order_type == OrderType.DELIVERY
        assert sale.courier_id == courier.id
        assert sale.delivery_fee == Decimal("2.50")
        assert sale.total == Decimal("12.50")  # 10.00 + 0 tax + 2.50 fee
        assert sale.delivery_status == DeliveryStatus.PENDING
        assert sale.delivery_address_line1 == "123 Main St, Dar es Salaam"

        # sale.completed carries the delivery keys (additive — inventory ignores them).
        mock_publish.assert_awaited_once()
        payload = mock_publish.await_args.args[1]
        assert payload["order_type"] == "delivery"
        assert payload["courier_id"] == str(courier.id)
        assert payload["delivery_status"] == "pending"
        assert payload["delivery_fee"] == "2.50"

    async def test_delivery_without_address_fails(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        batch = SaleSyncBatchRequest(sales=[_delivery_input(client_sale_id="del-no-addr")])
        # Bypass Pydantic by mutating AFTER batch construction (same trick
        # as TestSyncSaleBatch.test_partial_success_one_fails_one_succeeds)
        # to prove the service layer enforces the rule with per-sale failure.
        batch.sales[0].delivery_address_line1 = None
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "failed"
        assert "delivery_address_line1" in (response.results[0].reason or "")

    async def test_non_delivery_with_courier_fails(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(
            db_session, bid, None, CourierCreate(name="J", phone="p-9", vehicle=None)
        )
        batch = SaleSyncBatchRequest(sales=[_dine_in_input(client_sale_id="dine-with-courier")])
        # Bypass Pydantic by mutating AFTER batch construction to prove the
        # service layer enforces it too.
        batch.sales[0].courier_id = courier.id
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "failed"

    async def test_non_delivery_with_fee_fails(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        batch = SaleSyncBatchRequest(sales=[_dine_in_input(client_sale_id="dine-with-fee")])
        batch.sales[0].delivery_fee = Decimal("5.00")
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "failed"

    async def test_delivery_with_inactive_courier_fails(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(
            db_session,
            bid,
            None,
            CourierCreate(name="Off Duty", phone="p-off", vehicle=None, is_active=False),
        )
        batch = SaleSyncBatchRequest(
            sales=[_delivery_input(client_sale_id="del-inactive", courier_id=courier.id)]
        )
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "failed"
        assert "inactive" in (response.results[0].reason or "")

    async def test_delivery_with_foreign_courier_fails(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(
            db_session, uuid4(), None, CourierCreate(name="X", phone="p-x", vehicle=None)
        )
        batch = SaleSyncBatchRequest(
            sales=[_delivery_input(client_sale_id="del-foreign", courier_id=courier.id)]
        )
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "failed"

    async def test_dine_in_defaults(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        batch = SaleSyncBatchRequest(sales=[_dine_in_input(client_sale_id="dine-plain")])
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "created"
        sale = (
            await db_session.exec(select(Sale).where(Sale.client_sale_id == "dine-plain"))
        ).one()
        assert sale.order_type == OrderType.DINE_IN
        assert sale.delivery_status is None
        assert sale.delivery_fee == Decimal("0.00")
        assert sale.courier_id is None


class TestDeliveryStatusTransitions:
    async def _seed_delivery_sale(
        self, db_session: AsyncSession, business_id: UUID, courier_id=None
    ) -> Sale:
        batch = SaleSyncBatchRequest(
            sales=[_delivery_input(client_sale_id=f"del-{uuid4()}", courier_id=courier_id)]
        )
        await sync_sale_batch(db_session, business_id, None, batch, publish=AsyncMock())
        sale_id = (
            (await db_session.exec(select(Sale).where(Sale.business_id == business_id)))
            .all()[-1]
            .id
        )
        return (await db_session.exec(select(Sale).where(Sale.id == sale_id))).one()

    async def test_full_lifecycle_pending_to_delivered(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(
            db_session, bid, None, CourierCreate(name="J", phone="p-lc", vehicle=None)
        )
        sale = await self._seed_delivery_sale(db_session, bid)

        mock = AsyncMock()
        sale = await update_delivery_status(
            db_session,
            bid,
            sale.id,
            None,
            DeliveryStatus.ASSIGNED,
            courier_id=courier.id,
            publish=mock,
        )
        assert sale.delivery_status == DeliveryStatus.ASSIGNED
        assert sale.courier_id == courier.id
        mock.assert_awaited_once()
        assert mock.await_args.args[0] == "delivery.status_changed"

        sale = await update_delivery_status(
            db_session,
            bid,
            sale.id,
            None,
            DeliveryStatus.OUT_FOR_DELIVERY,
            publish=AsyncMock(),
        )
        assert sale.delivery_status == DeliveryStatus.OUT_FOR_DELIVERY

        sale = await update_delivery_status(
            db_session,
            bid,
            sale.id,
            None,
            DeliveryStatus.DELIVERED,
            publish=AsyncMock(),
        )
        assert sale.delivery_status == DeliveryStatus.DELIVERED

    async def test_skip_step_rejected(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        sale = await self._seed_delivery_sale(db_session, bid)
        with pytest.raises(SaleValidationError):
            await update_delivery_status(
                db_session,
                bid,
                sale.id,
                None,
                DeliveryStatus.DELIVERED,
                publish=AsyncMock(),
            )

    async def test_assign_without_courier_rejected(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        sale = await self._seed_delivery_sale(db_session, bid)
        with pytest.raises(SaleValidationError):
            await update_delivery_status(
                db_session,
                bid,
                sale.id,
                None,
                DeliveryStatus.ASSIGNED,
                publish=AsyncMock(),
            )

    async def test_terminal_state_rejects_moves(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(
            db_session, bid, None, CourierCreate(name="J", phone="p-t", vehicle=None)
        )
        sale = await self._seed_delivery_sale(db_session, bid, courier_id=courier.id)
        sale = await update_delivery_status(
            db_session,
            bid,
            sale.id,
            None,
            DeliveryStatus.ASSIGNED,
            publish=AsyncMock(),
        )
        sale = await update_delivery_status(
            db_session,
            bid,
            sale.id,
            None,
            DeliveryStatus.FAILED,
            publish=AsyncMock(),
        )
        assert sale.delivery_status == DeliveryStatus.FAILED
        with pytest.raises(SaleValidationError):
            await update_delivery_status(
                db_session,
                bid,
                sale.id,
                None,
                DeliveryStatus.DELIVERED,
                publish=AsyncMock(),
            )

    async def test_non_delivery_sale_rejected(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        await sync_sale_batch(
            db_session,
            bid,
            None,
            SaleSyncBatchRequest(sales=[_dine_in_input(client_sale_id="nd-1")]),
            publish=AsyncMock(),
        )
        sale = (await db_session.exec(select(Sale).where(Sale.client_sale_id == "nd-1"))).one()
        with pytest.raises(SaleValidationError):
            await update_delivery_status(
                db_session,
                bid,
                sale.id,
                None,
                DeliveryStatus.ASSIGNED,
                publish=AsyncMock(),
            )
