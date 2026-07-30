"""Read-only schema for the Permission model.

Permissions are seeded from the PermissionCode enum in app.core.permission_codes
and are not user-authorable.  No Create/Update schemas exist.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PermissionRead(BaseModel):
    """Full permission representation returned by the API.

    is_ai_sensitive, requires_human_approval, and domain are read-only/derived
    — they are never settable via a generic update schema because permissions
    are seeded from the code-level enum, not user-authored.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    description: str | None = None
    domain: str
    is_ai_sensitive: bool
    requires_human_approval: bool
    created_at: datetime
    updated_at: datetime
