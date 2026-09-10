"""Integration tests for supplier management endpoints.

Every test uses a real Postgres-backed session and a signed JWT so that the
full auth + permission stack is exercised (mirrors ``test_items.py``).
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID

import jwt
import pytest
from httpx import AsyncClient
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.models.suppliers import Supplier

# ── Test RSA keypair (copied from test_token_verification.py) ──────────
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

ALL_SUPPLIER_PERMS = [
    "suppliers.view",
    "suppliers.create",
    "suppliers.update",
    "suppliers.delete",
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
        "permissions": permissions or ALL_SUPPLIER_PERMS,
        "active_business_id": active_business_id,
    }
    return jwt.encode(payload, TEST_PRIVATE_KEY, algorithm=settings.jwt_algorithm)


BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000001")
OTHER_BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000099")
AUTH_HEADER = {"Authorization": f"Bearer {_build_token()}"}
API_PREFIX = f"/api/v1/businesses/{BUSINESS_ID}/suppliers"


def _auth_header(permissions: list[str] | None = None) -> dict[str, str]:
    return {"Authorization": f"Bearer {_build_token(permissions=permissions)}"}


def _other_biz_header() -> dict[str, str]:
    token = _build_token(active_business_id=str(OTHER_BUSINESS_ID))
    return {"Authorization": f"Bearer {token}"}


async def _create_test_supplier(
    session: AsyncSession,
    name: str = "Acme Produce",
    business_id: UUID = BUSINESS_ID,
) -> Supplier:
    supplier = Supplier(business_id=business_id, name=name, phone="+1-555-0100")
    session.add(supplier)
    await session.commit()
    await session.refresh(supplier)
    return supplier


# ── Tests ────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_full_crud_cycle(client: AsyncClient) -> None:
    create_payload = {"name": "Acme Produce", "phone": "+1-555-0100", "email": "hi@acme.test"}
    resp = await client.post(API_PREFIX, json=create_payload, headers=AUTH_HEADER)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    supplier_id = data["id"]
    assert data["name"] == "Acme Produce"
    assert data["business_id"] == str(BUSINESS_ID)

    resp = await client.get(f"{API_PREFIX}/{supplier_id}", headers=AUTH_HEADER)
    assert resp.status_code == 200
    assert resp.json()["name"] == "Acme Produce"

    resp = await client.patch(
        f"{API_PREFIX}/{supplier_id}", json={"name": "Acme Wholesale"}, headers=AUTH_HEADER
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["name"] == "Acme Wholesale"

    resp = await client.delete(f"{API_PREFIX}/{supplier_id}", headers=AUTH_HEADER)
    assert resp.status_code == 204

    # Soft-deleted: excluded from default list, still readable by id.
    resp = await client.get(API_PREFIX, headers=AUTH_HEADER)
    assert supplier_id not in [s["id"] for s in resp.json()["items"]]

    resp = await client.get(f"{API_PREFIX}/{supplier_id}", headers=AUTH_HEADER)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_list_search_and_pagination(client: AsyncClient, db_session: AsyncSession) -> None:
    await _create_test_supplier(db_session, name="Alpha Farms")
    await _create_test_supplier(db_session, name="Beta Distributors")

    resp = await client.get(API_PREFIX, params={"search": "alpha"}, headers=AUTH_HEADER)
    assert resp.status_code == 200
    names = [s["name"] for s in resp.json()["items"]]
    assert names == ["Alpha Farms"]

    resp = await client.get(API_PREFIX, params={"limit": 1}, headers=AUTH_HEADER)
    assert resp.status_code == 200
    body = resp.json()
    assert len(body["items"]) == 1
    assert body["total"] == 2


@pytest.mark.asyncio
async def test_list_is_business_scoped(client: AsyncClient, db_session: AsyncSession) -> None:
    await _create_test_supplier(db_session, name="Mine", business_id=BUSINESS_ID)
    await _create_test_supplier(db_session, name="Theirs", business_id=OTHER_BUSINESS_ID)

    resp = await client.get(API_PREFIX, headers=AUTH_HEADER)
    names = [s["name"] for s in resp.json()["items"]]
    assert names == ["Mine"]


@pytest.mark.asyncio
async def test_cannot_patch_or_delete_another_business_supplier(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    supplier = await _create_test_supplier(db_session, business_id=OTHER_BUSINESS_ID)

    resp = await client.patch(
        f"{API_PREFIX}/{supplier.id}", json={"name": "Hijacked"}, headers=AUTH_HEADER
    )
    assert resp.status_code == 404

    resp = await client.delete(f"{API_PREFIX}/{supplier.id}", headers=AUTH_HEADER)
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_update_with_no_fields_is_400(client: AsyncClient, db_session: AsyncSession) -> None:
    supplier = await _create_test_supplier(db_session)
    resp = await client.patch(f"{API_PREFIX}/{supplier.id}", json={}, headers=AUTH_HEADER)
    assert resp.status_code == 400


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("method", "path_suffix", "body", "required_perm"),
    [
        ("POST", "", {"name": "X"}, "suppliers.create"),
        ("GET", "", None, "suppliers.view"),
        ("PATCH", "/{id}", {"name": "X"}, "suppliers.update"),
        ("DELETE", "/{id}", None, "suppliers.delete"),
        ("GET", "/{id}", None, "suppliers.view"),
    ],
)
async def test_each_route_403s_without_its_permission(
    client: AsyncClient,
    db_session: AsyncSession,
    method: str,
    path_suffix: str,
    body: dict | None,
    required_perm: str,
) -> None:
    supplier = await _create_test_supplier(db_session)
    path = f"{API_PREFIX}{path_suffix.format(id=supplier.id)}"
    # A real-but-unrelated permission — an empty list falls back to the
    # ALL_SUPPLIER_PERMS default (see `_build_token`), which would silently
    # defeat this test.
    header = _auth_header(["reports.view"])

    resp = await client.request(method, path, json=body, headers=header)
    assert resp.status_code == 403, f"{method} {path} should 403 without {required_perm}"
