"""API tests for couriers endpoints and the sale delivery-status transition."""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.pos import Sale
from tests.test_token_verification import _build_token

COURIERS_URL = "/api/v1/businesses/{business_id}/couriers"
COURIER_DETAIL_URL = "/api/v1/businesses/{business_id}/couriers/{courier_id}"
SALE_SYNC_URL = "/api/v1/businesses/{business_id}/sales/sync"
DELIVERY_STATUS_URL = "/api/v1/businesses/{business_id}/sales/{sale_id}/delivery-status"
SALE_DETAIL_URL = "/api/v1/businesses/{business_id}/sales/{sale_id}"

ALL_PERMS = [
    "couriers.view",
    "couriers.create",
    "couriers.update",
    "couriers.delete",
    "pos.write",
    "pos.view",
]


def _auth_header(
    *, business_id: UUID | None = None, permissions: list[str] | None = None
) -> dict[str, str]:
    biz_id = business_id or uuid4()
    token = _build_token(
        extra_claims={
            "permissions": permissions if permissions is not None else ALL_PERMS,
            "active_business_id": str(biz_id),
        },
    )
    return {"Authorization": f"Bearer {token}"}


def _courier_payload(**overrides: object) -> dict:
    payload: dict = {
        "name": "James Chen",
        "phone": "+255-700-000-001",
        "vehicle": "Honda Civic - JX22KPL",
    }
    payload.update(overrides)
    return payload


def _delivery_sale_payload(**overrides: object) -> dict:
    sale: dict = {
        "client_sale_id": str(overrides.get("client_sale_id", uuid4())),
        "status": "completed",
        "store_id": str(overrides.get("store_id", uuid4())),
        "line_items": [{"item_id": str(uuid4()), "quantity": "1", "unit_price": "10.00"}],
        "discount_amount": "0",
        "payment_method": "cash",
        "occurred_at": datetime.now(UTC).isoformat(),
        "order_type": "delivery",
        "delivery_address_line1": "123 Main St",
        "delivery_fee": "2.50",
    }
    for key in (
        "courier_id",
        "delivery_recipient_phone",
        "delivery_note",
        "order_type",
        "delivery_fee",
        "delivery_address_line1",
    ):
        if key in overrides:
            sale[key] = overrides[key]
    return sale


