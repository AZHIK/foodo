from enum import StrEnum


class PermissionCode(StrEnum):
    POS_WRITE = "pos.write"
    POS_REFUND = "pos.refund"
    INVENTORY_VIEW = "inventory.view"
    INVENTORY_ADJUST = "inventory.adjust"
    PROCUREMENT_CREATE = "procurement.create"
    PROCUREMENT_APPROVE = "procurement.approve"
    PROCUREMENT_AUTO_ORDER_ENABLE = "procurement.auto_order.enable"
    AI_FORECAST_VIEW = "ai.forecast.view"
    AI_RECOMMENDATION_APPROVE = "ai.recommendation.approve"
    SUPPLIER_PRICE_MANAGE = "supplier.price.manage"
    FARMER_SUPPLY_COMMITMENT_MANAGE = "farmer.supply_commitment.manage"
    USERS_MANAGE = "users.manage"
    ROLES_ASSIGN = "roles.assign"
    BUSINESS_MANAGE_ROLES = "business.manage_roles"


def coerce_permission_code(code: str | PermissionCode) -> PermissionCode:
    if isinstance(code, PermissionCode):
        return code
    return PermissionCode(code)


def validate_permission_code(code: str | PermissionCode) -> None:
    coerce_permission_code(code)
