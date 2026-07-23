"""Integration tests for the businesses demo endpoint.

Tests GET /api/v1/businesses/{business_id}/roles — a demonstration endpoint
that proves require_business_permission end-to-end.

These tests use real JWT tokens (signed with the test private key) and hit
the full FastAPI app via the ASGI transport, so they exercise the complete
request path including dependency resolution.
"""

from uuid import uuid4

from httpx import AsyncClient
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.core.security import create_access_token
from app.models.user import UserCategory

_BUSINESS_ID = str(uuid4())


def _token_with_permission(
    business_id: str | None = _BUSINESS_ID,
    permissions: list[str] | None = None,
) -> str:
    """Build a business_user access token."""
    return create_access_token(
        subject=str(uuid4()),
        user_category=UserCategory.BUSINESS_USER.value,
        active_business_id=business_id,
        roles=["manager"],
        permissions=permissions or [],
        other_businesses=[],
    )


def _platform_staff_token() -> str:
    return create_access_token(
        subject=str(uuid4()),
        user_category=UserCategory.PLATFORM_STAFF.value,
        roles=["admin"],
        permissions=["*"],
    )


class TestBusinessRolesDemoEndpoint:
    """Integration tests for GET /api/v1/businesses/{business_id}/roles."""

    async def test_token_with_business_roles_view_permission_returns_200(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """A token with BUSINESS_ROLES_VIEW permission and matching business context succeeds."""
        biz_id = str(uuid4())
        token = _token_with_permission(
            business_id=biz_id,
            permissions=[str(PermissionCode.BUSINESS_ROLES_VIEW)],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}/roles",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert isinstance(data, list)

    async def test_token_missing_business_roles_view_permission_returns_403(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """A token without BUSINESS_ROLES_VIEW is rejected even with a valid business context."""
        biz_id = str(uuid4())
        token = _token_with_permission(
            business_id=biz_id,
            permissions=["inventory.view"],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}/roles",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403
        assert "business_roles.view" in resp.json()["detail"]

    async def test_token_with_no_business_context_returns_403(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """A token with the permission but no active business context is rejected."""
        biz_id = str(uuid4())
        token = _token_with_permission(
            business_id=None,
            permissions=[str(PermissionCode.BUSINESS_ROLES_VIEW)],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}/roles",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403
        assert "business context" in resp.json()["detail"].lower()

    async def test_token_context_mismatch_with_path_returns_403(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """Token active_business_id matches permission check, but differs from URL path."""
        token_business_id = str(uuid4())
        path_business_id = str(uuid4())  # different business

        token = _token_with_permission(
            business_id=token_business_id,
            permissions=[str(PermissionCode.BUSINESS_ROLES_VIEW)],
        )

        resp = await client.get(
            f"/api/v1/businesses/{path_business_id}/roles",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403
        assert "business context" in resp.json()["detail"].lower()

    async def test_no_authorization_header_returns_401(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """No token at all returns 401 (not 403)."""
        biz_id = str(uuid4())
        resp = await client.get(f"/api/v1/businesses/{biz_id}/roles")
        assert resp.status_code == 401

    async def test_wildcard_permission_token_returns_200(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """A token with '*' permissions (e.g. platform staff) passes the permission check.

        NOTE: The wildcard token also needs active_business_id set for the
        business-context gate to pass — platform staff tokens don't normally
        carry business context, so this test uses a synthetic token.
        """
        biz_id = str(uuid4())
        # Synthetic token: business_user category + wildcard permissions + business context.
        # (In practice, platform staff would use internal-staff endpoints, not this one.)
        token = create_access_token(
            subject=str(uuid4()),
            user_category=UserCategory.BUSINESS_USER.value,
            active_business_id=biz_id,
            roles=["super_admin"],
            permissions=["*"],
            other_businesses=[],
        )

        resp = await client.get(
            f"/api/v1/businesses/{biz_id}/roles",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200, resp.text
