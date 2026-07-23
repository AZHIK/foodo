"""Unit tests for app/deps/permissions.py.

These tests exercise the dependency logic directly by constructing fake
claims dicts and calling the inner ``_check_*`` coroutines.  No database
or HTTP client is required — each test is a pure async function that calls
the returned coroutine with a hand-crafted claims dict.

Strategy: each factory (e.g. ``require_permission``) returns an inner
async function.  We call that inner function with a fake ``claims`` dict,
bypassing FastAPI's dependency-injection machinery entirely.  This lets us
cover all branch paths without spinning up the app.
"""

import pytest
from fastapi import HTTPException

from app.core.permission_codes import PermissionCode
from app.deps.permissions import (
    require_all_permissions,
    require_any_permission,
    require_business_context,
    require_business_permission,
    require_permission,
    require_platform_staff,
)

# ─── helpers ───────────────────────────────────────────────────────────────


def _business_claims(
    permissions: list[str] | None = None,
    active_business_id: str | None = "biz-123",
) -> dict:
    return {
        "sub": "user-uuid-1",
        "user_category": "business_user",
        "active_business_id": active_business_id,
        "permissions": permissions or [],
        "roles": [],
    }


def _platform_staff_claims(permissions: list[str] | None = None) -> dict:
    return {
        "sub": "staff-uuid-1",
        "user_category": "platform_staff",
        "group": "ops",
        "permissions": permissions or [],
        "roles": ["admin"],
    }


async def _call(dep_factory_result, claims: dict):
    """Invoke the inner coroutine returned by a dependency factory."""
    return await dep_factory_result(claims)


# ═══════════════════════════════════════════════════════════════════════════
# 1. require_permission — single permission
# ═══════════════════════════════════════════════════════════════════════════


class TestRequirePermission:
    async def test_allows_token_with_permission_present(self) -> None:
        checker = require_permission(PermissionCode.ROLES_ASSIGN)
        claims = _business_claims(permissions=["roles.assign", "inventory.view"])
        result = await _call(checker, claims)
        assert result is claims  # returns claims unchanged

    async def test_rejects_token_missing_permission(self) -> None:
        checker = require_permission(PermissionCode.ROLES_ASSIGN)
        claims = _business_claims(permissions=["inventory.view"])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "roles.assign" in exc_info.value.detail

    async def test_allows_wildcard_permission(self) -> None:
        """A token carrying '*' should pass any single-permission check."""
        checker = require_permission(PermissionCode.INVENTORY_ADJUST)
        claims = _platform_staff_claims(permissions=["*"])
        result = await _call(checker, claims)
        assert result is claims

    async def test_rejects_empty_permissions_list(self) -> None:
        checker = require_permission(PermissionCode.POS_WRITE)
        claims = _business_claims(permissions=[])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_rejects_token_with_no_permissions_key(self) -> None:
        checker = require_permission(PermissionCode.POS_WRITE)
        # Simulate a driver/consumer token that has no 'permissions' key at all
        claims = {"sub": "u", "user_category": "driver", "platform_role": "driver"}
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_invalid_permission_string_raises_value_error_at_factory_time(
        self,
    ) -> None:
        """A typo'd permission string must fail loudly at factory-call time,
        not silently at request time."""
        with pytest.raises(ValueError):
            require_permission("this.does.not.exist.in.the.enum")

    async def test_accepts_raw_string_matching_enum_member(self) -> None:
        """A raw string that matches a PermissionCode value is accepted."""
        checker = require_permission("roles.assign")  # same value as ROLES_ASSIGN
        claims = _business_claims(permissions=["roles.assign"])
        result = await _call(checker, claims)
        assert result is claims

    # ── Remap regression: coarse ROLES_ASSIGN vs specific BUSINESS_ROLES_VIEW ──

    async def test_remap_business_roles_view_rejects_coarse_roles_assign(self) -> None:
        """Endpoint now requires BUSINESS_ROLES_VIEW; coarse ROLES_ASSIGN alone
        must NOT satisfy the check (proves the remap in businesses.py took effect)."""
        checker = require_permission(PermissionCode.BUSINESS_ROLES_VIEW)
        claims = _business_claims(permissions=["roles.assign"])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "business_roles.view" in exc_info.value.detail

    async def test_remap_business_roles_view_accepts_specific_code(self) -> None:
        """A token with the new specific BUSINESS_ROLES_VIEW is accepted."""
        checker = require_permission(PermissionCode.BUSINESS_ROLES_VIEW)
        claims = _business_claims(permissions=["business_roles.view"])
        result = await _call(checker, claims)
        assert result is claims


