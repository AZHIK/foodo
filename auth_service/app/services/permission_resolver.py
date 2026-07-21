from collections.abc import Iterable

from app.core.permission_codes import PermissionCode, coerce_permission_code


def resolve_effective_permissions(
    *,
    business_role_permissions: Iterable[str | PermissionCode],
    location_role_permissions: Iterable[str | PermissionCode],
    grants: Iterable[str | PermissionCode],
    denies: Iterable[str | PermissionCode],
) -> set[PermissionCode]:
    """effective_permissions(user, business, location) =
          business_role_permissions(user, business)
        ∪ location_role_permissions(user, business, location)
        ∪ grants(user, business)
        − denies(user, business)

    Union role-derived permissions from both business-wide and location-scoped
    role assignments, then apply grant overrides, then remove anything in deny
    overrides. Deny always wins last, even over a grant for the same code.
    """
    role_permissions = {
        coerce_permission_code(permission) for permission in business_role_permissions
    } | {coerce_permission_code(permission) for permission in location_role_permissions}
    granted_permissions = {coerce_permission_code(permission) for permission in grants}
    denied_permissions = {coerce_permission_code(permission) for permission in denies}
    return (role_permissions | granted_permissions) - denied_permissions
