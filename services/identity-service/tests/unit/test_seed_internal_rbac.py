"""Tests for the default internal groups/roles/role_permissions seeding (Part 1).

Uses an in-memory SQLite Session (matching the style of
``test_adjustment1_permission_seed.py``) so it needs no live Postgres.
"""

import pytest
from sqlmodel import Session, SQLModel, create_engine, select

from app.core.permission_codes import PermissionCode
from app.db.seed_internal_rbac import INTERNAL_GROUP_SEEDS, seed_internal_rbac
from app.models import Group, Role, RolePermission


@pytest.fixture
def session() -> Session:
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


# ── Exact expected permission sets (final, post-mapping codes) ─────────
_SUPER_ADMIN_VALUES = (
    # Groups
    PermissionCode.GROUPS_VIEW,
    PermissionCode.GROUPS_CREATE,
    PermissionCode.GROUPS_UPDATE,
    PermissionCode.GROUPS_DELETE,
    PermissionCode.GROUPS_ASSIGN_USER,
    # Roles
    PermissionCode.ROLES_VIEW,
    PermissionCode.ROLES_CREATE,
    PermissionCode.ROLES_UPDATE,
    PermissionCode.ROLES_DELETE,
    PermissionCode.ROLES_ASSIGN_TO_USER,
    PermissionCode.ROLES_MANAGE_PERMISSIONS,
    # Platform Roles
    PermissionCode.PLATFORM_ROLES_VIEW,
    PermissionCode.PLATFORM_ROLES_CREATE,
    PermissionCode.PLATFORM_ROLES_UPDATE,
    PermissionCode.PLATFORM_ROLES_DELETE,
    PermissionCode.PLATFORM_ROLES_ASSIGN_TO_USER,
    PermissionCode.PLATFORM_ROLES_MANAGE_PERMISSIONS,
    # Organizations
    PermissionCode.ORGANIZATIONS_VIEW,
    PermissionCode.ORGANIZATIONS_CREATE,
    PermissionCode.ORGANIZATIONS_UPDATE,
    PermissionCode.ORGANIZATIONS_DELETE,
    # Businesses
    PermissionCode.BUSINESSES_VIEW,
    PermissionCode.BUSINESSES_CREATE,
    PermissionCode.BUSINESSES_UPDATE,
    PermissionCode.BUSINESSES_DELETE,
    PermissionCode.BUSINESSES_ASSIGN_TO_ORGANIZATION,
    # Stores
    PermissionCode.STORES_VIEW,
    PermissionCode.STORES_CREATE,
    PermissionCode.STORES_UPDATE,
    PermissionCode.STORES_DELETE,
    # Role Templates
    PermissionCode.ROLE_TEMPLATES_VIEW,
    PermissionCode.ROLE_TEMPLATES_CREATE,
    PermissionCode.ROLE_TEMPLATES_UPDATE,
    PermissionCode.ROLE_TEMPLATES_DELETE,
    PermissionCode.ROLE_TEMPLATES_MANAGE_PERMISSIONS,
    # Users
    PermissionCode.USERS_VIEW,
    PermissionCode.USERS_UPDATE,
    PermissionCode.USERS_DEACTIVATE,
    PermissionCode.USERS_REACTIVATE,
)

_SUPPORT_AGENT = {
    PermissionCode.USERS_VIEW,
    PermissionCode.USERS_UPDATE,
    PermissionCode.BUSINESSES_VIEW,
    PermissionCode.USER_SESSIONS_VIEW,
    PermissionCode.USER_SESSIONS_REVOKE,
    PermissionCode.TRUSTED_DEVICES_VIEW,
    PermissionCode.TRUSTED_DEVICES_REVOKE,
    PermissionCode.LOGIN_ATTEMPTS_VIEW,
    PermissionCode.AUTH_RISK_EVENTS_VIEW,
}


