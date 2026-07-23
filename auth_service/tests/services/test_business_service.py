from uuid import uuid4

import pytest
import pytest_asyncio
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.models.business import (
    Business,
    BusinessRole,
    BusinessRolePermission,
    UserBusinessRole,
)
from app.models.user import User, UserCategory
from app.services.business_service import create_business


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    user = User(
        phone=f"+2557{uuid4().hex[:9]}",
        full_name="Business Creator",
        user_category=UserCategory.BUSINESS_USER,
    )
    async with db_session.begin():
        db_session.add(user)
    return user


@pytest_asyncio.fixture
async def seeded_templates(db_session: AsyncSession) -> None:
    """Seed all role templates into the test DB."""
    import app.db.seed_role_templates as srt
    from app.models.template import RoleTemplate, RoleTemplatePermission

    async with db_session.begin():
        for template_seed in srt.ROLE_TEMPLATE_SEEDS:
            rt = RoleTemplate(
                name=template_seed.name,
                description=template_seed.description,
                business_type=template_seed.business_type,
                is_owner_template=template_seed.is_owner_template,
            )
            db_session.add(rt)
            await db_session.flush()
            for code in template_seed.permissions:
                db_session.add(
                    RoleTemplatePermission(
                        role_template_id=rt.id,
                        permission_code=code.value,
                    )
                )


class TestCreateBusiness:
    async def test_creates_business_with_owner_role(
        self, db_session: AsyncSession, test_user: User, seeded_templates: None
    ) -> None:
        biz = await create_business(
            db_session,
            creator_user_id=test_user.id,
            name="Test Restaurant",
            business_type="restaurant",
        )

        assert biz.name == "Test Restaurant"
        assert biz.business_type == "restaurant"
        assert biz.owner_user_id == test_user.id

        roles = (
            await db_session.exec(select(BusinessRole).where(BusinessRole.business_id == biz.id))
        ).all()
        assert len(roles) >= 1

        owner_role = next((r for r in roles if r.is_protected), None)
        assert owner_role is not None
        assert "owner" in owner_role.name.lower()

        assignment = (
            await db_session.exec(
                select(UserBusinessRole).where(
                    UserBusinessRole.user_id == test_user.id,
                    UserBusinessRole.business_id == biz.id,
                )
            )
        ).one_or_none()
        assert assignment is not None
        assert assignment.business_role_id == owner_role.id

    async def test_owner_role_has_permissions(
        self, db_session: AsyncSession, test_user: User, seeded_templates: None
    ) -> None:
        biz = await create_business(
            db_session,
            creator_user_id=test_user.id,
            name="Perm Test Biz",
            business_type="restaurant",
        )

        roles = (
            await db_session.exec(select(BusinessRole).where(BusinessRole.business_id == biz.id))
        ).all()
        owner_role = next(r for r in roles if r.is_protected)

        perms = (
            await db_session.exec(
                select(BusinessRolePermission).where(
                    BusinessRolePermission.business_role_id == owner_role.id,
                )
            )
        ).all()
        codes = {p.permission_code for p in perms}
        assert PermissionCode.POS_WRITE.value in codes
        assert PermissionCode.INVENTORY_VIEW.value in codes
        assert PermissionCode.BUSINESSES_VIEW.value in codes

    async def test_supplier_gets_different_roles_than_restaurant(
        self, db_session: AsyncSession, test_user: User, seeded_templates: None
    ) -> None:
        restaurant = await create_business(
            db_session,
            creator_user_id=test_user.id,
            name="R",
            business_type="restaurant",
        )
        supplier = await create_business(
            db_session,
            creator_user_id=test_user.id,
            name="S",
            business_type="supplier",
        )

        rest_roles = (
            await db_session.exec(
                select(BusinessRole).where(BusinessRole.business_id == restaurant.id)
            )
        ).all()
        supp_roles = (
            await db_session.exec(
                select(BusinessRole).where(BusinessRole.business_id == supplier.id)
            )
        ).all()

        rest_names = {r.name for r in rest_roles}
        supp_names = {r.name for r in supp_roles}
        assert rest_names != supp_names

        rest_owner = next(r for r in rest_roles if r.is_protected)
        rest_perms = {
            p.permission_code
            for p in (
                await db_session.exec(
                    select(BusinessRolePermission).where(
                        BusinessRolePermission.business_role_id == rest_owner.id,
                    )
                )
            ).all()
        }
        assert PermissionCode.POS_WRITE.value in rest_perms

        supp_owner = next(r for r in supp_roles if r.is_protected)
        supp_perms = {
            p.permission_code
            for p in (
                await db_session.exec(
                    select(BusinessRolePermission).where(
                        BusinessRolePermission.business_role_id == supp_owner.id,
                    )
                )
            ).all()
        }
        assert PermissionCode.SUPPLIER_PRICE_MANAGE.value in supp_perms
        assert PermissionCode.POS_WRITE.value not in supp_perms

    async def test_rolls_back_entirely_on_failure(
        self, db_session: AsyncSession, test_user: User, seeded_templates: None
    ) -> None:
        async with db_session.begin():
            before_count = (await db_session.exec(select(Business))).all()

        with pytest.raises(ValueError):
            await create_business(
                db_session,
                creator_user_id=test_user.id,
                name="Fail Biz",
                business_type="nonexistent_type",
            )

        async with db_session.begin():
            after_count = (await db_session.exec(select(Business))).all()
        assert len(after_count) == len(before_count)

        async with db_session.begin():
            roles = (await db_session.exec(select(BusinessRole))).all()
        assert len(roles) == 0

    async def test_events_fire_with_correct_payloads(
        self, db_session: AsyncSession, test_user: User, seeded_templates: None
    ) -> None:
        from unittest.mock import patch

        events: list[dict] = []

        async def _capture(event_name: str, payload: dict) -> None:
            events.append({"name": event_name, "payload": payload})

        with (
            patch("app.services.business_service.publish_event", side_effect=_capture),
            patch("app.services.audit_events.publish_event", side_effect=_capture),
        ):
            biz = await create_business(
                db_session,
                creator_user_id=test_user.id,
                name="Event Test",
                business_type="restaurant",
            )

        event_names = {e["name"] for e in events}
        assert "business.created" in event_names
        assert "audit.recorded" in event_names

        biz_created = [e for e in events if e["name"] == "business.created"][0]
        assert biz_created["payload"]["business_id"] == str(biz.id)
        assert biz_created["payload"]["creator_user_id"] == str(test_user.id)
        assert biz_created["payload"]["business_type"] == "restaurant"
        assert biz_created["payload"]["cloned_role_count"] >= 1

        audits = [e for e in events if e["name"] == "audit.recorded"]
        actions = {a["payload"]["action"] for a in audits}
        assert "business.created" in actions
        assert "business_role.assigned" in actions
