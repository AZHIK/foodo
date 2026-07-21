from typing import Any
from uuid import UUID

import pytest

from app.core.exceptions import ProtectedRoleEditRejectedError
from app.models import PermissionType
from app.services import audit_events
from app.services.business_actions import (
    record_business_created,
    record_permission_override_created,
    record_role_assignment,
    reject_protected_role_edit,
)

ACTOR_ID = UUID("00000000-0000-0000-0000-000000000001")
BUSINESS_ID = UUID("00000000-0000-0000-0000-000000000002")
USER_ID = UUID("00000000-0000-0000-0000-000000000003")
ROLE_ID = UUID("00000000-0000-0000-0000-000000000004")


@pytest.fixture
def published_events(monkeypatch: pytest.MonkeyPatch) -> list[tuple[str, dict[str, Any]]]:
    events: list[tuple[str, dict[str, Any]]] = []

    async def fake_publish_event(event_name: str, payload: dict[str, Any]) -> None:
        events.append((event_name, payload))

    monkeypatch.setattr(audit_events, "publish_event", fake_publish_event)
    return events


@pytest.mark.asyncio
async def test_role_assignment_publishes_audit_recorded(
    published_events: list[tuple[str, dict[str, Any]]],
) -> None:
    await record_role_assignment(
        actor_id=ACTOR_ID,
        business_id=BUSINESS_ID,
        user_id=USER_ID,
        business_role_id=ROLE_ID,
    )

    assert published_events == [
        (
            "audit.recorded",
            {
                "actor_id": str(ACTOR_ID),
                "actor_type": "user",
                "business_id": str(BUSINESS_ID),
                "action": "business_role.assigned",
                "resource_type": "user_business_role",
                "resource_id": str(USER_ID),
                "details": {
                    "user_id": str(USER_ID),
                    "business_role_id": str(ROLE_ID),
                },
            },
        )
    ]


@pytest.mark.asyncio
async def test_permission_override_created_publishes_audit_recorded(
    published_events: list[tuple[str, dict[str, Any]]],
) -> None:
    await record_permission_override_created(
        actor_id=ACTOR_ID,
        business_id=BUSINESS_ID,
        user_id=USER_ID,
        permission_code="pos.refund",
        permission_type=PermissionType.GRANT,
    )

    event_name, payload = published_events[0]
    assert event_name == "audit.recorded"
    assert payload["action"] == "business_permission_override.created"
    assert payload["business_id"] == str(BUSINESS_ID)
    assert payload["details"] == {
        "user_id": str(USER_ID),
        "permission_code": "pos.refund",
        "type": "grant",
    }


@pytest.mark.asyncio
async def test_protected_role_edit_rejection_publishes_audit_recorded(
    published_events: list[tuple[str, dict[str, Any]]],
) -> None:
    with pytest.raises(ProtectedRoleEditRejectedError):
        await reject_protected_role_edit(
            actor_id=ACTOR_ID,
            business_id=BUSINESS_ID,
            business_role_id=ROLE_ID,
            attempted_change="rename owner role",
        )

    event_name, payload = published_events[0]
    assert event_name == "audit.recorded"
    assert payload["action"] == "business_role.protected_edit_rejected"
    assert payload["resource_type"] == "business_role"
    assert payload["resource_id"] == str(ROLE_ID)
    assert payload["details"] == {"attempted_change": "rename owner role"}


@pytest.mark.asyncio
async def test_business_created_publishes_audit_recorded(
    published_events: list[tuple[str, dict[str, Any]]],
) -> None:
    await record_business_created(
        actor_id=ACTOR_ID,
        business_id=BUSINESS_ID,
        business_name="Dar Kitchen",
    )

    event_name, payload = published_events[0]
    assert event_name == "audit.recorded"
    assert payload["action"] == "business.created"
    assert payload["resource_type"] == "business"
    assert payload["resource_id"] == str(BUSINESS_ID)
    assert payload["details"] == {"name": "Dar Kitchen"}
