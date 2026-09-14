"""Integration tests for production endpoints (Stage 2).

Real Postgres (built by the real Alembic chain, including the production
migration), real row locks, signed JWTs — including a true concurrency
test with two overlapping productions racing the same ingredients.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID

import jwt
import pytest
from httpx import AsyncClient
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.permission_codes import PermissionCode
from app.models.inventory import (
    Item,
    ItemType,
    ProductionEvent,
    StockLevel,
    StockMovement,
)
from app.models.units import Unit
from app.services.stock_movement_service import MovementType, record_movement

# ── Test RSA keypair (byte-identical to tests/api/test_items.py) ──────────
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

ALL_PERMS = [
    "recipes.view",
    "recipes.create",
    "recipes.update",
    "recipes.delete",
    "production.create",
    "production.view",
    "inventory.view",
    "inventory.items.create",
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
        # NB: `is not None`, not `or` — an explicit empty list means "no
        # permissions" (the RBAC negative case), not "use the default set".
        "permissions": permissions
        if permissions is not None
        else list(ALL_PERMS),
        "active_business_id": active_business_id,
    }
    return jwt.encode(payload, TEST_PRIVATE_KEY, algorithm=settings.jwt_algorithm)


BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000001")
STORE_ID = UUID("00000000-0000-0000-0000-000000000010")
AUTH_HEADER = {"Authorization": f"Bearer {_build_token()}"}
RECIPES_PREFIX = f"/api/v1/businesses/{BUSINESS_ID}/recipes"
HISTORY_PREFIX = f"/api/v1/businesses/{BUSINESS_ID}/production-events"


def _auth_header(*codes: str) -> dict[str, str]:
    """Token carrying exactly *codes* (for RBAC negative tests)."""
    return {"Authorization": f"Bearer {_build_token(permissions=list(codes))}"}


async def _kg_unit_id(session: AsyncSession) -> UUID:
    result = await session.exec(select(Unit).where(Unit.code == "kg"))
    return result.one().id


async def _create_test_item(
    session: AsyncSession,
    name: str,
    item_type: ItemType,
) -> Item:
    item = Item(
        business_id=BUSINESS_ID,
        store_id=STORE_ID,
        name=name,
        unit_id=await _kg_unit_id(session),
        reorder_threshold=Decimal("10.000"),
        reorder_quantity=Decimal("20.000"),
        item_type=item_type,
    )
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


async def _set_stock(
    session: AsyncSession, item_id: UUID, quantity: str
) -> StockLevel:
    sl = StockLevel(
        item_id=item_id, store_id=STORE_ID, current_quantity=Decimal(quantity)
    )
    session.add(sl)
    await session.commit()
    await session.refresh(sl)
    return sl


async def _level(session: AsyncSession, item_id: UUID) -> Decimal:
    result = await session.exec(
        select(StockLevel).where(
            StockLevel.item_id == item_id, StockLevel.store_id == STORE_ID
        )
    )
    row = result.one_or_none()
    return row.current_quantity if row else Decimal("0.000")


async def _make_pilau_kitchen(
    client: AsyncClient, db_session: AsyncSession
) -> tuple[Item, Item, Item, Item, UUID]:
    """Sellable Pilau + raw Rice/Meat/Oil, stocked, with a recipe.

    Recipe (per plate): Rice 0.200, Meat 0.100, Oil 0.020.
    Returns (pilau, rice, meat, oil, recipe_id).
    """
    pilau = await _create_test_item(db_session, "Pilau", ItemType.SELLABLE)
    rice = await _create_test_item(db_session, "Rice", ItemType.RAW_MATERIAL)
    meat = await _create_test_item(db_session, "Meat", ItemType.RAW_MATERIAL)
    oil = await _create_test_item(db_session, "Oil", ItemType.RAW_MATERIAL)
    await _set_stock(db_session, rice.id, "10.000")
    await _set_stock(db_session, meat.id, "10.000")
    await _set_stock(db_session, oil.id, "10.000")
    await _set_stock(db_session, pilau.id, "0.000")

    resp = await client.post(
        RECIPES_PREFIX,
        json={
            "sellable_item_id": str(pilau.id),
            "name": "Pilau",
            "components": [
                {"raw_material_item_id": str(rice.id), "quantity_required": "0.200"},
                {"raw_material_item_id": str(meat.id), "quantity_required": "0.100"},
                {"raw_material_item_id": str(oil.id), "quantity_required": "0.020"},
            ],
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    return pilau, rice, meat, oil, UUID(resp.json()["id"])


def _produce_url(recipe_id: UUID) -> str:
    return f"{RECIPES_PREFIX}/{recipe_id}/produce"


# ── Tests ────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_produce_consumes_every_ingredient_by_ratio(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """2kg rice ÷ 0.2kg/plate = 10 plates; meat/oil follow the same ratio."""
    pilau, rice, meat, oil, recipe_id = await _make_pilau_kitchen(client, db_session)

    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "2.000",
            "actual_output_quantity": "10.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["suggested_output_quantity"] == "10.000"
    assert data["actual_output_quantity"] == "10.000"
    assert data["sellable_item_name"] == "Pilau"
    by_name = {c["raw_material_name"]: c for c in data["components"]}
    # Leading row is the measured value exactly; others are ratio-computed.
    assert by_name["Rice"]["quantity_consumed"] == "2.000"
    assert by_name["Meat"]["quantity_consumed"] == "1.000"
    assert by_name["Oil"]["quantity_consumed"] == "0.200"
    assert by_name["Rice"]["raw_material_unit"] == "kg"

    async with db_session as s:
        assert await _level(s, rice.id) == Decimal("8.000")
        assert await _level(s, meat.id) == Decimal("9.000")
        assert await _level(s, oil.id) == Decimal("9.800")
        assert await _level(s, pilau.id) == Decimal("10.000")

        movements = (
            await s.exec(
                select(StockMovement).where(
                    StockMovement.business_id == BUSINESS_ID
                )
            )
        ).all()
        inputs = [m for m in movements if m.movement_type == MovementType.PRODUCTION_INPUT]
        outputs = [m for m in movements if m.movement_type == MovementType.PRODUCTION_OUTPUT]
        assert len(inputs) == 3
        assert len(outputs) == 1
        assert outputs[0].quantity_delta == Decimal("10.000")
        assert outputs[0].reference_type == "production_event"
        assert str(outputs[0].reference_id) == data["id"]


@pytest.mark.asyncio
async def test_actual_output_differs_from_suggested(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Big portions: suggested 10, confirmed 8 — sellable gains 8, both kept."""
    pilau, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)

    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "2.000",
            "actual_output_quantity": "8.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["suggested_output_quantity"] == "10.000"
    assert data["actual_output_quantity"] == "8.000"

    async with db_session as s:
        assert await _level(s, pilau.id) == Decimal("8.000")


