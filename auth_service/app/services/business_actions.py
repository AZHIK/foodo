from uuid import UUID

from app.core.exceptions import ProtectedRoleEditRejectedError
from app.models import PermissionType
from app.services.audit_events import publish_audit_recorded


async def record_business_created(
    *,
    actor_id: UUID | None,
    business_id: UUID,
    business_name: str,
) -> None:
    await publish_audit_recorded(
        actor_id=actor_id,
        actor_type="user" if actor_id is not None else "system",
        business_id=business_id,
        action="business.created",
        resource_type="business",
        resource_id=business_id,
        details={"name": business_name},
    )


async def record_role_assignment(
    *,
    actor_id: UUID | None,
    business_id: UUID,
    user_id: UUID,
    business_role_id: UUID,
) -> None:
    await publish_audit_recorded(
        actor_id=actor_id,
        actor_type="user" if actor_id is not None else "system",
        business_id=business_id,
        action="business_role.assigned",
        resource_type="user_business_role",
        resource_id=user_id,
        details={
            "user_id": str(user_id),
            "business_role_id": str(business_role_id),
        },
    )


async def record_permission_override_created(
    *,
    actor_id: UUID | None,
    business_id: UUID,
    user_id: UUID,
    permission_code: str,
    permission_type: PermissionType,
) -> None:
    await publish_audit_recorded(
        actor_id=actor_id,
        actor_type="user" if actor_id is not None else "system",
        business_id=business_id,
        action="business_permission_override.created",
        resource_type="user_business_permission",
        resource_id=user_id,
        details={
            "user_id": str(user_id),
            "permission_code": permission_code,
            "type": permission_type.value,
        },
    )


async def reject_protected_role_edit(
    *,
    actor_id: UUID | None,
    business_id: UUID,
    business_role_id: UUID,
    attempted_change: str,
) -> None:
    await publish_audit_recorded(
        actor_id=actor_id,
        actor_type="user" if actor_id is not None else "system",
        business_id=business_id,
        action="business_role.protected_edit_rejected",
        resource_type="business_role",
        resource_id=business_role_id,
        details={"attempted_change": attempted_change},
    )
    raise ProtectedRoleEditRejectedError("Protected business roles cannot be edited.")