# ═══════════════════════════════════════════════════════════════════════════
# 2. require_any_permission
# ═══════════════════════════════════════════════════════════════════════════


class TestRequireAnyPermission:
    async def test_allows_when_at_least_one_present(self) -> None:
        checker = require_any_permission(
            PermissionCode.INVENTORY_VIEW, PermissionCode.INVENTORY_ADJUST
        )
        claims = _business_claims(permissions=["inventory.view"])
        result = await _call(checker, claims)
        assert result is claims

    async def test_allows_when_all_present(self) -> None:
        checker = require_any_permission(
            PermissionCode.INVENTORY_VIEW, PermissionCode.INVENTORY_ADJUST
        )
        claims = _business_claims(permissions=["inventory.view", "inventory.adjust"])
        result = await _call(checker, claims)
        assert result is claims

    async def test_rejects_when_none_present(self) -> None:
        checker = require_any_permission(
            PermissionCode.INVENTORY_VIEW, PermissionCode.INVENTORY_ADJUST
        )
        claims = _business_claims(permissions=["pos.write", "roles.assign"])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_rejects_empty_permissions(self) -> None:
        checker = require_any_permission(PermissionCode.POS_WRITE, PermissionCode.POS_REFUND)
        claims = _business_claims(permissions=[])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_allows_wildcard(self) -> None:
        checker = require_any_permission(PermissionCode.AI_FORECAST_VIEW)
        claims = _platform_staff_claims(permissions=["*"])
        result = await _call(checker, claims)
        assert result is claims

    async def test_invalid_code_raises_at_factory_time(self) -> None:
        with pytest.raises(ValueError):
            require_any_permission(PermissionCode.POS_WRITE, "not.a.real.permission")


# ═══════════════════════════════════════════════════════════════════════════
# 3. require_all_permissions
# ═══════════════════════════════════════════════════════════════════════════


class TestRequireAllPermissions:
    async def test_allows_when_all_present(self) -> None:
        checker = require_all_permissions(
            PermissionCode.PROCUREMENT_CREATE, PermissionCode.PROCUREMENT_APPROVE
        )
        claims = _business_claims(permissions=["procurement.create", "procurement.approve"])
        result = await _call(checker, claims)
        assert result is claims

    async def test_rejects_when_one_missing(self) -> None:
        checker = require_all_permissions(
            PermissionCode.PROCUREMENT_CREATE, PermissionCode.PROCUREMENT_APPROVE
        )
        claims = _business_claims(permissions=["procurement.create"])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "procurement.approve" in exc_info.value.detail

    async def test_rejects_when_all_missing(self) -> None:
        checker = require_all_permissions(
            PermissionCode.PROCUREMENT_CREATE, PermissionCode.PROCUREMENT_APPROVE
        )
        claims = _business_claims(permissions=["pos.write"])
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_allows_wildcard(self) -> None:
        checker = require_all_permissions(PermissionCode.USERS_MANAGE, PermissionCode.ROLES_ASSIGN)
        claims = _platform_staff_claims(permissions=["*"])
        result = await _call(checker, claims)
        assert result is claims

    async def test_invalid_code_raises_at_factory_time(self) -> None:
        with pytest.raises(ValueError):
            require_all_permissions("not.valid", PermissionCode.POS_WRITE)


# ═══════════════════════════════════════════════════════════════════════════
# 4. require_business_context
# ═══════════════════════════════════════════════════════════════════════════


class TestRequireBusinessContext:
    async def test_allows_token_with_active_business_id(self) -> None:
        checker = require_business_context()
        claims = _business_claims(active_business_id="biz-abc-123")
        result = await _call(checker, claims)
        assert result == "biz-abc-123"  # returns the ID, not claims

    async def test_rejects_token_with_none_business_id(self) -> None:
        checker = require_business_context()
        claims = _business_claims(active_business_id=None)
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "business context" in exc_info.value.detail.lower()

    async def test_rejects_token_with_missing_business_id_key(self) -> None:
        checker = require_business_context()
        # A driver token has no active_business_id key at all
        claims = {"sub": "u", "user_category": "driver", "platform_role": "driver"}
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_rejects_empty_string_business_id(self) -> None:
        checker = require_business_context()
        claims = _business_claims(active_business_id="")
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_returns_correct_business_id_value(self) -> None:
        checker = require_business_context()
        expected_id = "some-uuid-string-here"
        claims = _business_claims(active_business_id=expected_id)
        returned = await _call(checker, claims)
        assert returned == expected_id


