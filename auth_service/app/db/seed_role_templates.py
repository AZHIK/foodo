"""Seed role_templates and role_template_permissions with Owner templates.

One owner template per business_type (restaurant, supplier, farmer, distributor,
platform_operator).  Each template gets a reasonable starting set of permission
codes drawn exclusively from the existing PermissionCode enum.

Non-owner templates (cashier, kitchen staff, supplier sales admin, farm
coordinator, etc.) are deliberately deferred — only Owner templates are
seeded here.
"""

from dataclasses import dataclass

from sqlmodel import Session, select

from app.core.permission_codes import PermissionCode
from app.models import RoleTemplate, RoleTemplatePermission


@dataclass(frozen=True)
class RoleTemplateSeed:
    name: str
    business_type: str
    is_owner_template: bool = True
    description: str = ""
    permissions: tuple[PermissionCode, ...] = ()


# ── Shared permission sets reused across business types ────────────────

_BUSINESS_ADMIN_PERMS: tuple[PermissionCode, ...] = (
    PermissionCode.BUSINESSES_VIEW,
    PermissionCode.BUSINESSES_UPDATE,
    PermissionCode.BUSINESS_ROLES_VIEW,
    PermissionCode.BUSINESS_ROLES_CREATE,
    PermissionCode.BUSINESS_ROLES_UPDATE,
    PermissionCode.BUSINESS_ROLES_DELETE,
    PermissionCode.BUSINESS_ROLES_MANAGE_PERMISSIONS,
    PermissionCode.USER_BUSINESS_ROLES_VIEW,
    PermissionCode.USER_BUSINESS_ROLES_ASSIGN,
    PermissionCode.USER_BUSINESS_ROLES_REVOKE,
    PermissionCode.BUSINESS_LOCATIONS_VIEW,
    PermissionCode.BUSINESS_LOCATIONS_CREATE,
    PermissionCode.BUSINESS_LOCATIONS_UPDATE,
    PermissionCode.BUSINESS_LOCATIONS_DELETE,
    PermissionCode.ORGANIZATIONS_VIEW,
    PermissionCode.INVENTORY_VIEW,
)

_INVENTORY_ADJUST: tuple[PermissionCode, ...] = (PermissionCode.INVENTORY_ADJUST,)

_PROCUREMENT: tuple[PermissionCode, ...] = (
    PermissionCode.PROCUREMENT_CREATE,
    PermissionCode.PROCUREMENT_APPROVE,
)

_PROCUREMENT_AUTO: tuple[PermissionCode, ...] = (PermissionCode.PROCUREMENT_AUTO_ORDER_ENABLE,)

_AI: tuple[PermissionCode, ...] = (
    PermissionCode.AI_FORECAST_VIEW,
    PermissionCode.AI_RECOMMENDATION_APPROVE,
)

_POS: tuple[PermissionCode, ...] = (
    PermissionCode.POS_WRITE,
    PermissionCode.POS_REFUND,
)

_SUPPLIER: tuple[PermissionCode, ...] = (PermissionCode.SUPPLIER_PRICE_MANAGE,)

_FARMER: tuple[PermissionCode, ...] = (PermissionCode.FARMER_SUPPLY_COMMITMENT_MANAGE,)

_PLATFORM_FULL: tuple[PermissionCode, ...] = (
    PermissionCode.USERS_VIEW,
    PermissionCode.USERS_UPDATE,
    PermissionCode.ORGANIZATIONS_CREATE,
    PermissionCode.ORGANIZATIONS_UPDATE,
    PermissionCode.ORGANIZATIONS_DELETE,
    PermissionCode.ROLE_TEMPLATES_VIEW,
    PermissionCode.ROLE_TEMPLATES_CREATE,
    PermissionCode.ROLE_TEMPLATES_UPDATE,
    PermissionCode.ROLE_TEMPLATES_DELETE,
    PermissionCode.ROLE_TEMPLATES_MANAGE_PERMISSIONS,
    PermissionCode.BUSINESSES_CREATE,
    PermissionCode.BUSINESSES_DELETE,
    PermissionCode.BUSINESSES_ASSIGN_TO_ORGANIZATION,
    PermissionCode.USER_BUSINESS_PERMISSIONS_VIEW,
    PermissionCode.USER_BUSINESS_PERMISSIONS_GRANT,
    PermissionCode.USER_BUSINESS_PERMISSIONS_DENY,
    PermissionCode.USER_BUSINESS_PERMISSIONS_REVOKE,
    PermissionCode.VERIFICATION_CODES_VIEW,
    PermissionCode.REFRESH_TOKENS_VIEW,
    PermissionCode.USER_SESSIONS_VIEW,
    PermissionCode.USER_SESSIONS_REVOKE,
)

# ── Seed definitions ───────────────────────────────────────────────────

ROLE_TEMPLATE_SEEDS: tuple[RoleTemplateSeed, ...] = (
    RoleTemplateSeed(
        name="restaurant_owner",
        business_type="restaurant",
        description="Restaurant owner — full operational control.",
        permissions=(
            _BUSINESS_ADMIN_PERMS
            + _INVENTORY_ADJUST
            + _PROCUREMENT
            + _PROCUREMENT_AUTO
            + _AI
            + _POS
        ),
    ),
    RoleTemplateSeed(
        name="supplier_owner",
        business_type="supplier",
        description="Supplier owner — full supplier operational control.",
        permissions=(_BUSINESS_ADMIN_PERMS + _INVENTORY_ADJUST + _PROCUREMENT + _SUPPLIER),
    ),
    RoleTemplateSeed(
        name="farmer_owner",
        business_type="farmer",
        description="Farmer owner — full farm operational control.",
        permissions=(_BUSINESS_ADMIN_PERMS + _INVENTORY_ADJUST + _FARMER),
    ),
    RoleTemplateSeed(
        name="distributor_owner",
        business_type="distributor",
        description="Distributor owner — full distribution operational control.",
        permissions=(_BUSINESS_ADMIN_PERMS + _INVENTORY_ADJUST + _PROCUREMENT),
    ),
    RoleTemplateSeed(
        name="platform_operator_owner",
        business_type="platform_operator",
        description="Platform operator — full control across all platform businesses.",
        permissions=(
            _BUSINESS_ADMIN_PERMS
            + _INVENTORY_ADJUST
            + _PROCUREMENT
            + _PROCUREMENT_AUTO
            + _AI
            + _POS
            + _SUPPLIER
            + _FARMER
            + _PLATFORM_FULL
        ),
    ),
)


def seed_role_templates(session: Session) -> None:
    for seed in ROLE_TEMPLATE_SEEDS:
        template = session.exec(
            select(RoleTemplate).where(RoleTemplate.name == seed.name)
        ).one_or_none()

        if template is None:
            template = RoleTemplate(
                name=seed.name,
                description=seed.description,
                business_type=seed.business_type,
                is_owner_template=seed.is_owner_template,
            )
            session.add(template)
            session.flush()

        # Upsert permissions: add any that are missing, leave existing ones.
        existing = {
            rtp.permission_code
            for rtp in session.exec(
                select(RoleTemplatePermission).where(
                    RoleTemplatePermission.role_template_id == template.id,
                )
            ).all()
        }

        for code in seed.permissions:
            if code.value not in existing:
                session.add(
                    RoleTemplatePermission(
                        role_template_id=template.id,
                        permission_code=code.value,
                    )
                )

    session.commit()
