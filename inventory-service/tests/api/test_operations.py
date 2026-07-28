"""Integration tests for manual operation endpoints (Stage 6).

Tests the HTTP layer — adjust, waste, and transfer endpoints — through
the full auth + permission stack with a real Postgres-backed session.
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
from app.models.inventory import (
    Item,
    ItemType,
    MovementType,
    StockLevel,
    StockMovement,
    UnitOfMeasure,
)

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


def _build_token(*, permissions: list[str] | None = None) -> str:
    settings = get_settings()
    now = datetime.now(UTC)
    payload = {
        "sub": "user-test-123",
        "type": "access",
        "user_category": "business_user",
        "iat": now,
        "exp": now + timedelta(minutes=15),
        "permissions": permissions or ["inventory.view", "inventory.adjust"],
        "active_business_id": "00000000-0000-0000-0000-000000000001",
    }
    return jwt.encode(payload, TEST_PRIVATE_KEY, algorithm=settings.jwt_algorithm)


BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000001")
LOCATION_ID = UUID("00000000-0000-0000-0000-000000000010")
LOCATION_ID_2 = UUID("00000000-0000-0000-0000-000000000020")
AUTH_HEADER = {"Authorization": f"Bearer {_build_token()}"}
API_PREFIX = f"/api/v1/businesses/{BUSINESS_ID}/items"


def _auth_header(permissions: list[str] | None = None) -> dict[str, str]:
    return {"Authorization": f"Bearer {_build_token(permissions=permissions)}"}


async def _create_item(
    session: AsyncSession,
    name: str = "Test Item",
    location_id: UUID = LOCATION_ID,
    item_type: ItemType = ItemType.BOTH,
    allow_negative_stock: bool = False,
    reorder_threshold: Decimal = Decimal("10.000"),
) -> Item:
    item = Item(
        business_id=BUSINESS_ID,
        business_location_id=location_id,
        name=name,
        unit_of_measure=UnitOfMeasure.KG,
        category="test",
        reorder_threshold=reorder_threshold,
        reorder_quantity=Decimal("20.000"),
        allow_negative_stock=allow_negative_stock,
        item_type=item_type,
    )
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


async def _create_stock_level(
    session: AsyncSession,
    item_id: UUID,
    location_id: UUID = LOCATION_ID,
    quantity: Decimal = Decimal("10.000"),
) -> StockLevel:
    sl = StockLevel(
        item_id=item_id,
        business_location_id=location_id,
        current_quantity=quantity,
    )
    session.add(sl)
    await session.commit()
    await session.refresh(sl)
    return sl


# ── Adjust Stock ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_adjust_stock_increases_quantity(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)
    await _create_stock_level(db_session, item_id=item.id, quantity=Decimal("10.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/adjust",
        json={"quantity_delta": 5.0, "reason": "Found extra stock in backroom"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["item_id"] == str(item.id)
    assert data["movement_type"] == "manual_adjustment"
    assert data["quantity_delta"] == "5.000"

    result = await db_session.exec(
        select(StockLevel).where(StockLevel.item_id == item.id)
    )
    sl = result.one()
    assert sl.current_quantity == Decimal("15.000")


@pytest.mark.asyncio
async def test_adjust_stock_decreases_quantity(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)
    await _create_stock_level(db_session, item_id=item.id, quantity=Decimal("10.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/adjust",
        json={"quantity_delta": -3.0, "reason": "Count correction"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["quantity_delta"] == "-3.000"

    result = await db_session.exec(
        select(StockLevel).where(StockLevel.item_id == item.id)
    )
    sl = result.one()
    assert sl.current_quantity == Decimal("7.000")


@pytest.mark.asyncio
async def test_adjust_stock_insufficient_raises_409(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session, allow_negative_stock=False)
    await _create_stock_level(db_session, item_id=item.id, quantity=Decimal("2.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/adjust",
        json={"quantity_delta": -5.0, "reason": "Trying to go negative"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409, resp.text


@pytest.mark.asyncio
async def test_adjust_stock_no_permission_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)

    restricted = _auth_header(permissions=["inventory.view"])
    resp = await client.post(
        f"{API_PREFIX}/{item.id}/adjust",
        json={"quantity_delta": 1.0, "reason": "Should not work"},
        headers=restricted,
    )
    assert resp.status_code == 403


# ── Waste ─────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_record_waste_decreases_quantity(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)
    await _create_stock_level(db_session, item_id=item.id, quantity=Decimal("10.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/waste",
        json={"quantity": 3.0, "reason": "Spoiled produce"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["movement_type"] == "waste"
    assert data["quantity_delta"] == "-3.000"

    result = await db_session.exec(
        select(StockLevel).where(StockLevel.item_id == item.id)
    )
    sl = result.one()
    assert sl.current_quantity == Decimal("7.000")


@pytest.mark.asyncio
async def test_record_waste_zero_quantity_rejected(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/waste",
        json={"quantity": 0, "reason": "Zero waste"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422, resp.text


@pytest.mark.asyncio
async def test_record_waste_insufficient_raises_409(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session, allow_negative_stock=False)
    await _create_stock_level(db_session, item_id=item.id, quantity=Decimal("1.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/waste",
        json={"quantity": 5.0, "reason": "Mass spoilage"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409, resp.text


# ── Transfer ───────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_transfer_moves_stock_between_locations(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session, name="Transferable Item", location_id=LOCATION_ID)
    await _create_stock_level(db_session, item_id=item.id, location_id=LOCATION_ID, quantity=Decimal("10.000"))
    await _create_stock_level(db_session, item_id=item.id, location_id=LOCATION_ID_2, quantity=Decimal("0.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/transfer",
        json={
            "item_id": str(item.id),
            "source_location_id": str(LOCATION_ID),
            "destination_location_id": str(LOCATION_ID_2),
            "quantity": 4.0,
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["movement_type"] == "transfer_out"
    assert data["quantity_delta"] == "-4.000"

    result = await db_session.exec(
        select(StockLevel).where(
            StockLevel.item_id == item.id,
            StockLevel.business_location_id == LOCATION_ID,
        )
    )
    sl_src = result.one()
    assert sl_src.current_quantity == Decimal("6.000")

    result = await db_session.exec(
        select(StockLevel).where(
            StockLevel.item_id == item.id,
            StockLevel.business_location_id == LOCATION_ID_2,
        )
    )
    sl_dst = result.one()
    assert sl_dst.current_quantity == Decimal("4.000")

    # Verify both movements recorded
    result = await db_session.exec(
        select(StockMovement).where(StockMovement.item_id == item.id)
    )
    movements = list(result.all())
    assert len(movements) == 2
    movement_types = {m.movement_type for m in movements}
    assert movement_types == {MovementType.TRANSFER_OUT, MovementType.TRANSFER_IN}


@pytest.mark.asyncio
async def test_transfer_insufficient_stock_raises_409(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session, allow_negative_stock=False)
    await _create_stock_level(db_session, item_id=item.id, location_id=LOCATION_ID, quantity=Decimal("1.000"))
    await _create_stock_level(db_session, item_id=item.id, location_id=LOCATION_ID_2, quantity=Decimal("0.000"))

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/transfer",
        json={
            "item_id": str(item.id),
            "source_location_id": str(LOCATION_ID),
            "destination_location_id": str(LOCATION_ID_2),
            "quantity": 5.0,
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409, resp.text

    # Verify no movements committed (rolled back)
    result = await db_session.exec(
        select(StockMovement).where(StockMovement.item_id == item.id)
    )
    assert list(result.all()) == []


@pytest.mark.asyncio
async def test_transfer_same_location_rejected(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/transfer",
        json={
            "item_id": str(item.id),
            "source_location_id": str(LOCATION_ID),
            "destination_location_id": str(LOCATION_ID),
            "quantity": 1.0,
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422, resp.text


@pytest.mark.asyncio
async def test_transfer_item_id_mismatch_rejected(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)
    other_id = UUID("ffffffff-ffff-ffff-ffff-ffffffffffff")

    resp = await client.post(
        f"{API_PREFIX}/{item.id}/transfer",
        json={
            "item_id": str(other_id),
            "source_location_id": str(LOCATION_ID),
            "destination_location_id": str(LOCATION_ID_2),
            "quantity": 1.0,
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422, resp.text


@pytest.mark.asyncio
async def test_transfer_no_permission_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    item = await _create_item(db_session)

    restricted = _auth_header(permissions=["inventory.view"])
    resp = await client.post(
        f"{API_PREFIX}/{item.id}/transfer",
        json={
            "item_id": str(item.id),
            "source_location_id": str(LOCATION_ID),
            "destination_location_id": str(LOCATION_ID_2),
            "quantity": 1.0,
        },
        headers=restricted,
    )
    assert resp.status_code == 403, resp.text