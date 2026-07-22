"""Business-related API endpoints.

DEMONSTRATION ENDPOINT — NOT A PRODUCTION FEATURE DELIVERABLE
--------------------------------------------------------------
This module exists solely to demonstrate the ``require_business_permission``
dependency pattern end-to-end.  The single endpoint below (
``GET /api/v1/businesses/{business_id}/roles``) shows exactly how a
future microservice should:

  1. Gate a business-scoped route behind ``require_business_permission``.
  2. Receive the resolved ``active_business_id`` directly from the
     dependency return value (no manual claim extraction needed).
  3. Verify the caller's token context matches the path parameter.

When the Roles & Permissions management service is built out fully, this
stub should be replaced by the real implementation in that service.
"""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.permission_codes import PermissionCode
from app.deps.permissions import require_business_permission

router = APIRouter(prefix="/api/v1/businesses", tags=["Businesses (demo)"])


# ---------------------------------------------------------------------------
# DEMONSTRATION ENDPOINT
# Purpose: prove require_business_permission end-to-end.
# Remove / replace when the real role-management service is built.
# ---------------------------------------------------------------------------


@router.get("/{business_id}/roles")
async def list_business_roles(
    business_id: UUID,
    # require_business_permission chains context + permission checks and returns
    # active_business_id so the handler can scope the query without re-reading claims.
    caller_business_id: str = Depends(require_business_permission(PermissionCode.ROLES_ASSIGN)),
) -> dict[str, Any]:
    """[DEMO] List roles for a business.

    Requires:
      - A valid business context token (``active_business_id`` must be set).
      - The ``roles.assign`` permission in the token's permission list.
      - The token's ``active_business_id`` must match the path ``business_id``.

    This is a demonstration stub. In production this would query the DB for
    actual role records and return a proper response schema.
    """
    # Cross-check: the caller's active business context must match the
    # business_id in the URL path.  This prevents a user with roles.assign in
    # Business A from hitting the endpoint for Business B with a context-
    # switched token they don't own.
    if str(business_id) != caller_business_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token business context does not match the requested business",
        )

    # DEMO — return a placeholder response instead of a real DB query.
    return {
        "business_id": str(business_id),
        "roles": [],
        "_note": "Demonstration stub — replace with real DB query in production.",
    }