# ═══════════════════════════════════════════════════════════════════════════
# 5. require_business_permission
# ═══════════════════════════════════════════════════════════════════════════


class TestRequireBusinessPermission:
    async def test_allows_token_with_context_and_permission(self) -> None:
        checker = require_business_permission(PermissionCode.ROLES_ASSIGN)
        claims = _business_claims(permissions=["roles.assign"], active_business_id="biz-xyz")
        result = await _call(checker, claims)
        assert result == "biz-xyz"  # returns active_business_id

    async def test_rejects_when_context_missing_even_if_permission_present(self) -> None:
        """Business context check must run first; permission alone is not enough."""
        checker = require_business_permission(PermissionCode.ROLES_ASSIGN)
        claims = _business_claims(
            permissions=["roles.assign"],
            active_business_id=None,  # no context
        )
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        # Should be the context message, not the permission message
        assert "business context" in exc_info.value.detail.lower()

    async def test_rejects_when_context_present_but_permission_missing(self) -> None:
        checker = require_business_permission(PermissionCode.ROLES_ASSIGN)
        claims = _business_claims(permissions=["inventory.view"], active_business_id="biz-xyz")
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "roles.assign" in exc_info.value.detail

    async def test_rejects_when_both_context_and_permission_missing(self) -> None:
        checker = require_business_permission(PermissionCode.ROLES_ASSIGN)
        claims = _business_claims(permissions=[], active_business_id=None)
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        # Context check runs first → context-specific message
        assert exc_info.value.status_code == 403
        assert "business context" in exc_info.value.detail.lower()

    # ── Remap regression: coarse ROLES_ASSIGN vs specific BUSINESS_ROLES_VIEW ──

    async def test_remap_business_permission_rejects_coarse_roles_assign(self) -> None:
        """require_business_permission now checks BUSINESS_ROLES_VIEW;
        coarse ROLES_ASSIGN must NOT satisfy it."""
        checker = require_business_permission(PermissionCode.BUSINESS_ROLES_VIEW)
        claims = _business_claims(
            permissions=["roles.assign"],
            active_business_id="biz-xyz",
        )
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "business_roles.view" in exc_info.value.detail

    async def test_remap_business_permission_accepts_new_specific_code(self) -> None:
        """A business-context token with BUSINESS_ROLES_VIEW is accepted."""
        checker = require_business_permission(PermissionCode.BUSINESS_ROLES_VIEW)
        claims = _business_claims(
            permissions=["business_roles.view"],
            active_business_id="biz-xyz",
        )
        result = await _call(checker, claims)
        assert result == "biz-xyz"

    async def test_invalid_code_raises_at_factory_time(self) -> None:
        with pytest.raises(ValueError):
            require_business_permission("not.a.real.code")


# ═══════════════════════════════════════════════════════════════════════════
# 6. require_platform_staff
# ═══════════════════════════════════════════════════════════════════════════


class TestRequirePlatformStaff:
    async def test_allows_platform_staff_token(self) -> None:
        checker = require_platform_staff()
        claims = _platform_staff_claims()
        result = await _call(checker, claims)
        assert result is claims

    async def test_rejects_business_user_token(self) -> None:
        checker = require_platform_staff()
        claims = _business_claims()
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
        assert "platform staff" in exc_info.value.detail.lower()

    async def test_rejects_driver_token(self) -> None:
        checker = require_platform_staff()
        claims = {"sub": "u", "user_category": "driver", "platform_role": "driver"}
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_rejects_consumer_token(self) -> None:
        checker = require_platform_staff()
        claims = {"sub": "u", "user_category": "consumer", "platform_role": "consumer"}
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403

    async def test_rejects_missing_user_category(self) -> None:
        checker = require_platform_staff()
        claims = {"sub": "u"}  # malformed — no user_category
        with pytest.raises(HTTPException) as exc_info:
            await _call(checker, claims)
        assert exc_info.value.status_code == 403
