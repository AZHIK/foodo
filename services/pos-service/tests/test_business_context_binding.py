"""Tests for the business-context-binding (Gap 1 fix from Inventory Service Stage 8.5).

Verifies that ``require_business_permission`` rejects tokens where the path's
``business_id`` does not match the token's ``active_business_id`` — even when the
permission code and business context are individually valid.

This test proves the Gap 1 fix is present and working from day one in POS
Service, mirroring the already-hardened version in Inventory Service's
``app/deps/auth.py`` (where the fix was implemented inventory-service-locally
and is now copied verbatim here).
"""

from uuid import UUID

import pytest
from fastapi import HTTPException

from app.deps.auth import require_business_permission


async def _call(dep_factory_result, claims: dict, **kwargs):
    """Call the inner function returned by a dependency factory."""
    return await dep_factory_result(claims, **kwargs)


class TestBusinessContextBinding:
    """Gap 1 fix: business-context binding at the dependency level.

    A token scoped to business X with the right permission code succeeds
    against an endpoint for business X, and is rejected for business Y.
    """

    async def test_business_x_token_succeeds_for_business_x(self) -> None:
        checker = require_business_permission("pos.write")
        biz_id = UUID("550e8400-e29b-41d4-a716-446655440000")
        claims = {
            "sub": "user-1",
            "user_category": "business_staff",
            "active_business_id": str(biz_id),
            "permissions": ["pos.write"],
        }
        result = await _call(checker, claims, business_id=biz_id)
        assert result == str(biz_id)

    async def test_business_x_token_fails_for_business_y(self) -> None:
        checker = require_business_permission("pos.write")
        biz_x = UUID("550e8400-e29b-41d4-a716-446655440000")
        biz_y = UUID("660e8400-e29b-41d4-a716-446655440001")
        claims = {
            "sub": "user-1",
            "user_category": "business_staff",
            "active_business_id": str(biz_x),
            "permissions": ["pos.write"],
        }
        with pytest.raises(HTTPException) as exc:
            await _call(checker, claims, business_id=biz_y)
        assert exc.value.status_code == 403
        assert "does not match" in exc.value.detail

    async def test_missing_business_context_rejected(self) -> None:
        checker = require_business_permission("pos.write")
        biz_id = UUID("550e8400-e29b-41d4-a716-446655440000")
        claims = {
            "sub": "user-1",
            "user_category": "business_staff",
            "permissions": ["pos.write"],
        }
        with pytest.raises(HTTPException) as exc:
            await _call(checker, claims, business_id=biz_id)
        assert exc.value.status_code == 403

    async def test_missing_permission_rejected(self) -> None:
        checker = require_business_permission("pos.refund")
        biz_id = UUID("550e8400-e29b-41d4-a716-446655440000")
        claims = {
            "sub": "user-1",
            "user_category": "business_staff",
            "active_business_id": str(biz_id),
            "permissions": ["pos.write"],
        }
        with pytest.raises(HTTPException) as exc:
            await _call(checker, claims, business_id=biz_id)
        assert exc.value.status_code == 403
