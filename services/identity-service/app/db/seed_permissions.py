from dataclasses import dataclass

from sqlmodel import Session, select

from app.core.permission_codes import PermissionCode
from app.models import Permission, PlatformRole, PlatformRolePermission


@dataclass(frozen=True)
class PermissionSeed:
    code: PermissionCode
    name: str
    description: str

    @property
    def domain(self) -> str:
        return self.code.value.split(".", maxsplit=1)[0]

    @property
    def is_ai_sensitive(self) -> bool:
        return self.code.value.startswith("ai.") or (
            self.code is PermissionCode.PROCUREMENT_AUTO_ORDER_ENABLE
        )

    @property
    def requires_human_approval(self) -> bool:
        return self.code in {
            PermissionCode.AI_RECOMMENDATION_APPROVE,
            PermissionCode.PROCUREMENT_APPROVE,
        }


PERMISSION_SEEDS: tuple[PermissionSeed, ...] = (
    PermissionSeed(PermissionCode.POS_WRITE, "Write POS sales", "Create or update POS sales."),
    PermissionSeed(PermissionCode.POS_REFUND, "Refund POS sale", "Refund a completed POS sale."),
    PermissionSeed(
        PermissionCode.INVENTORY_VIEW,
        "View inventory",
        "View stock levels, expiry risk, and inventory history.",
    ),
    PermissionSeed(
        PermissionCode.INVENTORY_ADJUST,
        "Adjust inventory",
        "Manually adjust stock quantities.",
    ),
    PermissionSeed(
        PermissionCode.PROCUREMENT_CREATE,
        "Create procurement",
        "Create supplier purchase requests and purchase orders.",
    ),
    PermissionSeed(
        PermissionCode.PROCUREMENT_APPROVE,
        "Approve procurement",
        "Approve supplier purchase requests and purchase orders.",
    ),
    PermissionSeed(
        PermissionCode.PROCUREMENT_AUTO_ORDER_ENABLE,
        "Enable automated ordering",
        "Allow automated procurement actions to be enabled.",
    ),
    PermissionSeed(
        PermissionCode.AI_FORECAST_VIEW,
        "View AI forecasts",
        "View demand, stockout, and waste forecasts.",
    ),
    PermissionSeed(
        PermissionCode.AI_RECOMMENDATION_APPROVE,
        "Approve AI recommendations",
        "Approve AI-generated operational recommendations.",
    ),
    PermissionSeed(
        PermissionCode.SUPPLIER_PRICE_MANAGE,
        "Manage supplier prices",
        "Create and update supplier item prices.",
    ),
    PermissionSeed(
        PermissionCode.FARMER_SUPPLY_COMMITMENT_MANAGE,
        "Manage farmer supply commitments",
        "Create and update farmer supply commitments.",
    ),
    # Users (platform staff)
    PermissionSeed(
        PermissionCode.USERS_VIEW,
        "View users",
        "List and view platform staff users.",
    ),
    PermissionSeed(
        PermissionCode.USERS_UPDATE,
        "Update users",
        "Update user profile details.",
    ),
    PermissionSeed(
        PermissionCode.USERS_DEACTIVATE,
        "Deactivate users",
        "Soft-delete (deactivate) a platform staff user.",
    ),
    PermissionSeed(
        PermissionCode.USERS_REACTIVATE,
        "Reactivate users",
        "Reactivate a previously deactivated platform staff user.",
    ),
    # Coarse/legacy alias — kept for backward compatibility with existing
    # seeds/roles. New code should prefer the specific codes above.
    PermissionSeed(
        PermissionCode.USERS_MANAGE,
        "Manage users",
        "Invite, suspend, and update users.",
    ),
    # Groups (internal RBAC)
    PermissionSeed(
        PermissionCode.GROUPS_VIEW,
        "View groups",
        "List and view internal groups.",
    ),
    PermissionSeed(
        PermissionCode.GROUPS_CREATE,
        "Create groups",
        "Create a new internal group.",
    ),
    PermissionSeed(
        PermissionCode.GROUPS_UPDATE,
        "Update groups",
        "Update an internal group's details.",
    ),
    PermissionSeed(
        PermissionCode.GROUPS_DELETE,
        "Delete groups",
        "Delete an internal group (if no users assigned).",
    ),
    PermissionSeed(
        PermissionCode.GROUPS_ASSIGN_USER,
        "Assign user to group",
        "Assign a user to an internal group.",
    ),
    # Roles (internal RBAC)
    PermissionSeed(
        PermissionCode.ROLES_VIEW,
        "View roles",
        "List and view internal roles.",
    ),
    PermissionSeed(
        PermissionCode.ROLES_CREATE,
        "Create roles",
        "Create a new internal role.",
    ),
    PermissionSeed(
        PermissionCode.ROLES_UPDATE,
        "Update roles",
        "Update an internal role's details.",
    ),
    PermissionSeed(
        PermissionCode.ROLES_DELETE,
        "Delete roles",
        "Delete an internal role (if no users assigned).",
    ),
    PermissionSeed(
        PermissionCode.ROLES_ASSIGN_TO_USER,
        "Assign role to user",
        "Assign an internal role to a user.",
    ),
    PermissionSeed(
        PermissionCode.ROLES_MANAGE_PERMISSIONS,
        "Manage role permissions",
        "Assign or remove permissions from an internal role.",
    ),
    # Coarse/legacy alias — kept for backward compatibility with existing
    # seeds/roles. New code should prefer the specific codes above.
    PermissionSeed(
        PermissionCode.ROLES_ASSIGN,
        "Assign roles",
        "Assign roles to users.",
    ),
    # Organizations
    PermissionSeed(
        PermissionCode.ORGANIZATIONS_VIEW,
        "View organizations",
        "List and view organizations.",
    ),
    PermissionSeed(
        PermissionCode.ORGANIZATIONS_CREATE,
        "Create organizations",
        "Create a new organization.",
    ),
    PermissionSeed(
        PermissionCode.ORGANIZATIONS_UPDATE,
        "Update organizations",
        "Update an organization's details.",
    ),
    PermissionSeed(
        PermissionCode.ORGANIZATIONS_DELETE,
        "Delete organizations",
        "Delete an organization.",
    ),
    # Businesses
    PermissionSeed(
        PermissionCode.BUSINESSES_VIEW,
        "View businesses",
        "List and view businesses.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESSES_CREATE,
        "Create businesses",
        "Create a new business.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESSES_UPDATE,
        "Update businesses",
        "Update a business's details.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESSES_DELETE,
        "Delete businesses",
        "Delete a business.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESSES_ASSIGN_TO_ORGANIZATION,
        "Assign business to organization",
        "Assign a business to an organization.",
    ),
    # Business Locations
    PermissionSeed(
        PermissionCode.BUSINESS_LOCATIONS_VIEW,
        "View business locations",
        "List and view business locations.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_LOCATIONS_CREATE,
        "Create business locations",
        "Create a new business location.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_LOCATIONS_UPDATE,
        "Update business locations",
        "Update a business location's details.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_LOCATIONS_DELETE,
        "Delete business locations",
        "Delete a business location.",
    ),
    # Business Roles (per-business custom roles)
    PermissionSeed(
        PermissionCode.BUSINESS_ROLES_VIEW,
        "View business roles",
        "List and view per-business custom roles.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_ROLES_CREATE,
        "Create business roles",
        "Create a new per-business custom role.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_ROLES_UPDATE,
        "Update business roles",
        "Update a per-business custom role's details.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_ROLES_DELETE,
        "Delete business roles",
        "Delete a per-business custom role.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_ROLES_MANAGE_PERMISSIONS,
        "Manage business role permissions",
        "Assign or remove permissions from a per-business custom role.",
    ),
    # Coarse/legacy alias — kept for backward compatibility with existing
    # seeds/roles. New code should prefer the specific codes above.
    PermissionSeed(
        PermissionCode.BUSINESS_MANAGE_ROLES,
        "Manage business roles",
        "Create and update business roles and permissions.",
    ),
    # User Business Role Assignment
    PermissionSeed(
        PermissionCode.USER_BUSINESS_ROLES_VIEW,
        "View user business roles",
        "List and view role assignments for users within a business.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_ROLES_ASSIGN,
        "Assign user business role",
        "Assign a business role to a user.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_ROLES_REVOKE,
        "Revoke user business role",
        "Remove a business role assignment from a user.",
    ),
    # User Business Location Role Assignment
    PermissionSeed(
        PermissionCode.USER_BUSINESS_LOCATION_ROLES_VIEW,
        "View user business location roles",
        "List and view location-scoped role assignments for users.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_LOCATION_ROLES_ASSIGN,
        "Assign user location role",
        "Assign a business location role to a user.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_LOCATION_ROLES_REVOKE,
        "Revoke user location role",
        "Remove a business location role assignment from a user.",
    ),
    # User Business Permission Overrides
    PermissionSeed(
        PermissionCode.USER_BUSINESS_PERMISSIONS_VIEW,
        "View user business permissions",
        "List and view permission overrides for users within a business.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_PERMISSIONS_GRANT,
        "Grant user business permission",
        "Grant an individual permission override to a user within a business.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_PERMISSIONS_DENY,
        "Deny user business permission",
        "Create a permission denial override for a user within a business.",
    ),
    PermissionSeed(
        PermissionCode.USER_BUSINESS_PERMISSIONS_REVOKE,
        "Revoke user business permission override",
        "Remove an existing permission override row for a user within a business.",
    ),
    # Role Templates
    PermissionSeed(
        PermissionCode.ROLE_TEMPLATES_VIEW,
        "View role templates",
        "List and view role templates.",
    ),
    PermissionSeed(
        PermissionCode.ROLE_TEMPLATES_CREATE,
        "Create role templates",
        "Create a new role template.",
    ),
    PermissionSeed(
        PermissionCode.ROLE_TEMPLATES_UPDATE,
        "Update role templates",
        "Update a role template's details.",
    ),
    PermissionSeed(
        PermissionCode.ROLE_TEMPLATES_DELETE,
        "Delete role templates",
        "Delete a role template.",
    ),
    PermissionSeed(
        PermissionCode.ROLE_TEMPLATES_MANAGE_PERMISSIONS,
        "Manage role template permissions",
        "Assign or remove permissions from a role template.",
    ),
    # Auth / Security (view-only, except REVOKE actions)
    PermissionSeed(
        PermissionCode.VERIFICATION_CODES_VIEW,
        "View verification codes",
        "View OTP and email verification codes.",
    ),
    PermissionSeed(
        PermissionCode.REFRESH_TOKENS_VIEW,
        "View refresh tokens",
        "List and view refresh tokens.",
    ),
    PermissionSeed(
        PermissionCode.USER_SESSIONS_VIEW,
        "View user sessions",
        "List and view active user sessions.",
    ),
    PermissionSeed(
        PermissionCode.USER_SESSIONS_REVOKE,
        "Revoke user session",
        "Forcefully revoke a user's active session.",
    ),
    PermissionSeed(
        PermissionCode.TRUSTED_DEVICES_VIEW,
        "View trusted devices",
        "List and view trusted devices.",
    ),
    PermissionSeed(
        PermissionCode.TRUSTED_DEVICES_REVOKE,
        "Revoke trusted device",
        "Remove a trusted device registration.",
    ),
    PermissionSeed(
        PermissionCode.LOGIN_ATTEMPTS_VIEW,
        "View login attempts",
        "List and view login attempt history.",
    ),
    PermissionSeed(
        PermissionCode.AUTH_RISK_EVENTS_VIEW,
        "View auth risk events",
        "List and view authentication risk events.",
    ),
    # Platform Roles (driver/consumer/admin)
    PermissionSeed(
        PermissionCode.PLATFORM_ROLES_VIEW,
        "View platform roles",
        "List and view platform roles.",
    ),
    PermissionSeed(
        PermissionCode.PLATFORM_ROLES_CREATE,
        "Create platform roles",
        "Create a new platform role.",
    ),
    PermissionSeed(
        PermissionCode.PLATFORM_ROLES_UPDATE,
        "Update platform roles",
        "Update a platform role's details.",
    ),
    PermissionSeed(
        PermissionCode.PLATFORM_ROLES_DELETE,
        "Delete platform roles",
        "Delete a platform role (if no users assigned).",
    ),
    PermissionSeed(
        PermissionCode.PLATFORM_ROLES_ASSIGN_TO_USER,
        "Assign platform role to user",
        "Assign a platform role to a user.",
    ),
    PermissionSeed(
        PermissionCode.PLATFORM_ROLES_MANAGE_PERMISSIONS,
        "Manage platform role permissions",
        "Assign or remove permissions from a platform role.",
    ),
    PermissionSeed(
        PermissionCode.DELIVERY_VIEW_ASSIGNED,
        "View assigned delivery",
        "View assigned delivery details.",
    ),
    PermissionSeed(
        PermissionCode.DELIVERY_UPDATE_STATUS,
        "Update delivery status",
        "Update status of an active delivery.",
    ),
    PermissionSeed(
        PermissionCode.DELIVERY_CONFIRM_DROPOFF,
        "Confirm dropoff",
        "Confirm delivery dropoff to recipient.",
    ),
    PermissionSeed(
        PermissionCode.ORDER_CREATE,
        "Create order",
        "Place a new food or supply order.",
    ),
    PermissionSeed(
        PermissionCode.ORDER_VIEW_OWN,
        "View own orders",
        "View personal order history and status.",
    ),
    PermissionSeed(
        PermissionCode.ORDER_RATE,
        "Rate order",
        "Submit rating and review for a completed order.",
    ),
)


