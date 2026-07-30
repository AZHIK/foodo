from dataclasses import dataclass
from uuid import UUID

from app.core.permission_codes import PermissionCode
from app.models import PermissionType
from app.services.permission_resolver import resolve_effective_permissions

BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000001")
OTHER_BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000002")
LOCATION_ID = UUID("00000000-0000-0000-0000-000000000003")
OTHER_LOCATION_ID = UUID("00000000-0000-0000-0000-000000000004")


@dataclass(frozen=True)
class ScopedPermission:
    code: PermissionCode
    business_id: UUID
    location_id: UUID | None = None
    override_type: PermissionType | None = None


def collect_for_scope(
    permissions: list[ScopedPermission],
    business_id: UUID,
    location_id: UUID,
) -> set[PermissionCode]:
    return resolve_effective_permissions(
        business_role_permissions=[
            permission.code
            for permission in permissions
            if permission.business_id == business_id
            and permission.location_id is None
            and permission.override_type is None
        ],
        location_role_permissions=[
            permission.code
            for permission in permissions
            if permission.business_id == business_id
            and permission.location_id == location_id
            and permission.override_type is None
        ],
        grants=[
            permission.code
            for permission in permissions
            if permission.business_id == business_id
            and permission.location_id is None
            and permission.override_type is PermissionType.GRANT
        ],
        denies=[
            permission.code
            for permission in permissions
            if permission.business_id == business_id
            and permission.location_id is None
            and permission.override_type is PermissionType.DENY
        ],
    )


def test_business_role_permission_is_included() -> None:
    result = resolve_effective_permissions(
        business_role_permissions=[PermissionCode.POS_WRITE],
        location_role_permissions=[],
        grants=[],
        denies=[],
    )

    assert result == {PermissionCode.POS_WRITE}


def test_location_scoped_role_permission_is_included() -> None:
    result = resolve_effective_permissions(
        business_role_permissions=[],
        location_role_permissions=[PermissionCode.INVENTORY_VIEW],
        grants=[],
        denies=[],
    )

    assert result == {PermissionCode.INVENTORY_VIEW}


def test_duplicate_permission_from_business_and_location_is_included_once() -> None:
    result = resolve_effective_permissions(
        business_role_permissions=[PermissionCode.INVENTORY_VIEW],
        location_role_permissions=[PermissionCode.INVENTORY_VIEW],
        grants=[],
        denies=[],
    )

    assert result == {PermissionCode.INVENTORY_VIEW}


def test_grant_override_adds_permission_not_present_in_roles() -> None:
    result = resolve_effective_permissions(
        business_role_permissions=[],
        location_role_permissions=[],
        grants=[PermissionCode.POS_REFUND],
        denies=[],
    )

    assert result == {PermissionCode.POS_REFUND}


def test_deny_override_removes_permission_present_via_role() -> None:
    result = resolve_effective_permissions(
        business_role_permissions=[PermissionCode.POS_REFUND],
        location_role_permissions=[],
        grants=[],
        denies=[PermissionCode.POS_REFUND],
    )

    assert result == set()


def test_deny_overrides_grant_for_same_code() -> None:
    result = resolve_effective_permissions(
        business_role_permissions=[],
        location_role_permissions=[],
        grants=[PermissionCode.PROCUREMENT_APPROVE],
        denies=[PermissionCode.PROCUREMENT_APPROVE],
    )

    assert result == set()


def test_other_business_and_location_permissions_do_not_leak() -> None:
    result = collect_for_scope(
        [
            ScopedPermission(PermissionCode.POS_WRITE, BUSINESS_ID),
            ScopedPermission(PermissionCode.INVENTORY_VIEW, OTHER_BUSINESS_ID),
            ScopedPermission(PermissionCode.PROCUREMENT_CREATE, BUSINESS_ID, LOCATION_ID),
            ScopedPermission(PermissionCode.PROCUREMENT_APPROVE, BUSINESS_ID, OTHER_LOCATION_ID),
            ScopedPermission(
                PermissionCode.AI_FORECAST_VIEW,
                OTHER_BUSINESS_ID,
                override_type=PermissionType.GRANT,
            ),
        ],
        BUSINESS_ID,
        LOCATION_ID,
    )

    assert result == {
        PermissionCode.POS_WRITE,
        PermissionCode.PROCUREMENT_CREATE,
    }
