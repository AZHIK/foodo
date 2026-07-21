from dataclasses import dataclass

from sqlmodel import Session, select

from app.core.permission_codes import PermissionCode
from app.models import Permission


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
    PermissionSeed(
        PermissionCode.USERS_MANAGE,
        "Manage users",
        "Invite, suspend, and update users.",
    ),
    PermissionSeed(
        PermissionCode.ROLES_ASSIGN,
        "Assign roles",
        "Assign roles to users.",
    ),
    PermissionSeed(
        PermissionCode.BUSINESS_MANAGE_ROLES,
        "Manage business roles",
        "Create and update business roles and permissions.",
    ),
)


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

    session.commit()
