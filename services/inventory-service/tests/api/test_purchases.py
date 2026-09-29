"""Integration tests for the purchases module endpoints.

Covers the full lifecycle: draft PO → submit → approve → partial GRN →
full GRN (asserts the stock engine ran + weighted-average costing), returns,
invoices/payments, supplier statement, status-transition guards, and route
permissions. Mirrors ``test_reorders.py``'s shape.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID

import jwt
import pytest
from httpx import AsyncClient
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.models.inventory import Item, ItemType, StockLevel, StockMovement
from app.models.suppliers import Supplier
from app.models.units import Unit

# ── Test RSA keypair (copied from test_reorders.py) ──────────────────────
TEST_PRIVATE_KEY = """-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAoeArXtZ+XrZt5klLXLayTcGOFZCOUZ9tbexpmrdMcXzwxAzx
h+ByKOHyJEJ1xXB6hdZZMWV/66rHMG+dx3l8w8o3woM1Ae/QEz7Yf8Zx1Eu3eqCR
E05QzX0c1SfSxrzNQ91czCIRW3vyq2CQ/dnD3xqFP7asLrfihqYzw2SzSNyoOJo3
EAYwv2IdkJJeQepco+WX5OjZBrYOB9YFXySmo32cT7uT6eIIo1CJFYqCvfK6OeAw
oQy92wOJxod1VcPYRBbFU86bTnge2+ymbjpnnMDUUyF5pl+05raXwrg3pz8ibXjs
V+9aGx1Qs1pAd0IMB6b9JegMcRy3SCdUgvcz/wIDAQABAoIBADEbusyYsdm16n1U
ewJzgoBIWfx80FA+14njkN4ZAZ3kU36GlresBbYVZcpOR0BQsTrtHj34Fui99JPj
KLCdUJZtQKFIAMrHoA5WoIOTBnFrTwxqrdh3h9fvPtIDtNQJ7xPJkh9zrmRco/AN
6a65Y8zJVOdRWccKjjRfM5Dxedp+axsPkLTXJvh/tioGDTzsFTSshMIdOSElH8e4
VZQPx+nB50yRRu/ek3AjrdELppQ8OziNBvl455g9pg8XOuclEG3JuZoZU/s22sYi
oORswvTGrceuzWSdosh6hwMWW8D07BOkLaIMAWpiL0TpCqWW3ABamj6MmZJRHDKL
Rxr8vkECgYEAzosvjW5A5JGTh9XmxMbi2GifN95cm7Lb8IZAdvI/370eVGIxzIHi
eduiHw0pXNcEnTS5uT0fbt/2AvfN8bvoOrfdAnjLSlbgzLFbx544Mtekert6hyGA
ISiB79J6dgdHxa1hWRiQ+Tn+71t+9Afry5TWA/JmqIcFTBLhIJ/WgzECgYEAyKLm
tnN/DHkfYsuWKF2T8LBfXJ5AsXAznfjDP9NKpuVr9ouy/QhjOgVriXdtvt67B00Z
FNtkS2LrjlFLz5cTvABW0TOdB09EA3s6iWE6bjp+Jg7gSHXzIW29YS1VOzVlYxP9
FfYigxlDVrgjnZ9lefZz0iwT+ACDPErjCVdzfi8CgYB6xAxNulzj/wt7z85M5BJt
ozIQGSFegl9shb/Hc5I3wMdITN1gu0sMN1oTrtUJE9zwPCiwS/5k/sXRWc2Vg6Uz
UZoSIA5lb2JLCJiO/CJXRgnD0a+wpl7sVpF1JNwZT5Z/juCv/oQdPzWiu/WnwxWK
ejsDOY9/WFHzt70MkTUF4QKBgQCK5lQo/b54KSZ0ZBNZcKdp2wC6Awkwjkf91ml9
t06YSn462i4ZBQSE95miOp8so9ABVvvFN7mwgxQmm9uLJMFRxz5TaJMOq26fpmE5
GKm2BCKvQF8/awDeJLYWH6dA7U96jy0IVjVAY23+DE8D4YUEMX2vhDpy2BAC3qld
H0DimwKBgG3GWjH5G4uYQ5x/LKX5mSO5vGANRM0n3CVfXtyEDURuo8hQQFbSUyH/
ac/0/f9oHqk1dBBfGYF9eNr6iSo3qgGYmlnavwSeOoemgHwfF9oCULVUPPwldMVD
Miohh2E1Z9T1bGnvke8mHGpvQ4WurtmexOjz+KzVooCAkKzxIYKf
-----END RSA PRIVATE KEY-----
"""

ALL_PURCHASE_PERMS = [
    "procurement.create",
    "procurement.approve",
    "procurement.view",
    "procurement.receive",
]


def _build_token(
    *,
    permissions: list[str] | None = None,
    active_business_id: str = "00000000-0000-0000-0000-000000000001",
) -> str:
    settings = get_settings()
    now = datetime.now(UTC)
    payload = {
        "sub": "user-test-123",
        "type": "access",
        "user_category": "business_staff",
        "iat": now,
        "exp": now + timedelta(minutes=15),
        "permissions": permissions if permissions is not None else ALL_PURCHASE_PERMS,
        "active_business_id": active_business_id,
    }
    return jwt.encode(payload, TEST_PRIVATE_KEY, algorithm=settings.jwt_algorithm)


BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000001")
STORE_ID = UUID("00000000-0000-0000-0000-000000000010")
AUTH_HEADER = {"Authorization": f"Bearer {_build_token()}"}
API_PREFIX = f"/api/v1/businesses/{BUSINESS_ID}/purchases"


def _auth_header(permissions: list[str] | None = None) -> dict[str, str]:
    return {"Authorization": f"Bearer {_build_token(permissions=permissions)}"}


async def _unit_id(session: AsyncSession, code: str = "kg") -> UUID:
    result = await session.exec(select(Unit).where(Unit.code == code))
    return result.one().id


async def _create_item(
    session: AsyncSession,
    name: str = "Flour",
    item_type: ItemType = ItemType.RAW_MATERIAL,
    unit_cost: Decimal | None = None,
) -> Item:
    item = Item(
        business_id=BUSINESS_ID,
        store_id=STORE_ID,
        name=name,
        unit_id=await _unit_id(session),
        reorder_threshold=Decimal("10.000"),
        reorder_quantity=Decimal("50.000"),
        item_type=item_type,
        unit_cost=unit_cost,
    )
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


async def _create_supplier(session: AsyncSession, name: str = "Acme Produce") -> Supplier:
    supplier = Supplier(business_id=BUSINESS_ID, name=name)
    session.add(supplier)
    await session.commit()
    await session.refresh(supplier)
    return supplier


def _order_payload(
    item: Item, supplier: Supplier, second_item: Item | None = None, **overrides
) -> dict:
    lines = [
        {
            "item_id": str(item.id),
            "quantity_ordered": "20.000",
            "unit_cost": "2.5000",
        }
    ]
    if second_item is not None:
        lines.append(
            {
                "item_id": str(second_item.id),
                "quantity_ordered": "10.000",
                "unit_cost": "5.0000",
            }
        )
    payload = {
        "store_id": str(STORE_ID),
        "supplier_id": str(supplier.id),
        "lines": lines,
    }
    payload.update(overrides)
    return payload


async def _create_approved_order(
    client: AsyncClient,
    item: Item,
    supplier: Supplier,
    second_item: Item | None = None,
) -> dict:
    """Drive a PO through draft → submitted → approved via the API."""
    resp = await client.post(
        f"{API_PREFIX}/orders",
        json=_order_payload(item, supplier, second_item),
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    order = resp.json()
    for action in ("submit", "approve"):
        resp = await client.post(
            f"{API_PREFIX}/orders/{order['id']}/{action}", headers=AUTH_HEADER
        )
        assert resp.status_code == 200, resp.text
    return resp.json()


async def _stock_level(session: AsyncSession, item: Item) -> Decimal:
    level = (
        await session.exec(
            select(StockLevel).where(
                StockLevel.item_id == item.id, StockLevel.store_id == STORE_ID
            )
        )
    ).one_or_none()
    return level.current_quantity if level else Decimal("0.000")


# ── Create ───────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_create_multi_line_order(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    second = await _create_item(db_session, name="Sugar")
    supplier = await _create_supplier(db_session)

    resp = await client.post(
        f"{API_PREFIX}/orders",
        json=_order_payload(item, supplier, second),
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["status"] == "draft"
    assert data["po_number"].startswith("PO-")
    # 20*2.5 + 10*5.0 = 100.00
    assert Decimal(data["total_amount"]) == Decimal("100.00")

    detail = (
        await client.get(f"{API_PREFIX}/orders/{data['id']}", headers=AUTH_HEADER)
    ).json()
    assert len(detail["lines"]) == 2
    assert {line["unit"] for line in detail["lines"]} == {"kg"}


@pytest.mark.asyncio
async def test_create_order_sellable_item_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session, item_type=ItemType.SELLABLE)
    supplier = await _create_supplier(db_session)

    resp = await client.post(
        f"{API_PREFIX}/orders",
        json=_order_payload(item, supplier),
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422
    assert "sellable" in resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_create_order_duplicate_and_empty_lines_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)

    dup = _order_payload(item, supplier)
    dup["lines"] = [dup["lines"][0], dup["lines"][0]]
    resp = await client.post(
        f"{API_PREFIX}/orders", json=dup, headers=AUTH_HEADER
    )
    assert resp.status_code == 422

    empty = _order_payload(item, supplier, lines=[])
    resp = await client.post(
        f"{API_PREFIX}/orders", json=empty, headers=AUTH_HEADER
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_create_order_unknown_supplier_404s(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    payload = _order_payload(
        item, supplier, supplier_id="00000000-0000-0000-0000-000000000404"
    )
    resp = await client.post(
        f"{API_PREFIX}/orders", json=payload, headers=AUTH_HEADER
    )
    assert resp.status_code == 404


# ── Lifecycle guards ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_submit_approve_and_double_transition_guards(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    order = (
        await client.post(
            f"{API_PREFIX}/orders",
            json=_order_payload(item, supplier),
            headers=AUTH_HEADER,
        )
    ).json()

    # Approve before submit is rejected.
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/approve", headers=AUTH_HEADER
    )
    assert resp.status_code == 409

    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/submit", headers=AUTH_HEADER
    )
    assert resp.json()["status"] == "submitted"

    # Double submit is rejected.
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/submit", headers=AUTH_HEADER
    )
    assert resp.status_code == 409

    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/approve", headers=AUTH_HEADER
    )
    assert resp.json()["status"] == "approved"


@pytest.mark.asyncio
async def test_receive_before_approval_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    order = (
        await client.post(
            f"{API_PREFIX}/orders",
            json=_order_payload(item, supplier),
            headers=AUTH_HEADER,
        )
    ).json()
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]

    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "5.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409


# ── Receiving (core: stock + costing) ──────────────────────────────────────


@pytest.mark.asyncio
async def test_partial_then_full_receive_updates_stock_and_cost(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session, unit_cost=Decimal("2.0000"))
    supplier = await _create_supplier(db_session)
    order = await _create_approved_order(client, item, supplier)
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]

    # Partial: 8 of 20 @ 2.5000 over opening 0 @ 2.0000 → avg 2.5000.
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "8.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["grn_number"].startswith("GRN-")

    detail = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()
    assert detail["status"] == "partially_received"
    assert Decimal(detail["lines"][0]["quantity_received"]) == Decimal("8.000")
    assert await _stock_level(db_session, item) == Decimal("8.000")

    # Remainder: 12 @ 2.5000 over 8 @ 2.5000 → avg stays 2.5000.
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "12.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text

    detail = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()
    assert detail["status"] == "received"
    assert len(detail["receipts"]) == 2
    assert await _stock_level(db_session, item) == Decimal("20.000")

    await db_session.refresh(item)
    assert item.unit_cost == Decimal("2.5000")

    movements = (
        await db_session.exec(
            select(StockMovement).where(StockMovement.item_id == item.id)
        )
    ).all()
    assert len(movements) == 2
    assert all(m.reference_type == "goods_receipt" for m in movements)


@pytest.mark.asyncio
async def test_weighted_average_cost_blends_with_existing_stock(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    # Opening 10 @ 1.0000, receive 10 @ 3.0000 → (10 + 30)/20 = 2.0000.
    item = await _create_item(db_session, unit_cost=Decimal("1.0000"))
    db_session.add(
        StockLevel(item_id=item.id, store_id=STORE_ID, current_quantity=Decimal("10.000"))
    )
    await db_session.commit()
    supplier = await _create_supplier(db_session)
    order = await _create_approved_order(client, item, supplier)
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]

    # Line cost is 2.5000 per payload; override expectation accordingly:
    # (10*1.0 + 10*2.5)/20 = 1.7500.
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "10.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text
    await db_session.refresh(item)
    assert item.unit_cost == Decimal("1.7500")


@pytest.mark.asyncio
async def test_over_receive_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    order = await _create_approved_order(client, item, supplier)
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]

    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "21.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409
    assert await _stock_level(db_session, item) == Decimal("0.000")


@pytest.mark.asyncio
async def test_cancel_after_receive_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    order = await _create_approved_order(client, item, supplier)
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "5.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text

    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/cancel", headers=AUTH_HEADER
    )
    assert resp.status_code == 409


# ── Returns ────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_return_decrements_stock_and_over_return_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    order = await _create_approved_order(client, item, supplier)
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "20.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text

    resp = await client.post(
        f"{API_PREFIX}/returns",
        json={
            "item_id": str(item.id),
            "quantity": "4.000",
            "purchase_order_id": order["id"],
            "reason": "damaged in transit",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    assert await _stock_level(db_session, item) == Decimal("16.000")

    # Only 16 returnable now; 17 is rejected.
    resp = await client.post(
        f"{API_PREFIX}/returns",
        json={"item_id": str(item.id), "quantity": "17.000", "purchase_order_id": order["id"]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409
    assert await _stock_level(db_session, item) == Decimal("16.000")


# ── Invoices, payments, statement ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_invoice_payment_lifecycle_and_statement(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    order = await _create_approved_order(client, item, supplier)
    line_id = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]
    resp = await client.post(
        f"{API_PREFIX}/orders/{order['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line_id, "quantity_received": "20.000"}]},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text

    # Default invoice total = received value: 20 * 2.5 = 50.00.
    resp = await client.post(
        f"{API_PREFIX}/invoices",
        json={"purchase_order_id": order["id"], "invoice_number": "SUP-001"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    invoice = resp.json()
    assert Decimal(invoice["amount_total"]) == Decimal("50.00")
    assert invoice["status"] == "unpaid"

    # Partial payment → partial; PO mirrors it.
    resp = await client.post(
        f"{API_PREFIX}/invoices/{invoice['id']}/payments",
        json={"amount": "20.00", "method": "mpesa"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text

    detail = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()
    assert detail["invoices"][0]["status"] == "partial"
    assert detail["invoice_status"] == "partial"

    # Overpay is rejected.
    resp = await client.post(
        f"{API_PREFIX}/invoices/{invoice['id']}/payments",
        json={"amount": "31.00"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422

    # Pay the rest → paid everywhere.
    resp = await client.post(
        f"{API_PREFIX}/invoices/{invoice['id']}/payments",
        json={"amount": "30.00"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    detail = (
        await client.get(f"{API_PREFIX}/orders/{order['id']}", headers=AUTH_HEADER)
    ).json()
    assert detail["invoice_status"] == "paid"

    # Statement shows the settled invoice with zero balance…
    stmt = (
        await client.get(
            f"{API_PREFIX}/suppliers/{supplier.id}/statement", headers=AUTH_HEADER
        )
    ).json()
    assert Decimal(stmt["outstanding_balance"]) == Decimal("0.00")

    # …and a second open order + unpaid invoice contribute to the balance.
    second_item = await _create_item(db_session, name="Rice")
    order2 = await _create_approved_order(client, second_item, supplier)
    line2 = (
        await client.get(f"{API_PREFIX}/orders/{order2['id']}", headers=AUTH_HEADER)
    ).json()["lines"][0]["id"]
    await client.post(
        f"{API_PREFIX}/orders/{order2['id']}/receive",
        json={"lines": [{"purchase_order_line_id": line2, "quantity_received": "10.000"}]},
        headers=AUTH_HEADER,
    )
    await client.post(
        f"{API_PREFIX}/invoices",
        json={"purchase_order_id": order2["id"], "invoice_number": "SUP-002"},
        headers=AUTH_HEADER,
    )
    stmt = (
        await client.get(
            f"{API_PREFIX}/suppliers/{supplier.id}/statement", headers=AUTH_HEADER
        )
    ).json()
    # 10 * 2.5 = 25.00 outstanding; order2 fully received so no open orders.
    assert Decimal(stmt["outstanding_balance"]) == Decimal("25.00")
    assert stmt["unpaid_invoices"][0]["invoice_number"] == "SUP-002"


# ── List & permissions ─────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_list_filters_by_status(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    await _create_approved_order(client, item, supplier)
    draft = (
        await client.post(
            f"{API_PREFIX}/orders",
            json=_order_payload(item, supplier),
            headers=AUTH_HEADER,
        )
    ).json()

    resp = await client.get(
        f"{API_PREFIX}/orders?status=draft", headers=AUTH_HEADER
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["total"] == 1
    assert body["items"][0]["id"] == draft["id"]


@pytest.mark.asyncio
async def test_missing_token_401_and_missing_permission_403(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)

    resp = await client.post(
        f"{API_PREFIX}/orders", json=_order_payload(item, supplier)
    )
    assert resp.status_code == 401

    resp = await client.post(
        f"{API_PREFIX}/orders",
        json=_order_payload(item, supplier),
        headers=_auth_header(permissions=["procurement.view"]),
    )
    assert resp.status_code == 403

    resp = await client.get(
        f"{API_PREFIX}/orders", headers=_auth_header(permissions=[])
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_cross_business_token_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """A token bound to another business cannot touch this business's POs."""
    item = await _create_item(db_session)
    supplier = await _create_supplier(db_session)
    other_id = "00000000-0000-0000-0000-000000000099"
    other_header = {"Authorization": f"Bearer {_build_token(active_business_id=other_id)}"}
    resp = await client.post(
        f"{API_PREFIX}/orders",
        json=_order_payload(item, supplier),
        headers=other_header,
    )
    assert resp.status_code == 403
