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

    # --- Users (platform staff) ---
    USERS_VIEW = "users.view"
    USERS_UPDATE = "users.update"
    USERS_DEACTIVATE = "users.deactivate"
    USERS_REACTIVATE = "users.reactivate"
    # Coarse/legacy alias — kept for backward compatibility with existing
    # seeds/roles. New code should prefer the specific codes above.
    USERS_MANAGE = "users.manage"

    # --- Groups (internal) ---
    GROUPS_VIEW = "groups.view"
    GROUPS_CREATE = "groups.create"
    GROUPS_UPDATE = "groups.update"
    GROUPS_DELETE = "groups.delete"
    GROUPS_ASSIGN_USER = "groups.assign_user"

    # --- Roles (internal) ---
    ROLES_VIEW = "roles.view"
    ROLES_CREATE = "roles.create"
    ROLES_UPDATE = "roles.update"
    ROLES_DELETE = "roles.delete"
    ROLES_ASSIGN_TO_USER = "roles.assign_to_user"
    ROLES_MANAGE_PERMISSIONS = "roles.manage_permissions"
    # Coarse/legacy alias — kept for backward compatibility with existing
    # seeds/roles. New code should prefer the specific codes above.
    ROLES_ASSIGN = "roles.assign"

    # --- Platform Roles (driver/consumer/admin) ---
    PLATFORM_ROLES_VIEW = "platform_roles.view"
    PLATFORM_ROLES_CREATE = "platform_roles.create"
    PLATFORM_ROLES_UPDATE = "platform_roles.update"
    PLATFORM_ROLES_DELETE = "platform_roles.delete"
    PLATFORM_ROLES_ASSIGN_TO_USER = "platform_roles.assign_to_user"
    PLATFORM_ROLES_MANAGE_PERMISSIONS = "platform_roles.manage_permissions"

    # --- Organizations ---
    ORGANIZATIONS_VIEW = "organizations.view"
    ORGANIZATIONS_CREATE = "organizations.create"
    ORGANIZATIONS_UPDATE = "organizations.update"
    ORGANIZATIONS_DELETE = "organizations.delete"

    # --- Businesses ---
    BUSINESSES_VIEW = "businesses.view"
    BUSINESSES_CREATE = "businesses.create"
    BUSINESSES_UPDATE = "businesses.update"
    BUSINESSES_DELETE = "businesses.delete"
    BUSINESSES_ASSIGN_TO_ORGANIZATION = "businesses.assign_to_organization"

    # --- Business Locations ---
    BUSINESS_LOCATIONS_VIEW = "business_locations.view"
    BUSINESS_LOCATIONS_CREATE = "business_locations.create"
    BUSINESS_LOCATIONS_UPDATE = "business_locations.update"
    BUSINESS_LOCATIONS_DELETE = "business_locations.delete"

    # --- Business Roles (per-business custom roles) ---
    BUSINESS_ROLES_VIEW = "business_roles.view"
    BUSINESS_ROLES_CREATE = "business_roles.create"
    BUSINESS_ROLES_UPDATE = "business_roles.update"
    BUSINESS_ROLES_DELETE = "business_roles.delete"
    BUSINESS_ROLES_MANAGE_PERMISSIONS = "business_roles.manage_permissions"
    # Coarse/legacy alias — kept for backward compatibility with existing
    # seeds/roles. New code should prefer the specific codes above.
    BUSINESS_MANAGE_ROLES = "business.manage_roles"

    # --- User Business Role Assignment ---
    USER_BUSINESS_ROLES_VIEW = "user_business_roles.view"
    USER_BUSINESS_ROLES_ASSIGN = "user_business_roles.assign"
    USER_BUSINESS_ROLES_REVOKE = "user_business_roles.revoke"

    # --- User Business Location Role Assignment ---
    USER_BUSINESS_LOCATION_ROLES_VIEW = "user_business_location_roles.view"
    USER_BUSINESS_LOCATION_ROLES_ASSIGN = "user_business_location_roles.assign"
    USER_BUSINESS_LOCATION_ROLES_REVOKE = "user_business_location_roles.revoke"

    # --- User Business Permission Overrides ---
    USER_BUSINESS_PERMISSIONS_VIEW = "user_business_permissions.view"
    USER_BUSINESS_PERMISSIONS_GRANT = "user_business_permissions.grant"
    USER_BUSINESS_PERMISSIONS_DENY = "user_business_permissions.deny"
    USER_BUSINESS_PERMISSIONS_REVOKE = "user_business_permissions.revoke"

    # --- Role Templates ---
    ROLE_TEMPLATES_VIEW = "role_templates.view"
    ROLE_TEMPLATES_CREATE = "role_templates.create"
    ROLE_TEMPLATES_UPDATE = "role_templates.update"
    ROLE_TEMPLATES_DELETE = "role_templates.delete"
    ROLE_TEMPLATES_MANAGE_PERMISSIONS = "role_templates.manage_permissions"

    # --- Auth / Security (view-only, except REVOKE actions) ---
    VERIFICATION_CODES_VIEW = "verification_codes.view"
    REFRESH_TOKENS_VIEW = "refresh_tokens.view"
    USER_SESSIONS_VIEW = "user_sessions.view"
    USER_SESSIONS_REVOKE = "user_sessions.revoke"
    TRUSTED_DEVICES_VIEW = "trusted_devices.view"
    TRUSTED_DEVICES_REVOKE = "trusted_devices.revoke"
    LOGIN_ATTEMPTS_VIEW = "login_attempts.view"
    AUTH_RISK_EVENTS_VIEW = "auth_risk_events.view"

    DELIVERY_VIEW_ASSIGNED = "delivery.view_assigned"
    DELIVERY_UPDATE_STATUS = "delivery.update_status"
    DELIVERY_CONFIRM_DROPOFF = "delivery.confirm_dropoff"
    ORDER_CREATE = "order.create"
    ORDER_VIEW_OWN = "order.view_own"
    ORDER_RATE = "order.rate"


def coerce_permission_code(code: str | PermissionCode) -> PermissionCode:
    if isinstance(code, PermissionCode):
        return code
    return PermissionCode(code)


def validate_permission_code(code: str | PermissionCode) -> None:
    coerce_permission_code(code)
