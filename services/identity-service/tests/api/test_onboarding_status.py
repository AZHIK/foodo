"""Integration tests for GET /users/me/onboarding-status."""

from uuid import uuid4

from httpx import AsyncClient
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.security import create_access_token
from app.models.business import Business, BusinessRole, BusinessType, UserBusinessRole
from app.models.user import User, UserCategory, UserStatus


def _valid_phone() -> str:
    return f"+2557{uuid4().int % 100_000_000:08d}"


def _token(user: User) -> str:
    return create_access_token(
        subject=str(user.id),
        user_category=UserCategory.BUSINESS_USER.value,
    )


async def _make_user(db_session: AsyncSession, phone: str | None = None) -> User:
    user = User(
        phone=phone or _valid_phone(),
        full_name="Onboarding User",
        user_category=UserCategory.BUSINESS_USER,
        status=UserStatus.ACTIVE,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


async def _make_business_with_role(
    db_session: AsyncSession, owner: User
) -> tuple[Business, BusinessRole]:
    biz = Business(
        name=f"Onboard Biz {uuid4().hex[:8]}",
        business_type=BusinessType.RESTAURANT,
        owner_user_id=owner.id,
        country_code="TZ",
    )
    db_session.add(biz)
    await db_session.commit()
    await db_session.refresh(biz)

    role = BusinessRole(business_id=biz.id, name="Cashier")
    db_session.add(role)
    await db_session.commit()
    await db_session.refresh(role)
    return biz, role


class TestOnboardingStatus:
    async def test_unauthenticated_returns_401(self, client: AsyncClient) -> None:
        resp = await client.get("/api/v1/users/me/onboarding-status")
        assert resp.status_code == 401

    async def test_needs_onboarding_true_when_no_roles(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        user = await _make_user(db_session)
        resp = await client.get(
            "/api/v1/users/me/onboarding-status",
            headers={"Authorization": f"Bearer {_token(user)}"},
        )
        assert resp.status_code == 200
        assert resp.json() == {
            "needs_onboarding": True,
            "business_id": None,
            "business_name": None,
            "full_name": user.full_name,
            "email": user.email,
        }

    async def test_needs_onboarding_false_after_role_assigned(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        owner = await _make_user(db_session)
        staff = await _make_user(db_session)
        biz, role = await _make_business_with_role(db_session, owner)

        ubr = UserBusinessRole(
            user_id=staff.id,
            business_id=biz.id,
            business_role_id=role.id,
        )
        db_session.add(ubr)
        await db_session.commit()

        resp = await client.get(
            "/api/v1/users/me/onboarding-status",
            headers={"Authorization": f"Bearer {_token(staff)}"},
        )
        assert resp.status_code == 200
        assert resp.json() == {
            "needs_onboarding": False,
            "business_id": str(biz.id),
            "business_name": biz.name,
            "full_name": staff.full_name,
            "email": staff.email,
        }

    async def test_needs_onboarding_false_after_invite_end_to_end(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        owner = await _make_user(db_session)
        biz, role = await _make_business_with_role(db_session, owner)
        owner_token = create_access_token(
            subject=str(owner.id),
            user_category=UserCategory.BUSINESS_USER.value,
            active_business_id=str(biz.id),
            roles=["owner"],
            permissions=["*"],
            other_businesses=[],
        )
        phone = _valid_phone()

        invite_resp = await client.post(
            f"/api/v1/businesses/{biz.id}/staff",
            json={"business_role_id": str(role.id), "phone": phone},
            headers={"Authorization": f"Bearer {owner_token}"},
        )
        assert invite_resp.status_code == 201

        invited = (await db_session.exec(select(User).where(User.phone == phone))).one()
        assert invited.status == UserStatus.INVITED

        resp = await client.get(
            "/api/v1/users/me/onboarding-status",
            headers={"Authorization": f"Bearer {_token(invited)}"},
        )
        assert resp.status_code == 200
        assert resp.json() == {
            "needs_onboarding": False,
            "business_id": str(biz.id),
            "business_name": biz.name,
            "full_name": invited.full_name,
            "email": invited.email,
        }


class TestUpdateProfile:
    async def test_updates_full_name_and_email(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        user = await _make_user(db_session)
        resp = await client.patch(
            "/api/v1/users/me",
            json={"full_name": "Jane Doe", "email": "jane@example.com"},
            headers={"Authorization": f"Bearer {_token(user)}"},
        )
        assert resp.status_code == 200
        assert resp.json() == {"full_name": "Jane Doe", "email": "jane@example.com"}

        status_resp = await client.get(
            "/api/v1/users/me/onboarding-status",
            headers={"Authorization": f"Bearer {_token(user)}"},
        )
        assert status_resp.json()["full_name"] == "Jane Doe"
        assert status_resp.json()["email"] == "jane@example.com"

    async def test_duplicate_email_returns_409(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        taken = await _make_user(db_session)
        taken.email = "taken@example.com"
        db_session.add(taken)
        await db_session.commit()

        user = await _make_user(db_session)
        resp = await client.patch(
            "/api/v1/users/me",
            json={"full_name": "Someone", "email": "taken@example.com"},
            headers={"Authorization": f"Bearer {_token(user)}"},
        )
        assert resp.status_code == 409

    async def test_unauthenticated_returns_401(self, client: AsyncClient) -> None:
        resp = await client.patch(
            "/api/v1/users/me",
            json={"full_name": "Someone"},
        )
        assert resp.status_code == 401
