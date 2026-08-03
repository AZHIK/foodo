"""Seed default internal groups, roles, and role_permissions.

Populates the platform's internal RBAC hierarchy (Part 1 of the default-groups
and roles seeding work): six groups, each with their designated roles, and the
exact permission set per role drawn exclusively from the PermissionCode enum.

Every definition lives here so the whole internal hierarchy is visible in one
place.  The seed is idempotent — running it repeatedly never duplicates rows
(Groups and Roles are upserted by name, RolePermission rows are added only if
not already present).

None of this touches business role_templates or platform_roles; those live in
``app/db/seed_role_templates.py`` and ``app/db/seed_permissions.py``.
"""

from dataclasses import dataclass

from sqlmodel import Session, select

from app.core.permission_codes import PermissionCode
from app.db.seed_mappings import POS_SALES_LIST, POS_SALES_VIEW, uniq
from app.models import Group, Role, RolePermission


@dataclass(frozen=True)
class RoleSeed:
    name: str
    description: str
    permissions: tuple[PermissionCode, ...]


@dataclass(frozen=True)
class GroupSeed:
    name: str
    description: str
    roles: tuple[RoleSeed, ...]


# The internal "Super Admin" — every action across the administrative resource
# domains the internal RBAC guards (Groups, Roles, Platform Roles, Organizations,
# Businesses, Business Locations, Role Templates, Users).
_SUPER_ADMIN_PERMISSIONS: tuple[PermissionCode, ...] = (
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
    # Business Locations
    PermissionCode.BUSINESS_LOCATIONS_VIEW,
    PermissionCode.BUSINESS_LOCATIONS_CREATE,
    PermissionCode.BUSINESS_LOCATIONS_UPDATE,
    PermissionCode.BUSINESS_LOCATIONS_DELETE,
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

# Support Agent's full set, reused as the base for Support Lead.
_SUPPORT_AGENT_PERMISSIONS: tuple[PermissionCode, ...] = (
    PermissionCode.USERS_VIEW,
    PermissionCode.USERS_UPDATE,
    PermissionCode.BUSINESSES_VIEW,
    PermissionCode.USER_SESSIONS_VIEW,
    PermissionCode.USER_SESSIONS_REVOKE,
    PermissionCode.TRUSTED_DEVICES_VIEW,
    PermissionCode.TRUSTED_DEVICES_REVOKE,
    PermissionCode.LOGIN_ATTEMPTS_VIEW,
    PermissionCode.AUTH_RISK_EVENTS_VIEW,
)

# Finance Analyst: full set; base for Finance Manager.
_FINANCE_ANALYST_PERMISSIONS: tuple[PermissionCode, ...] = (
    PermissionCode.BUSINESSES_VIEW,
    PermissionCode.ORGANIZATIONS_VIEW,
    POS_SALES_LIST,
    POS_SALES_VIEW,
)


INTERNAL_GROUP_SEEDS: tuple[GroupSeed, ...] = (
    GroupSeed(
        name="IT / Platform Admin",
        description="Platform-wide configuration and administration.",
        roles=(
            RoleSeed(
                name="Super Admin",
                description="Unrestricted access across all administrative resource domains.",
                permissions=uniq(_SUPER_ADMIN_PERMISSIONS),
            ),
        ),
    ),
    GroupSeed(
        name="Support",
        description="Customer and platform support.",
        roles=(
            RoleSeed(
                name="Support Agent",
                description="Resolve user, session, and business support issues.",
                permissions=uniq(_SUPPORT_AGENT_PERMISSIONS),
            ),
            RoleSeed(
                name="Support Lead",
                description="Lead support team with account management authority.",
                permissions=uniq(
                    _SUPPORT_AGENT_PERMISSIONS
                    + (
                        PermissionCode.USERS_DEACTIVATE,
                        PermissionCode.USERS_REACTIVATE,
                    )
                ),
            ),
        ),
    ),
    GroupSeed(
        name="Finance",
        description="Financial reporting and organizational finance.",
        roles=(
            RoleSeed(
                name="Finance Analyst",
                description="View financial and sales reporting.",
                permissions=uniq(_FINANCE_ANALYST_PERMISSIONS),
            ),
            RoleSeed(
                name="Finance Manager",
                description="Manage finance and organizational records.",
                permissions=uniq(
                    _FINANCE_ANALYST_PERMISSIONS
                    + (
                        PermissionCode.POS_REFUND,
                        PermissionCode.ORGANIZATIONS_CREATE,
                        PermissionCode.ORGANIZATIONS_UPDATE,
                    )
                ),
            ),
        ),
    ),
    GroupSeed(
        name="Marketing",
        description="Marketing and growth.",
        roles=(
            RoleSeed(
                name="Marketing Analyst",
                description="View business and organization data for marketing.",
                permissions=uniq(
                    (
                        PermissionCode.BUSINESSES_VIEW,
                        PermissionCode.ORGANIZATIONS_VIEW,
                    )
                ),
            ),
        ),
    ),
    GroupSeed(
        name="Data / Analytics",
        description="Analytics and forecasting.",
        roles=(
            RoleSeed(
                name="Data Analyst",
                description="View forecasting, sales, and inventory analytics.",
                permissions=uniq(
                    (
                        PermissionCode.AI_FORECAST_VIEW,
                        PermissionCode.BUSINESSES_VIEW,
                        POS_SALES_LIST,
                        PermissionCode.INVENTORY_VIEW,
                    )
                ),
            ),
        ),
    ),
    GroupSeed(
        name="Compliance",
        description="Regulatory and security compliance.",
        roles=(
            RoleSeed(
                name="Compliance Officer",
                description="Review security and compliance records.",
                permissions=uniq(
                    (
                        PermissionCode.USERS_VIEW,
                        PermissionCode.LOGIN_ATTEMPTS_VIEW,
                        PermissionCode.AUTH_RISK_EVENTS_VIEW,
                        PermissionCode.VERIFICATION_CODES_VIEW,
                        PermissionCode.REFRESH_TOKENS_VIEW,
                        PermissionCode.USER_SESSIONS_VIEW,
                    )
                ),
            ),
        ),
    ),
)


def seed_internal_rbac(session: Session) -> None:
    """Upsert groups, roles, and role_permissions idempotently."""
    for group_seed in INTERNAL_GROUP_SEEDS:
        group = session.exec(select(Group).where(Group.name == group_seed.name)).one_or_none()
        if group is None:
            group = Group(name=group_seed.name, description=group_seed.description)
            session.add(group)
            session.flush()
        else:
            group.description = group_seed.description

        for role_seed in group_seed.roles:
            role = session.exec(
                select(Role).where(
                    Role.group_id == group.id,
                    Role.name == role_seed.name,
                )
            ).one_or_none()
            if role is None:
                role = Role(
                    group_id=group.id,
                    name=role_seed.name,
                    description=role_seed.description,
                )
                session.add(role)
                session.flush()
            else:
                role.description = role_seed.description

            existing = {
                rp.permission_code
                for rp in session.exec(
                    select(RolePermission).where(RolePermission.role_id == role.id)
                ).all()
            }

            for code in role_seed.permissions:
                if code.value not in existing:
                    session.add(
                        RolePermission(
                            role_id=role.id,
                            permission_code=code.value,
                        )
                    )

    session.commit()
