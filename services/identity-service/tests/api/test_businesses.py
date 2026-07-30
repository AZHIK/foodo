from uuid import uuid4

from httpx import AsyncClient
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.core.security import create_access_token
from app.db.seed_role_templates import seed_role_templates
from app.models.user import User, UserCategory


async def _seed_templates(db_session: AsyncSession) -> None:
    def _seed(session):
        seed_role_templates(session)

    await db_session.run_sync(_seed)


async def _create_test_user(db_session: AsyncSession) -> User:
    user = User(
        phone=f"+2557{uuid4().hex[:9]}",
        full_name="API Test User",
        user_category=UserCategory.BUSINESS_USER,
    )
    async with db_session.begin():
        db_session.add(user)
    return user


def _business_user_token(
    subject: str,
    business_id: str | None = None,
    permissions: list[str] | None = None,
) -> str:
    return create_access_token(
        subject=subject,
        user_category=UserCategory.BUSINESS_USER.value,
        active_business_id=business_id,
        roles=["owner"],
        permissions=permissions or [],
        other_businesses=[],
    )


class TestCreateBusinessApi:
    async def test_creates_business_and_returns_roles(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        await _seed_templates(db_session)
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        resp = await client.post(
            "/api/v1/businesses",
            json={"name": "My Restaurant", "business_type": "restaurant"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 201, resp.text
        data = resp.json()
        assert data["business"]["name"] == "My Restaurant"
        assert data["business"]["business_type"] == "restaurant"
        assert data["business"]["owner_user_id"] == str(user.id)
        assert len(data["roles_created"]) >= 1
        assert data["owner_role_name"] != ""
        assert "context/switch" in data["note"]

    async def test_rejects_unauthenticated_request(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        resp = await client.post(
            "/api/v1/businesses",
            json={"name": "No Auth", "business_type": "restaurant"},
        )
        assert resp.status_code == 401

    async def test_rejects_invalid_business_type(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        resp = await client.post(
            "/api/v1/businesses",
            json={"name": "Bad Type", "business_type": "invalid_type"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 422

    async def test_creates_business_with_optional_fields(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        await _seed_templates(db_session)
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        resp = await client.post(
            "/api/v1/businesses",
            json={
                "name": "Full Biz",
                "business_type": "supplier",
                "tax_id": "TZ12345",
                "country_code": "TZ",
                "city": "Dar es Salaam",
                "timezone": "Africa/Dar_es_Salaam",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 201, resp.text
        data = resp.json()
        assert data["business"]["tax_id"] == "TZ12345"
        assert data["business"]["city"] == "Dar es Salaam"
        assert data["business"]["business_type"] == "supplier"


class TestGetBusinessApi:
    async def test_creator_can_read_business_after_context_switch(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        await _seed_templates(db_session)
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        create_resp = await client.post(
            "/api/v1/businesses",
            json={"name": "Read Test", "business_type": "restaurant"},
            headers={"Authorization": f"Bearer {token}"},
        )
        biz_id = create_resp.json()["business"]["id"]

        switch_token = _business_user_token(
            subject=str(user.id),
            business_id=biz_id,
            permissions=[str(PermissionCode.BUSINESSES_VIEW)],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}",
            headers={"Authorization": f"Bearer {switch_token}"},
        )
        assert resp.status_code == 200, resp.text
        assert resp.json()["id"] == biz_id
        assert resp.json()["name"] == "Read Test"

    async def test_token_without_business_context_gets_403(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        await _seed_templates(db_session)
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        create_resp = await client.post(
            "/api/v1/businesses",
            json={"name": "No Ctx", "business_type": "restaurant"},
            headers={"Authorization": f"Bearer {token}"},
        )
        biz_id = create_resp.json()["business"]["id"]

        no_ctx_token = _business_user_token(
            subject=str(user.id),
            business_id=None,
            permissions=[str(PermissionCode.BUSINESSES_VIEW)],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}",
            headers={"Authorization": f"Bearer {no_ctx_token}"},
        )
        assert resp.status_code == 403
        assert "business context" in resp.json()["detail"].lower()


class TestListBusinessRolesApi:
    async def test_creator_can_list_roles_after_context_switch(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        await _seed_templates(db_session)
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        create_resp = await client.post(
            "/api/v1/businesses",
            json={"name": "Roles Test", "business_type": "restaurant"},
            headers={"Authorization": f"Bearer {token}"},
        )
        biz_id = create_resp.json()["business"]["id"]

        switch_token = _business_user_token(
            subject=str(user.id),
            business_id=biz_id,
            permissions=[str(PermissionCode.BUSINESS_ROLES_VIEW)],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}/roles",
            headers={"Authorization": f"Bearer {switch_token}"},
        )
        assert resp.status_code == 200, resp.text
        roles = resp.json()
        assert len(roles) >= 1
        owner_role = next(r for r in roles if r["is_protected"])
        assert "owner" in owner_role["name"].lower()

    async def test_roles_endpoint_rejects_token_without_permission(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        await _seed_templates(db_session)
        user = await _create_test_user(db_session)
        token = _business_user_token(subject=str(user.id))

        create_resp = await client.post(
            "/api/v1/businesses",
            json={"name": "No Perm", "business_type": "restaurant"},
            headers={"Authorization": f"Bearer {token}"},
        )
        biz_id = create_resp.json()["business"]["id"]

        no_perm_token = _business_user_token(
            subject=str(user.id),
            business_id=biz_id,
            permissions=["inventory.view"],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}/roles",
            headers={"Authorization": f"Bearer {no_perm_token}"},
        )
        assert resp.status_code == 403
        assert "business_roles.view" in resp.json()["detail"]