DEFAULT_PLATFORM_ROLE_PERMISSIONS: dict[str, list[PermissionCode]] = {
    "driver": [
        PermissionCode.DELIVERY_VIEW_ASSIGNED,
        PermissionCode.DELIVERY_UPDATE_STATUS,
        PermissionCode.DELIVERY_CONFIRM_DROPOFF,
    ],
    "consumer": [
        PermissionCode.ORDER_CREATE,
        PermissionCode.ORDER_VIEW_OWN,
        PermissionCode.ORDER_RATE,
    ],
    "admin": [
        # Coarse/legacy aliases — kept for backward compatibility
        PermissionCode.USERS_MANAGE,
        PermissionCode.ROLES_ASSIGN,
        PermissionCode.BUSINESS_MANAGE_ROLES,
        # Existing business-domain codes
        PermissionCode.POS_WRITE,
        PermissionCode.POS_REFUND,
        PermissionCode.INVENTORY_VIEW,
        PermissionCode.INVENTORY_ADJUST,
        PermissionCode.PROCUREMENT_CREATE,
        PermissionCode.PROCUREMENT_APPROVE,
        PermissionCode.PROCUREMENT_AUTO_ORDER_ENABLE,
        PermissionCode.AI_FORECAST_VIEW,
        PermissionCode.AI_RECOMMENDATION_APPROVE,
        PermissionCode.SUPPLIER_PRICE_MANAGE,
        PermissionCode.FARMER_SUPPLY_COMMITMENT_MANAGE,
        PermissionCode.DELIVERY_VIEW_ASSIGNED,
        PermissionCode.DELIVERY_UPDATE_STATUS,
        PermissionCode.DELIVERY_CONFIRM_DROPOFF,
        PermissionCode.ORDER_CREATE,
        PermissionCode.ORDER_VIEW_OWN,
        PermissionCode.ORDER_RATE,
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
        # Business Roles
        PermissionCode.BUSINESS_ROLES_VIEW,
        PermissionCode.BUSINESS_ROLES_CREATE,
        PermissionCode.BUSINESS_ROLES_UPDATE,
        PermissionCode.BUSINESS_ROLES_DELETE,
        PermissionCode.BUSINESS_ROLES_MANAGE_PERMISSIONS,
        # User Business Role Assignment
        PermissionCode.USER_BUSINESS_ROLES_VIEW,
        PermissionCode.USER_BUSINESS_ROLES_ASSIGN,
        PermissionCode.USER_BUSINESS_ROLES_REVOKE,
        # User Business Location Role Assignment
        PermissionCode.USER_BUSINESS_LOCATION_ROLES_VIEW,
        PermissionCode.USER_BUSINESS_LOCATION_ROLES_ASSIGN,
        PermissionCode.USER_BUSINESS_LOCATION_ROLES_REVOKE,
        # User Business Permission Overrides
        PermissionCode.USER_BUSINESS_PERMISSIONS_VIEW,
        PermissionCode.USER_BUSINESS_PERMISSIONS_GRANT,
        PermissionCode.USER_BUSINESS_PERMISSIONS_DENY,
        PermissionCode.USER_BUSINESS_PERMISSIONS_REVOKE,
        # Role Templates
        PermissionCode.ROLE_TEMPLATES_VIEW,
        PermissionCode.ROLE_TEMPLATES_CREATE,
        PermissionCode.ROLE_TEMPLATES_UPDATE,
        PermissionCode.ROLE_TEMPLATES_DELETE,
        PermissionCode.ROLE_TEMPLATES_MANAGE_PERMISSIONS,
        # Auth / Security
        PermissionCode.VERIFICATION_CODES_VIEW,
        PermissionCode.REFRESH_TOKENS_VIEW,
        PermissionCode.USER_SESSIONS_VIEW,
        PermissionCode.USER_SESSIONS_REVOKE,
        PermissionCode.TRUSTED_DEVICES_VIEW,
        PermissionCode.TRUSTED_DEVICES_REVOKE,
        PermissionCode.LOGIN_ATTEMPTS_VIEW,
        PermissionCode.AUTH_RISK_EVENTS_VIEW,
    ],
}


