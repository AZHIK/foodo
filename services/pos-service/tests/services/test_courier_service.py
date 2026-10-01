from __future__ import annotations

from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.couriers import Courier
from app.models.pos import Sale
from app.schemas.couriers import CourierCreate, CourierUpdate
from app.services.courier_service import (
    CourierConflictError,
    CourierNotFoundError,
    CourierValidationError,
    create_courier,
    delete_courier,
    get_courier,
    list_couriers,
    update_courier,
    validate_courier_for_sale,
)


def _create_payload(**overrides: object) -> CourierCreate:
    return CourierCreate(
        name=str(overrides.get("name", "James Chen")),
        phone=str(overrides.get("phone", "+255-700-000-001")),
        vehicle=overrides.get("vehicle", "Honda Civic - JX22KPL"),  # type: ignore[arg-type]
        is_active=overrides.get("is_active", True),  # type: ignore[arg-type]
    )


class TestCreateCourier:
    async def test_create_courier_persists_row(self, db_session: AsyncSession) -> None:
        business_id = uuid4()
        courier = await create_courier(db_session, business_id, None, _create_payload())
        assert courier.business_id == business_id
        assert courier.name == "James Chen"
        assert courier.is_active is True

        reloaded = (await db_session.exec(select(Courier).where(Courier.id == courier.id))).one()
        assert reloaded.phone == "+255-700-000-001"

    async def test_duplicate_phone_same_business_conflicts(self, db_session: AsyncSession) -> None:
        business_id = uuid4()
        await create_courier(db_session, business_id, None, _create_payload())
        with pytest.raises(CourierConflictError):
            await create_courier(db_session, business_id, None, _create_payload())

        rows = (
            await db_session.exec(select(Courier).where(Courier.business_id == business_id))
        ).all()
        assert len(rows) == 1

    async def test_same_phone_different_business_ok(self, db_session: AsyncSession) -> None:
        await create_courier(db_session, uuid4(), None, _create_payload())
        courier2 = await create_courier(db_session, uuid4(), None, _create_payload())
        assert courier2.id is not None


class TestListCouriers:
    async def test_list_is_business_scoped(self, db_session: AsyncSession) -> None:
        bid_a, bid_b = uuid4(), uuid4()
        await create_courier(db_session, bid_a, None, _create_payload(phone="p-a"))
        await create_courier(db_session, bid_b, None, _create_payload(phone="p-b"))

        result = await list_couriers(db_session, bid_a, limit=20, offset=0)
        assert result.total == 1
        assert result.items[0].phone == "p-a"

    async def test_search_and_active_only(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        await create_courier(db_session, bid, None, _create_payload(name="James Chen", phone="p-1"))
        await create_courier(
            db_session,
            bid,
            None,
            _create_payload(name="Maria Rossi", phone="p-2", is_active=False),
        )

        searched = await list_couriers(db_session, bid, limit=20, offset=0, search="james")
        assert searched.total == 1

        active = await list_couriers(db_session, bid, limit=20, offset=0, active_only=True)
        assert active.total == 1
        assert active.items[0].name == "James Chen"


class TestUpdateAndDelete:
    async def test_update_name_and_deactivate(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(db_session, bid, None, _create_payload())
        updated = await update_courier(
            db_session, bid, courier.id, CourierUpdate(name="Jay C", is_active=False)
        )
        assert updated.name == "Jay C"
        assert updated.is_active is False

    async def test_update_phone_clash_conflicts(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        await create_courier(db_session, bid, None, _create_payload(phone="p-1"))
        courier2 = await create_courier(db_session, bid, None, _create_payload(phone="p-2"))
        with pytest.raises(CourierConflictError):
            await update_courier(db_session, bid, courier2.id, CourierUpdate(phone="p-1"))

    async def test_update_missing_raises_not_found(self, db_session: AsyncSession) -> None:
        with pytest.raises(CourierNotFoundError):
            await update_courier(db_session, uuid4(), uuid4(), CourierUpdate(name="Ghost"))

    async def test_delete_removes_row_and_nulls_sale_courier(
        self, db_session: AsyncSession
    ) -> None:
        from datetime import UTC, datetime
        from decimal import Decimal
        from unittest.mock import AsyncMock

        from app.schemas.line_items import SaleLineItemInput
        from app.schemas.sales import SaleSyncBatchRequest, SaleSyncInput
        from app.services.sale_service import sync_sale_batch

        bid = uuid4()
        courier = await create_courier(db_session, bid, None, _create_payload())

        batch = SaleSyncBatchRequest(
            sales=[
                SaleSyncInput(
                    client_sale_id="courier-del-sale",
                    status="completed",
                    store_id=uuid4(),
                    line_items=[
                        SaleLineItemInput(
                            item_id=uuid4(),
                            quantity=Decimal("1"),
                            unit_price=Decimal("10.00"),
                        )
                    ],
                    discount_amount=Decimal("0"),
                    payment_method="cash",
                    occurred_at=datetime.now(UTC),
                    order_type="delivery",
                    courier_id=courier.id,
                    delivery_address_line1="123 Main St",
                    delivery_fee=Decimal("2.50"),
                )
            ]
        )
        response = await sync_sale_batch(db_session, bid, None, batch, publish=AsyncMock())
        assert response.results[0].status == "created"

        await delete_courier(db_session, bid, courier.id)
        with pytest.raises(CourierNotFoundError):
            await get_courier(db_session, bid, courier.id)

        sale = (
            await db_session.exec(select(Sale).where(Sale.client_sale_id == "courier-del-sale"))
        ).one()
        assert sale.courier_id is None  # ON DELETE SET NULL preserved the sale


class TestValidateCourierForSale:
    async def test_inactive_courier_rejected(self, db_session: AsyncSession) -> None:
        bid = uuid4()
        courier = await create_courier(db_session, bid, None, _create_payload(is_active=False))
        with pytest.raises(CourierValidationError):
            await validate_courier_for_sale(db_session, bid, courier.id)

    async def test_wrong_business_rejected(self, db_session: AsyncSession) -> None:
        courier = await create_courier(db_session, uuid4(), None, _create_payload())
        with pytest.raises(CourierValidationError):
            await validate_courier_for_sale(db_session, uuid4(), courier.id)

    async def test_missing_courier_rejected(self, db_session: AsyncSession) -> None:
        with pytest.raises(CourierValidationError):
            await validate_courier_for_sale(db_session, uuid4(), uuid4())
