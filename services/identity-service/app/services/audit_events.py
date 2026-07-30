from typing import Any
from uuid import UUID

from app.core.events import publish_event


async def publish_audit_recorded(
    *,
    actor_id: UUID | None,
    actor_type: str,
    business_id: UUID | None,
    action: str,
    resource_type: str,
    resource_id: UUID | str | None,
    details: dict[str, Any],
) -> None:
    await publish_event(
        "audit.recorded",
        {
            "actor_id": str(actor_id) if actor_id is not None else None,
            "actor_type": actor_type,
            "business_id": str(business_id) if business_id is not None else None,
            "action": action,
            "resource_type": resource_type,
            "resource_id": str(resource_id) if resource_id is not None else None,
            "details": details,
        },
    )