def _expected() -> dict[tuple[str, str], set[str]]:
    return {
        ("IT / Platform Admin", "Super Admin"): {c.value for c in _SUPER_ADMIN_VALUES},
        ("Support", "Support Agent"): {c.value for c in _SUPPORT_AGENT},
        ("Support", "Support Lead"): {c.value for c in _SUPPORT_AGENT}
        | {PermissionCode.USERS_DEACTIVATE.value, PermissionCode.USERS_REACTIVATE.value},
        ("Finance", "Finance Analyst"): {
            PermissionCode.BUSINESSES_VIEW.value,
            PermissionCode.ORGANIZATIONS_VIEW.value,
            PermissionCode.POS_WRITE.value,
        },
        ("Finance", "Finance Manager"): {
            PermissionCode.BUSINESSES_VIEW.value,
            PermissionCode.ORGANIZATIONS_VIEW.value,
            PermissionCode.POS_WRITE.value,
            PermissionCode.POS_REFUND.value,
            PermissionCode.ORGANIZATIONS_CREATE.value,
            PermissionCode.ORGANIZATIONS_UPDATE.value,
        },
        ("Marketing", "Marketing Analyst"): {
            PermissionCode.BUSINESSES_VIEW.value,
            PermissionCode.ORGANIZATIONS_VIEW.value,
        },
        ("Data / Analytics", "Data Analyst"): {
            PermissionCode.AI_FORECAST_VIEW.value,
            PermissionCode.BUSINESSES_VIEW.value,
            PermissionCode.POS_WRITE.value,
            PermissionCode.INVENTORY_VIEW.value,
        },
        ("Compliance", "Compliance Officer"): {
            PermissionCode.USERS_VIEW.value,
            PermissionCode.LOGIN_ATTEMPTS_VIEW.value,
            PermissionCode.AUTH_RISK_EVENTS_VIEW.value,
            PermissionCode.VERIFICATION_CODES_VIEW.value,
            PermissionCode.REFRESH_TOKENS_VIEW.value,
            PermissionCode.USER_SESSIONS_VIEW.value,
        },
    }


def test_seeding_twice_produces_no_duplicates(session: Session) -> None:
    seed_internal_rbac(session)
    seed_internal_rbac(session)

    groups = session.exec(select(Group)).all()
    assert len(groups) == len(INTERNAL_GROUP_SEEDS)

    roles = session.exec(select(Role)).all()
    assert len(roles) == sum(len(gs.roles) for gs in INTERNAL_GROUP_SEEDS)

    perms = session.exec(select(RolePermission)).all()
    pairs = {(p.role_id, p.permission_code) for p in perms}
    assert len(perms) == len(pairs)


def test_permission_count_unchanged_on_rereun(session: Session) -> None:
    seed_internal_rbac(session)
    before = len(session.exec(select(RolePermission)).all())
    seed_internal_rbac(session)
    after = len(session.exec(select(RolePermission)).all())
    assert before == after


def test_every_group_role_matches_exact_spec(session: Session) -> None:
    seed_internal_rbac(session)

    expected = _expected()
    group_by_name = {g.name: g for g in session.exec(select(Group)).all()}

    checked = 0
    for group_seed in INTERNAL_GROUP_SEEDS:
        for role_seed in group_seed.roles:
            key = (group_seed.name, role_seed.name)
            assert key in expected, f"missing expected spec for {key}"
            group = group_by_name[group_seed.name]
            role = session.exec(
                select(Role).where(Role.group_id == group.id, Role.name == role_seed.name)
            ).one_or_none()
            assert role is not None, f"role {role_seed.name} not seeded"
            codes = {
                rp.permission_code
                for rp in session.exec(
                    select(RolePermission).where(RolePermission.role_id == role.id)
                ).all()
            }
            assert codes == expected[key], (
                f"{key} permissions mismatch: got {sorted(codes)} want {sorted(expected[key])}"
            )
            checked += 1

    assert checked == len(expected)


def test_all_definitions_reference_enum_members() -> None:
    """Raw-string guard: every permission is a PermissionCode member, never a string."""
    for group_seed in INTERNAL_GROUP_SEEDS:
        for role_seed in group_seed.roles:
            for code in role_seed.permissions:
                assert isinstance(code, PermissionCode)
                assert PermissionCode(code.value) == code