def seed_permissions(session: Session) -> None:
    for seed in PERMISSION_SEEDS:
        permission = session.exec(
            select(Permission).where(Permission.code == seed.code.value)
        ).one_or_none()
        if permission is None:
            session.add(
                Permission(
                    code=seed.code.value,
                    name=seed.name,
                    description=seed.description,
                    domain=seed.domain,
                    is_ai_sensitive=seed.is_ai_sensitive,
                    requires_human_approval=seed.requires_human_approval,
                )
            )
            continue

        permission.name = seed.name
        permission.description = seed.description
        permission.domain = seed.domain
        permission.is_ai_sensitive = seed.is_ai_sensitive
        permission.requires_human_approval = seed.requires_human_approval

    for role_name, perm_codes in DEFAULT_PLATFORM_ROLE_PERMISSIONS.items():
        platform_role = session.exec(
            select(PlatformRole).where(PlatformRole.name == role_name)
        ).one_or_none()
        if platform_role is None:
            platform_role = PlatformRole(name=role_name)
            session.add(platform_role)
            session.flush()

        for code in perm_codes:
            prp = session.exec(
                select(PlatformRolePermission).where(
                    PlatformRolePermission.platform_role_id == platform_role.id,
                    PlatformRolePermission.permission_code == code.value,
                )
            ).one_or_none()
            if prp is None:
                session.add(
                    PlatformRolePermission(
                        platform_role_id=platform_role.id,
                        permission_code=code.value,
                    )
                )

    session.commit()
