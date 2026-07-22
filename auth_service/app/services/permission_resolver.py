from collections.abc import Iterable
from uuid import UUID

from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode, coerce_permission_code
from app.models import (
    PlatformRole,
    PlatformRolePermission,
    User,
    UserCategory,
    UserPlatformRole,
)


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


async def compute_platform_role_permissions(session: AsyncSession, user_id: UUID) -> set[str]:
    """Compute platform role permissions for a user.

    Queries platform_role_permissions via user_platform_roles.
    If no explicit user_platform_roles assignments exist, falls back to the
    PlatformRole matching the user's category (e.g. driver, consumer).
    """
    stmt = (
        select(PlatformRolePermission.permission_code)
        .join(
            UserPlatformRole,
            UserPlatformRole.platform_role_id == PlatformRolePermission.platform_role_id,  # type: ignore[arg-type]
        )
        .where(
            UserPlatformRole.user_id == user_id,
            UserPlatformRole.is_deleted == False,  # noqa: E712
            PlatformRolePermission.is_deleted == False,  # noqa: E712
        )
    )
    result = await session.exec(stmt)
    perms = set(result.all())

    if not perms:
        user = await session.get(User, user_id)
        if user and user.user_category:
            role_name = (
                user.user_category.value
                if isinstance(user.user_category, UserCategory)
                else user.user_category
            )
            fallback_stmt = (
                select(PlatformRolePermission.permission_code)
                .join(
                    PlatformRole,
                    PlatformRole.id == PlatformRolePermission.platform_role_id,  # type: ignore[arg-type]
                )
                .where(
                    PlatformRole.name == role_name,
                    PlatformRole.is_deleted == False,  # noqa: E712
                    PlatformRolePermission.is_deleted == False,  # noqa: E712
                )
            )
            fallback_result = await session.exec(fallback_stmt)
            perms = set(fallback_result.all())

    return perms