@pytest.mark.asyncio
async def test_actual_output_defaults_to_suggested(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Omitting actual_output_quantity commits the suggestion."""
    pilau, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)

    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "2.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["actual_output_quantity"] == data["suggested_output_quantity"] == "10.000"

    async with db_session as s:
        assert await _level(s, pilau.id) == Decimal("10.000")


@pytest.mark.asyncio
async def test_insufficient_non_leading_ingredient_rolls_back_entirely(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Plenty of rice but not enough meat → 409 AND zero side effects.

    The direct movement query is the point: not even rice's leg may exist.
    """
    pilau, rice, meat, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    async with db_session as s:
        row = (
            await s.exec(
                select(StockLevel).where(
                    StockLevel.item_id == meat.id, StockLevel.store_id == STORE_ID
                )
            )
        ).one()
        row.current_quantity = Decimal("0.050")
        s.add(row)
        await s.commit()

    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "2.000",
            "actual_output_quantity": "10.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 409, resp.text

    async with db_session as s:
        # No movements at all for this business — full rollback, not partial.
        movements = (
            await s.exec(
                select(StockMovement).where(
                    StockMovement.business_id == BUSINESS_ID
                )
            )
        ).all()
        assert movements == []
        # Untouched levels, and no production event row either.
        assert await _level(s, rice.id) == Decimal("10.000")
        assert await _level(s, meat.id) == Decimal("0.050")
        assert await _level(s, pilau.id) == Decimal("0.000")
        events = (
            await s.exec(
                select(ProductionEvent).where(
                    ProductionEvent.business_id == BUSINESS_ID
                )
            )
        ).all()
        assert events == []


@pytest.mark.asyncio
async def test_concurrent_productions_no_deadlock_no_lost_update(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Two overlapping productions race the same meat: one wins, one 409s.

    Meat covers exactly one run; rice covers both. Sorted-order locking
    must serialize (not deadlock) them, and the loser must see the
    winner's deduction — no lost update. The wait_for turns a deadlock
    into a loud failure instead of a hung suite.
    """
    pilau, rice, meat, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    async with db_session as s:
        row = (
            await s.exec(
                select(StockLevel).where(
                    StockLevel.item_id == meat.id, StockLevel.store_id == STORE_ID
                )
            )
        ).one()
        row.current_quantity = Decimal("1.000")
        s.add(row)
        await s.commit()

    payload = {
        "leading_item_id": str(rice.id),
        "leading_quantity_used": "2.000",
        "actual_output_quantity": "10.000",
    }

    async def _run() -> int:
        resp = await client.post(
            _produce_url(recipe_id), json=payload, headers=AUTH_HEADER
        )
        return resp.status_code

    first, second = await asyncio.wait_for(
        asyncio.gather(_run(), _run()), timeout=30
    )
    assert sorted([first, second]) == [201, 409]

    async with db_session as s:
        assert await _level(s, meat.id) == Decimal("0.000")
        assert await _level(s, rice.id) == Decimal("8.000")
        assert await _level(s, pilau.id) == Decimal("10.000")


@pytest.mark.asyncio
async def test_production_movements_exempt_from_sale_purchase_rules(
    db_session: AsyncSession,
) -> None:
    """production_input/output skip the sale/purchase item_type restrictions.

    A production_input on a sellable-only item and a production_output on a
    raw-only item both succeed — the same calls with sale/purchase types
    would raise ItemTypeMismatchError (covered by existing engine tests).
    """
    sellable = await _create_test_item(db_session, "Cake", ItemType.SELLABLE)
    raw = await _create_test_item(db_session, "Flour", ItemType.RAW_MATERIAL)
    await _set_stock(db_session, sellable.id, "5.000")
    await _set_stock(db_session, raw.id, "5.000")

    async with db_session as s:
        await record_movement(
            db=s,
            item_id=sellable.id,
            business_id=BUSINESS_ID,
            store_id=STORE_ID,
            quantity_delta=Decimal("-1.000"),
            movement_type=MovementType.PRODUCTION_INPUT,
        )
        await record_movement(
            db=s,
            item_id=raw.id,
            business_id=BUSINESS_ID,
            store_id=STORE_ID,
            quantity_delta=Decimal("1.000"),
            movement_type=MovementType.PRODUCTION_OUTPUT,
        )


@pytest.mark.asyncio
async def test_production_publishes_events_with_payloads(
    client: AsyncClient, db_session: AsyncSession, monkeypatch: pytest.MonkeyPatch
) -> None:
    """production.recorded + audit.recorded carry suggested-vs-actual detail."""
    import app.services.production_service as production_service

    seen: list[tuple[str, dict]] = []

    async def _recorder(event_name: str, payload: dict) -> None:
        seen.append((event_name, payload))

    monkeypatch.setattr(production_service, "publish_event", _recorder)

    _, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "2.000",
            "actual_output_quantity": "8.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text
    event_id = resp.json()["id"]

    by_name = {name: payload for name, payload in seen}
    assert by_name["production.recorded"]["event_id"] == event_id
    assert by_name["production.recorded"]["recipe_id"] == str(recipe_id)
    assert by_name["production.recorded"]["suggested_output_quantity"] == "10.000"
    assert by_name["production.recorded"]["actual_output_quantity"] == "8.000"
    assert by_name["audit.recorded"]["action"] == "production.recorded"
    assert by_name["audit.recorded"]["resource_type"] == "production_event"
    assert by_name["audit.recorded"]["resource_id"] == event_id
    assert by_name["audit.recorded"]["details"]["suggested_output_quantity"] == "10.000"


@pytest.mark.asyncio
async def test_leading_ingredient_outside_recipe_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Measuring an item that is not on the recipe → 422."""
    _, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    sugar = await _create_test_item(db_session, "Sugar", ItemType.RAW_MATERIAL)

    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(sugar.id),
            "leading_quantity_used": "1.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422, resp.text
    assert str(rice.id) not in resp.text  # no leakage, just the rejection


@pytest.mark.asyncio
async def test_zero_leading_quantity_rejected(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """Zero/negative measured quantities never reach the ratio math (422)."""
    _, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "0.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 422, resp.text


@pytest.mark.asyncio
async def test_recipe_delete_blocked_with_production_history(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """A produced recipe cannot be deleted out from under its records (409)."""
    _, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    resp = await client.post(
        _produce_url(recipe_id),
        json={
            "leading_item_id": str(rice.id),
            "leading_quantity_used": "2.000",
        },
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 201, resp.text

    resp = await client.delete(
        f"{RECIPES_PREFIX}/{recipe_id}", headers=AUTH_HEADER
    )
    assert resp.status_code == 409, resp.text
    assert "production events" in resp.json()["detail"]

    resp = await client.get(f"{RECIPES_PREFIX}/{recipe_id}", headers=AUTH_HEADER)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_production_history_list_detail_and_filters(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    """History lists newest-first, filters by date, resolves detail."""
    _, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    first_id: str | None = None
    for qty in ("1.000", "2.000"):
        resp = await client.post(
            _produce_url(recipe_id),
            json={
                "leading_item_id": str(rice.id),
                "leading_quantity_used": qty,
            },
            headers=AUTH_HEADER,
        )
        assert resp.status_code == 201, resp.text
        first_id = first_id or resp.json()["id"]

    resp = await client.get(HISTORY_PREFIX, headers=AUTH_HEADER)
    assert resp.status_code == 200, resp.text
    listed = resp.json()
    assert len(listed) == 2
    assert listed[0]["leading_quantity_used"] == "2.000"

    today = datetime.now(UTC).date().isoformat()
    resp = await client.get(
        HISTORY_PREFIX, params={"from": today, "to": today}, headers=AUTH_HEADER
    )
    assert resp.status_code == 200, resp.text
    assert len(resp.json()) == 2

    resp = await client.get(
        HISTORY_PREFIX, params={"from": "2000-01-01", "to": "2000-01-02"},
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 200, resp.text
    assert resp.json() == []

    assert first_id is not None
    resp = await client.get(f"{HISTORY_PREFIX}/{first_id}", headers=AUTH_HEADER)
    assert resp.status_code == 200, resp.text
    assert resp.json()["leading_quantity_used"] == "1.000"

    resp = await client.get(
        f"{HISTORY_PREFIX}/00000000-0000-0000-0000-000000000099",
        headers=AUTH_HEADER,
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_production_rbac(client: AsyncClient, db_session: AsyncSession) -> None:
    """PRODUCTION_CREATE/VIEW gate their endpoints; others get 403."""
    _, rice, _, _, recipe_id = await _make_pilau_kitchen(client, db_session)
    payload = {
        "leading_item_id": str(rice.id),
        "leading_quantity_used": "1.000",
    }

    resp = await client.post(
        _produce_url(recipe_id), json=payload, headers=_auth_header()
    )
    assert resp.status_code == 403, resp.text
    resp = await client.post(
        _produce_url(recipe_id), json=payload, headers=_auth_header("recipes.view")
    )
    assert resp.status_code == 403, resp.text
    resp = await client.post(
        _produce_url(recipe_id),
        json=payload,
        headers=_auth_header("production.create"),
    )
    assert resp.status_code == 201, resp.text
    event_id = resp.json()["id"]

    resp = await client.get(HISTORY_PREFIX, headers=_auth_header())
    assert resp.status_code == 403, resp.text
    resp = await client.get(
        HISTORY_PREFIX, headers=_auth_header("production.view")
    )
    assert resp.status_code == 200, resp.text

    resp = await client.get(
        f"{HISTORY_PREFIX}/{event_id}", headers=_auth_header("production.create")
    )
    assert resp.status_code == 403, resp.text


def test_production_permission_codes_registered() -> None:
    """The two production codes exist in this service's PermissionCode copy."""
    assert PermissionCode.PRODUCTION_CREATE.value == "production.create"
    assert PermissionCode.PRODUCTION_VIEW.value == "production.view"
