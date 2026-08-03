"""Tests for the exact seeded permission sets of the platform_roles (Part 2).

driver/consumer follow the agreed spec verbatim; admin is confirmed to cover
the full PermissionCode surface (platform-wide oversight aligned to the internal
"Super Admin" set plus every business/value-chain code).
"""

import pytest
from sqlmodel import Session, SQLModel, create_engine, select

from app.core.permission_codes import PermissionCode
from app.db.seed_permissions import DEFAULT_PLATFORM_ROLE_PERMISSIONS, seed_permissions
from app.models import PlatformRole, PlatformRolePermission


@pytest.fixture
def session() -> Session:
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


def _permissions_for(session: Session, role_name: str) -> set[str]:
    role = session.exec(select(PlatformRole).where(PlatformRole.name == role_name)).one()
    return {
        prp.permission_code
        for prp in session.exec(
            select(PlatformRolePermission).where(PlatformRolePermission.platform_role_id == role.id)
        ).all()
    }


def test_driver_exact_permissions(session: Session) -> None:
    seed_permissions(session)
    assert _permissions_for(session, "driver") == {
        PermissionCode.DELIVERY_VIEW_ASSIGNED.value,
        PermissionCode.DELIVERY_UPDATE_STATUS.value,
        PermissionCode.DELIVERY_CONFIRM_DROPOFF.value,
    }


def test_consumer_exact_permissions(session: Session) -> None:
    seed_permissions(session)
    assert _permissions_for(session, "consumer") == {
        PermissionCode.ORDER_CREATE.value,
        PermissionCode.ORDER_VIEW_OWN.value,
        PermissionCode.ORDER_RATE.value,
    }


def test_admin_covers_full_enum_surface(session: Session) -> None:
    seed_permissions(session)
    admin_codes = _permissions_for(session, "admin")
    assert admin_codes == {code.value for code in PermissionCode}


def test_definitions_are_enum_members() -> None:
    for role_name, codes in DEFAULT_PLATFORM_ROLE_PERMISSIONS.items():
        for code in codes:
            assert isinstance(code, PermissionCode), f"{role_name} has non-enum {code!r}"
            assert PermissionCode(code.value) == code
