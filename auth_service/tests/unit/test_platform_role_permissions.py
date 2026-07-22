"""Tests for platform role permissions resolver, token claims, and require_permission guard."""

import pytest
import pytest_asyncio
from fastapi import HTTPException
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.core.security import create_access_token, decode_and_verify_access_token
from app.deps.permissions import require_permission
from app.models import (
    Permission,
    PlatformRole,
    PlatformRolePermission,
    User,
    UserCategory,
    UserPlatformRole,
)
from app.services.permission_resolver import compute_platform_role_permissions


@pytest_asyncio.fixture
async def seeded_async_session(
    db_session: AsyncSession,
) -> AsyncSession:
    """Seed the platform roles + permissions into the async session,
    then return it so tests can add user records."""
    from app.db.seed_permissions import DEFAULT_PLATFORM_ROLE_PERMISSIONS, PERMISSION_SEEDS

    # seed Permission rows
    for seed in PERMISSION_SEEDS:
        existing = (
            await db_session.exec(select(Permission).where(Permission.code == seed.code.value))
        ).one_or_none()
        if existing is None:
            db_session.add(
                Permission(
                    code=seed.code.value,
                    name=seed.name,
                    description=seed.description,
                    domain=seed.domain,
                    is_ai_sensitive=seed.is_ai_sensitive,
                    requires_human_approval=seed.requires_human_approval,
                )
            )
    await db_session.flush()

    # seed PlatformRole + PlatformRolePermission rows
    for role_name, perm_codes in DEFAULT_PLATFORM_ROLE_PERMISSIONS.items():
        role = (
            await db_session.exec(select(PlatformRole).where(PlatformRole.name == role_name))
        ).one_or_none()
        if role is None:
            role = PlatformRole(name=role_name)
            db_session.add(role)
            await db_session.flush()

        for code in perm_codes:
            prp = (
                await db_session.exec(
                    select(PlatformRolePermission).where(
                        PlatformRolePermission.platform_role_id == role.id,
                        PlatformRolePermission.permission_code == code.value,
                    )
                )
            ).one_or_none()
            if prp is None:
                db_session.add(
                    PlatformRolePermission(
                        platform_role_id=role.id,
                        permission_code=code.value,
                    )
                )
    await db_session.flush()
    return db_session


@pytest.mark.asyncio
async def test_compute_platform_role_permissions_driver_vs_consumer(
    seeded_async_session: AsyncSession,
) -> None:
    driver_user = User(
        phone="+254711111111",
        full_name="Driver Joe",
        user_category=UserCategory.DRIVER,
    )
    consumer_user = User(
        phone="+254722222222",
        full_name="Consumer Jane",
        user_category=UserCategory.CONSUMER,
    )
    seeded_async_session.add(driver_user)
    seeded_async_session.add(consumer_user)
    await seeded_async_session.commit()
    await seeded_async_session.refresh(driver_user)
    await seeded_async_session.refresh(consumer_user)

    driver_perms = await compute_platform_role_permissions(seeded_async_session, driver_user.id)
    consumer_perms = await compute_platform_role_permissions(seeded_async_session, consumer_user.id)

    assert PermissionCode.DELIVERY_UPDATE_STATUS.value in driver_perms
    assert PermissionCode.DELIVERY_VIEW_ASSIGNED.value in driver_perms
    assert PermissionCode.DELIVERY_CONFIRM_DROPOFF.value in driver_perms
    assert PermissionCode.ORDER_CREATE.value not in driver_perms

    assert PermissionCode.ORDER_CREATE.value in consumer_perms
    assert PermissionCode.ORDER_VIEW_OWN.value in consumer_perms
    assert PermissionCode.ORDER_RATE.value in consumer_perms
    assert PermissionCode.DELIVERY_UPDATE_STATUS.value not in consumer_perms


@pytest.mark.asyncio
async def test_compute_platform_role_permissions_via_user_platform_role_assignment(
    seeded_async_session: AsyncSession,
) -> None:
    user = User(
        phone="+254733333333",
        full_name="Custom Staff",
        user_category=UserCategory.PLATFORM_STAFF,
    )
    seeded_async_session.add(user)
    await seeded_async_session.flush()

    driver_role = (
        await seeded_async_session.exec(select(PlatformRole).where(PlatformRole.name == "driver"))
    ).one()

    upr = UserPlatformRole(user_id=user.id, platform_role_id=driver_role.id)
    seeded_async_session.add(upr)
    await seeded_async_session.commit()

    perms = await compute_platform_role_permissions(seeded_async_session, user.id)
    assert PermissionCode.DELIVERY_UPDATE_STATUS.value in perms


@pytest.mark.asyncio
async def test_driver_token_issuance_contains_permissions_claim(
    seeded_async_session: AsyncSession,
) -> None:
    driver_user = User(
        phone="+254744444444",
        full_name="Driver Sam",
        user_category=UserCategory.DRIVER,
    )
    seeded_async_session.add(driver_user)
    await seeded_async_session.commit()
    await seeded_async_session.refresh(driver_user)

    perms = await compute_platform_role_permissions(seeded_async_session, driver_user.id)
    user_cat = (
        driver_user.user_category.value
        if isinstance(driver_user.user_category, UserCategory)
        else driver_user.user_category
    )
    token = create_access_token(
        subject=str(driver_user.id),
        user_category=user_cat,
        platform_role=user_cat,
        permissions=sorted(perms),
    )

    claims = decode_and_verify_access_token(token)
    assert claims["user_category"] == "driver"
    assert claims["platform_role"] == "driver"
    assert "permissions" in claims
    assert PermissionCode.DELIVERY_UPDATE_STATUS.value in claims["permissions"]


@pytest.mark.asyncio
async def test_require_permission_dependency_allows_driver_token() -> None:
    """Regression test proving require_permission accepts driver token for driver permissions."""
    driver_claims = {
        "sub": "00000000-0000-0000-0000-000000000099",
        "user_category": "driver",
        "platform_role": "driver",
        "permissions": [
            "delivery.view_assigned",
            "delivery.update_status",
            "delivery.confirm_dropoff",
        ],
    }

    dep_func = require_permission(PermissionCode.DELIVERY_UPDATE_STATUS)
    result_claims = await dep_func(claims=driver_claims)
    assert result_claims == driver_claims

    forbidden_dep = require_permission(PermissionCode.POS_REFUND)
    with pytest.raises(HTTPException) as exc_info:
        await forbidden_dep(claims=driver_claims)

    assert exc_info.value.status_code == 403