class TestCourierCrud:
    async def test_create_and_get_courier(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)

        resp = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        assert resp.status_code == 201
        courier_id = resp.json()["id"]

        detail = await client.get(
            COURIER_DETAIL_URL.format(business_id=business_id, courier_id=courier_id),
            headers=headers,
        )
        assert detail.status_code == 200
        assert detail.json()["name"] == "James Chen"
        assert detail.json()["business_id"] == str(business_id)

    async def test_duplicate_phone_returns_409(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)

        resp1 = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        assert resp1.status_code == 201

        resp2 = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(name="Someone Else"),
            headers=headers,
        )
        assert resp2.status_code == 409

    async def test_list_is_business_scoped(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        bid_a, bid_b = uuid4(), uuid4()
        await client.post(
            COURIERS_URL.format(business_id=bid_a),
            json=_courier_payload(phone="p-a"),
            headers=_auth_header(business_id=bid_a),
        )
        await client.post(
            COURIERS_URL.format(business_id=bid_b),
            json=_courier_payload(phone="p-b"),
            headers=_auth_header(business_id=bid_b),
        )

        listed = await client.get(
            COURIERS_URL.format(business_id=bid_a),
            headers=_auth_header(business_id=bid_a),
        )
        assert listed.status_code == 200
        assert listed.json()["total"] == 1
        assert listed.json()["items"][0]["phone"] == "p-a"

    async def test_patch_courier(self, client: AsyncClient, db_session: AsyncSession) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)
        created = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        courier_id = created.json()["id"]

        patched = await client.patch(
            COURIER_DETAIL_URL.format(business_id=business_id, courier_id=courier_id),
            json={"is_active": False},
            headers=headers,
        )
        assert patched.status_code == 200
        assert patched.json()["is_active"] is False

    async def test_delete_courier(self, client: AsyncClient, db_session: AsyncSession) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)
        created = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        courier_id = created.json()["id"]

        deleted = await client.delete(
            COURIER_DETAIL_URL.format(business_id=business_id, courier_id=courier_id),
            headers=headers,
        )
        assert deleted.status_code == 204

        missing = await client.get(
            COURIER_DETAIL_URL.format(business_id=business_id, courier_id=courier_id),
            headers=headers,
        )
        assert missing.status_code == 404

    async def test_missing_permission_returns_403(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id, permissions=["pos.view"])
        resp = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        assert resp.status_code == 403

    async def test_wrong_business_returns_403(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        resp = await client.get(
            COURIERS_URL.format(business_id=uuid4()),
            headers=_auth_header(business_id=uuid4()),
        )
        assert resp.status_code == 403


class TestSaleDeliveryApi:
    async def _sync_delivery_sale(
        self,
        client: AsyncClient,
        business_id: UUID,
        headers: dict[str, str],
        **overrides: object,
    ) -> UUID:
        payload = _delivery_sale_payload(**overrides)
        resp = await client.post(
            SALE_SYNC_URL.format(business_id=business_id),
            json={"sales": [payload]},
            headers=headers,
        )
        assert resp.status_code == 200
        assert resp.json()["results"][0]["status"] == "created"
        # Look the sale up by client id to recover the server UUID.
        lookup = await client.get(
            f"/api/v1/businesses/{business_id}/sales/by-client-id/{payload['client_sale_id']}",
            headers=headers,
        )
        assert lookup.status_code == 200
        return UUID(lookup.json()["id"])

    async def test_sync_delivery_sale_round_trips(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)

        courier_resp = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        courier_id = courier_resp.json()["id"]

        sale_id = await self._sync_delivery_sale(
            client, business_id, headers, courier_id=courier_id
        )
        detail = await client.get(
            SALE_DETAIL_URL.format(business_id=business_id, sale_id=sale_id),
            headers=headers,
        )
        assert detail.status_code == 200
        body = detail.json()
        assert body["order_type"] == "delivery"
        assert body["courier_id"] == courier_id
        assert body["delivery_status"] == "pending"
        assert Decimal(body["delivery_fee"]) == Decimal("2.50")
        assert Decimal(body["total"]) == Decimal("12.50")

    async def test_sync_delivery_without_address_fails(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        # A schema-invalid payload is rejected at the HTTP boundary with 422
        # (whole-request validation); per-sale "failed" only applies to
        # service-level rules like unknown/inactive couriers.
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)
        payload = _delivery_sale_payload()
        del payload["delivery_address_line1"]
        resp = await client.post(
            SALE_SYNC_URL.format(business_id=business_id),
            json={"sales": [payload]},
            headers=headers,
        )
        assert resp.status_code == 422

    async def test_delivery_status_lifecycle(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)
        courier_resp = await client.post(
            COURIERS_URL.format(business_id=business_id),
            json=_courier_payload(),
            headers=headers,
        )
        courier_id = courier_resp.json()["id"]
        sale_id = await self._sync_delivery_sale(client, business_id, headers)

        # pending → assigned requires a courier.
        no_courier = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale_id),
            json={"delivery_status": "assigned"},
            headers=headers,
        )
        assert no_courier.status_code == 409

        assigned = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale_id),
            json={"delivery_status": "assigned", "courier_id": courier_id},
            headers=headers,
        )
        assert assigned.status_code == 200
        assert assigned.json()["delivery_status"] == "assigned"
        assert assigned.json()["courier_id"] == courier_id

        # Skipping a step is rejected.
        skip = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale_id),
            json={"delivery_status": "delivered"},
            headers=headers,
        )
        assert skip.status_code == 409

        otd = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale_id),
            json={"delivery_status": "out_for_delivery"},
            headers=headers,
        )
        assert otd.status_code == 200

        done = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale_id),
            json={"delivery_status": "delivered"},
            headers=headers,
        )
        assert done.status_code == 200
        assert done.json()["delivery_status"] == "delivered"

        # Terminal state rejects further moves.
        reopen = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale_id),
            json={"delivery_status": "failed"},
            headers=headers,
        )
        assert reopen.status_code == 409

    async def test_list_filters_by_order_type(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        business_id = uuid4()
        headers = _auth_header(business_id=business_id)
        await self._sync_delivery_sale(client, business_id, headers)

        listed = await client.get(
            f"/api/v1/businesses/{business_id}/sales?order_type=delivery",
            headers=headers,
        )
        assert listed.status_code == 200
        assert listed.json()["total"] == 1

        dine_in = await client.get(
            f"/api/v1/businesses/{business_id}/sales?order_type=dine_in",
            headers=headers,
        )
        assert dine_in.status_code == 200
        assert dine_in.json()["total"] == 0

    async def test_delivery_status_on_non_delivery_sale_returns_409(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        from datetime import UTC as _UTC
        from datetime import datetime as _dt

        business_id = uuid4()
        headers = _auth_header(business_id=business_id)
        resp = await client.post(
            SALE_SYNC_URL.format(business_id=business_id),
            json={
                "sales": [
                    {
                        "client_sale_id": str(uuid4()),
                        "status": "completed",
                        "store_id": str(uuid4()),
                        "line_items": [
                            {
                                "item_id": str(uuid4()),
                                "quantity": "1",
                                "unit_price": "10.00",
                            }
                        ],
                        "discount_amount": "0",
                        "payment_method": "cash",
                        "occurred_at": _dt.now(_UTC).isoformat(),
                    }
                ]
            },
            headers=headers,
        )
        assert resp.json()["results"][0]["status"] == "created"
        sale = (await db_session.exec(select(Sale).where(Sale.business_id == business_id))).one()

        bad = await client.patch(
            DELIVERY_STATUS_URL.format(business_id=business_id, sale_id=sale.id),
            json={"delivery_status": "assigned"},
            headers=headers,
        )
        assert bad.status_code == 409
