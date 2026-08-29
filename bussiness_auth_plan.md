# Plan: session/permission context for `business_staff` and `business_store_staff`

## Context

`UserCategory` was recently renamed on disk: `BUSINESS_USER` no longer exists, replaced by `BUSINESS_STAFF` and a new `BUSINESS_STORE_STAFF` (plus unrelated future placeholders `FARMER`, `LOGISTICS_PROVIDER`, `QA` — out of scope). This left identity-service broken: 16 files still reference `UserCategory.BUSINESS_USER`, including a class-level default in `schemas/auth.py` that is evaluated at import time — the service currently crashes on startup.

Separately, the user wants the equivalent of "session middleware" tying each of the three in-scope categories to the right scope, checked on every request:
- `platform_staff` — just a session, no extra scoping (already works, no change).
- `business_staff` — scoped to one `active_business_id` at a time (already exists via JWT claims + `require_business_context`/`require_business_permission`; only needs the rename fix).
- `business_store_staff` — new: must be scoped to exactly one store. Since store IDs are globally unique, checking `store_id` alone identifies both store and business.

This system has no ASGI middleware or gateway — every service independently verifies the same RS256 JWT and enforces scope via FastAPI `Depends()` dependency factories, copy-pasted verbatim across identity-service/inventory-service/pos-service (a documented, deliberate pattern). This plan extends that exact pattern rather than introducing new middleware infrastructure.

**Decisions locked in with the user:**
- `business_store_staff` is single-store only for now — no store-switch endpoint. `active_store_id` (+ derived `active_business_id`) is resolved automatically at login/refresh from the user's one `UserStoreRole` row.
- Include new store-staff assignment endpoints (nothing today creates a `UserStoreRole` row, so the feature would be untestable otherwise).
- Block `business_store_staff` from `list_stores`/`create_store` (business-wide store operations) — they stay confined to their one store everywhere.
- Add a guard so `POST /auth/context/switch` rejects non-`business_staff` callers (closes a theoretical privilege-escalation path).
- Cross-service test files with a plain `"business_user"` string literal (not the enum) get updated too, for full consistency, even though they're not required for the startup fix.

---

## 1. `BUSINESS_USER` → `BUSINESS_STAFF` rename cascade (required fix, service is currently broken)

**Production code (3 files):**
- `services/identity-service/app/schemas/auth.py:130` — `BusinessUserTokenClaims.user_category` default → `UserCategory.BUSINESS_STAFF`; rename class to `BusinessStaffTokenClaims`; add new `StoreStaffTokenClaims` (see §3); update module docstring line 1. Leave `BusinessUserRegisterRequest` class name as-is (registration payload name, also used by driver/consumer self-registration — renaming it would be misleading either way).
- `services/identity-service/app/api/v1/endpoints/auth.py` — lines 110, 158, 221, 691, 842: `UserCategory.BUSINESS_USER` → `UserCategory.BUSINESS_STAFF` (lines 110/691/842 get folded into the three-way split in §4 anyway). Update the comment at lines 150-153.
- `services/identity-service/app/api/v1/endpoints/business_rbac.py` — line 337, 359: `UserCategory.BUSINESS_USER` → `UserCategory.BUSINESS_STAFF`; keep this an exact-match guard against `BUSINESS_STAFF` only (a `business_store_staff` user must go through the new store-scoped assignment endpoint in §6, not this one). Update error string at lines 362-365.

**Test files (13 files, mechanical `UserCategory.BUSINESS_USER` → `UserCategory.BUSINESS_STAFF`):**
`tests/models/test_models_stage1.py:63` (also fix the `.value == "business_user"` string), `tests/services/test_store_setting.py`, `tests/api/test_businesses.py`, `tests/api/test_businesses_demo.py`, `tests/api/test_admin_internal_rbac.py`, `tests/api/test_auth_platform.py`, `tests/api/test_auth_recording.py`, `tests/services/test_business_seeded_role_flow.py`, `tests/api/test_business_rbac.py` (incl. line 562 assertion + check for the changed error-string literal), `tests/services/test_business_service.py`, `tests/api/test_onboarding_status.py`, `tests/api/test_admin_users.py` (incl. the plain-string `"business_user"` at line 177), `tests/api/test_auth_business.py` (26 occurrences).

**Additional plain-string `"business_user"` literals to fix:**
- `services/identity-service/tests/core/test_security.py` (lines 83, 91, 148, 164, 179, 195, 205) — these exercise `create_access_token`'s branching directly; update to `"business_staff"` since §3 replaces the generic else-branch with an explicit `elif`.
- `services/identity-service/tests/deps/test_permissions.py:36` — cosmetic, update for consistency.
- Cross-service: `services/pos-service/tests/test_business_context_binding.py`, `services/pos-service/tests/test_token_verification.py`, `services/inventory-service/tests/test_token_verification.py`, `services/inventory-service/tests/api/test_items.py`, `services/inventory-service/tests/api/test_operations.py`, `services/inventory-service/tests/api/test_reports.py` — not broken (no `UserCategory` import, just claims dict fixtures), update anyway for consistency.

**No Alembic migration needed** — confirmed `user_category` is `Field(sa_type=String)`, a plain varchar, not a native Postgres enum.

---

## 2. `services/identity-service/app/core/security.py` — `create_access_token`

Replace the current two-way `if/elif/else` (lines 109-157) with an explicit three-way split plus a minimal fallback for genuinely future/unmapped categories:

```python
if user_category == "platform_staff":
    ...unchanged...
elif user_category in ("driver", "consumer"):
    ...unchanged...
elif user_category == "business_staff":
    payload["active_business_id"] = active_business_id
    payload["roles"] = roles or []
    payload["permissions"] = permissions or []
    payload["other_businesses"] = other_businesses or []
elif user_category == "business_store_staff":
    payload["active_business_id"] = active_business_id
    payload["active_store_id"] = active_store_id
    payload["roles"] = roles or []
    payload["permissions"] = permissions or []
else:
    # Future categories with no defined claim shape yet (farmer, logistics_provider, qa, ...).
    payload["roles"] = roles or []
    payload["permissions"] = permissions or []
```

- Add new parameter `active_store_id: str | None = None`.
- `business_store_staff` tokens carry no `other_businesses`/`other_stores` (single-store only).
- Update the docstring accordingly.

---

## 3. `services/identity-service/app/schemas/auth.py` — new `StoreStaffTokenClaims`

Add directly after the renamed `BusinessStaffTokenClaims`:

```python
class StoreStaffTokenClaims(BaseModel):
    """Claims shape for a business-store-staff JWT (doc / response typing, not encoding)."""

    sub: str
    user_category: UserCategory = UserCategory.BUSINESS_STORE_STAFF
    active_business_id: UUID | None = None
    active_store_id: UUID | None = None
    roles: list[str] = Field(default_factory=list)
    permissions: list[str] = Field(default_factory=list)
```

---

## 4. Token issuance — `services/identity-service/app/api/v1/endpoints/auth.py`

Add one shared helper (near the top, before `_issue_tokens`) so the store-resolution query isn't tripled across call sites:

```python
async def _resolve_store_staff_context(
    session: AsyncSession, user_id: UUID
) -> tuple[UUID | None, UUID | None, list[str], list[str]]:
    """Resolve (active_business_id, active_store_id, role_names, effective_permissions)
    for a business_store_staff user from their UserStoreRole assignment.

    Single-store only: if more than one UserStoreRole row exists, the first
    by id is used and a warning is logged. Returns all-None/empty if the
    user has no UserStoreRole yet (not assigned to any store).
    """
    result = await session.exec(
        select(UserStoreRole).where(UserStoreRole.user_id == user_id).order_by(UserStoreRole.id)
    )
    store_roles = result.all()
    if not store_roles:
        return None, None, [], []
    if len(store_roles) > 1:
        logger.warning("user_has_multiple_store_roles", user_id=str(user_id))
    usr = store_roles[0]

    role = await session.get(BusinessRole, usr.business_role_id)
    role_names = [role.name] if role else []
    role_permission_codes: list[str] = []
    if role:
        perm_result = await session.exec(
            select(BusinessRolePermission).where(BusinessRolePermission.business_role_id == role.id)
        )
        role_permission_codes = [rp.permission_code for rp in perm_result.all()]

    grant_result = await session.exec(
        select(UserBusinessPermission).where(
            UserBusinessPermission.user_id == user_id,
            UserBusinessPermission.business_id == usr.business_id,
            UserBusinessPermission.type == "grant",
        )
    )
    deny_result = await session.exec(
        select(UserBusinessPermission).where(
            UserBusinessPermission.user_id == user_id,
            UserBusinessPermission.business_id == usr.business_id,
            UserBusinessPermission.type == "deny",
        )
    )
    grants = [p.permission_code for p in grant_result.all()]
    denies = [p.permission_code for p in deny_result.all()]

    effective = resolve_effective_permissions(
        business_role_permissions=[],
        location_role_permissions=role_permission_codes,
        grants=grants,
        denies=denies,
    )
    return usr.business_id, usr.store_id, role_names, [str(p) for p in effective]
```

This populates `resolve_effective_permissions`'s previously-unused `location_role_permissions` parameter from `UserStoreRole → BusinessRole → BusinessRolePermission`, and folds in business-level `UserBusinessPermission` grant/deny overrides (there's no per-store override table). Hoist `UserStoreRole`, `BusinessRole`, `BusinessRolePermission`, `UserBusinessPermission` to top-level imports in this file (currently imported locally inside `switch_business_context`) since they're now used in 2+ functions.

**`_issue_tokens`** (lines 89-124) and **`/refresh`** (lines ~680-696): both get the same three-way split —

```python
if user.user_category in (UserCategory.DRIVER, UserCategory.CONSUMER):
    ...unchanged...
elif user.user_category == UserCategory.BUSINESS_STORE_STAFF:
    biz_id, store_id, role_names, perms = await _resolve_store_staff_context(session_or_db, user.id)
    access_token = create_access_token(
        subject=user_id_str,
        user_category=UserCategory.BUSINESS_STORE_STAFF.value,
        active_business_id=str(biz_id) if biz_id else None,
        active_store_id=str(store_id) if store_id else None,
        roles=role_names,
        permissions=perms,
    )
else:
    access_token = create_access_token(
        subject=user_id_str,
        user_category=UserCategory.BUSINESS_STAFF.value,
        active_business_id=None,
        roles=[],
        permissions=[],
        other_businesses=[],
    )
```

Note the deliberate asymmetry: `business_staff` still starts with `active_business_id=None` and must call `/auth/context/switch`; `business_store_staff` resolves its store immediately at login since there's nothing to disambiguate.

**`/auth/context/switch`** (lines ~761-859): apply the `BUSINESS_USER`→`BUSINESS_STAFF` string fix, and add a guard at the top rejecting non-`business_staff` callers:

```python
if claims.get("user_category") != "business_staff":
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="This endpoint is for business-staff accounts only.",
    )
```

---

## 5. `services/identity-service/app/deps/permissions.py` — new dependency factories

Add `require_store_context()` and `require_store_permission(code)`, mirroring `require_business_context`/`require_business_permission` exactly but keyed on `active_store_id`:

```python
def require_store_context() -> Callable[..., Awaitable[str]]:
    async def _check_store_context(
        claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    ) -> str:
        active_store_id: str | None = claims.get("active_store_id")
        if not active_store_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="A valid store context is required. Ask a business administrator to assign you to a store.",
            )
        return active_store_id
    return _check_store_context


def require_store_permission(permission_code: str | PermissionCode) -> Callable[..., Awaitable[str]]:
    validated: PermissionCode = coerce_permission_code(permission_code)

    async def _check_store_permission(
        claims: Annotated[dict[str, Any], Depends(get_current_claims)],
    ) -> str:
        active_store_id: str | None = claims.get("active_store_id")
        if not active_store_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="A valid store context is required. Ask a business administrator to assign you to a store.",
            )
        permissions: list[str] = claims.get("permissions", [])
        if str(validated) not in permissions and "*" not in permissions:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission '{validated}' is required",
            )
        return active_store_id
    return _check_store_permission
```

Update the module docstring's factory list accordingly. Update `resolve_effective_permissions`'s docstring in `services/identity-service/app/services/permission_resolver.py` to reflect that `location_role_permissions` is now populated (no signature change).

---

## 6. Cross-service copies — `services/inventory-service/app/deps/auth.py` and `services/pos-service/app/deps/auth.py`

Copy the same two factories into both files, but using the **path-param cross-check variant** (matching how these two services' `require_business_permission` already differs from identity-service's by adding a `business_id: UUID` path-param check — "Stage 8.5, Gap 1"):

```python
def require_store_permission(permission_code: str | PermissionCode) -> Callable[..., Awaitable[str]]:
    validated: PermissionCode = coerce_permission_code(permission_code)

    async def _check_store_permission(
        claims: Annotated[dict[str, Any], Depends(get_current_claims)],
        store_id: UUID,
    ) -> str:
        active_store_id: str | None = claims.get("active_store_id")
        if not active_store_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="A valid store context is required.")
        if str(store_id) != active_store_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Store ID in path does not match authenticated store context")
        permissions: list[str] = claims.get("permissions", [])
        if str(validated) not in permissions and "*" not in permissions:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Permission '{validated}' is required")
        return active_store_id
    return _check_store_permission
```

(`require_store_context()` is identical to identity-service's version — no path param to cross-check.) These are added but not yet wired into any inventory/pos route — retrofitting `items.py`/`operations.py`/`reports.py`/`sales.py`/`void_refund.py` to require `store_id` in the path and enforce it is explicitly **out of scope** (already flagged in-repo as a deferred "CROSS-SERVICE VALIDATION GAP"); this plan only builds the mechanism so that follow-up can wire it in without further claim-shape changes.

---

## 7. `services/identity-service/app/api/v1/endpoints/stores.py`

**7a. Layered store-scope guard on the four `{store_id}` routes** (`get_store`, `update_store`, `get_store_settings`, `update_store_settings`): add claims as a dependency and a new helper mirroring `_require_context_match`:

```python
def _require_store_scope_match(store_id: UUID, claims: dict[str, Any]) -> None:
    """If the caller has an active_store_id (business_store_staff), the path
    store_id must match it. business_staff/platform_staff have no
    active_store_id and are unrestricted here."""
    active_store_id = claims.get("active_store_id")
    if active_store_id and str(store_id) != active_store_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token store context does not match the requested store",
        )
```

Call this right after `_require_context_match(...)` in each of the four routes.

**7b. Block `business_store_staff` from `list_stores`/`create_store_endpoint`** (business-wide operations): add a category check —

```python
if claims.get("user_category") == "business_store_staff":
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not available to store-scoped staff")
```

**7c. New store-staff assignment endpoints** (closes the gap that nothing today creates a `UserStoreRole` row; mirrors `business_rbac.py`'s `assign_staff_role`/`list_staff`/`revoke_staff_role`, using the already-defined `UserStoreRoleCreate`/`UserStoreRoleRead` schemas and `USER_STORE_ROLES_ASSIGN`/`USER_STORE_ROLES_VIEW`/`USER_STORE_ROLES_REVOKE` permission codes):

- `POST /businesses/{business_id}/stores/{store_id}/staff` — gated by `require_business_permission(PermissionCode.USER_STORE_ROLES_ASSIGN)`. Body: `{business_role_id, phone?, user_id?}`. Auto-provisions a fresh phone-only target as `UserCategory.BUSINESS_STORE_STAFF`; 400s if an existing target user's category isn't `BUSINESS_STORE_STAFF`; creates `UserStoreRole(user_id, business_id, store_id, business_role_id)`; 409 if it already exists.
- `GET /businesses/{business_id}/stores/{store_id}/staff` — gated by `require_business_permission(PermissionCode.USER_STORE_ROLES_VIEW)`. Lists staff at that store, grouped by user (mirrors `list_staff`).
- `DELETE /businesses/{business_id}/stores/{store_id}/staff/{user_id}/roles/{role_id}` — gated by `require_business_permission(PermissionCode.USER_STORE_ROLES_REVOKE)`. Mirrors `revoke_staff_role`.

All three also call `_get_store_or_404(db, business_id, store_id)` and `_require_context_match(business_id, caller_business_id)` — they're business-admin actions performed on a store, not actions performed as the store-staff member, so no `_require_store_scope_match` needed here.

---

## Verification

**Import/test check:**
```
cd services/identity-service
uv run python -c "import app.main"
uv run pytest tests/ -x -q
```
Specifically confirm `tests/api/test_auth_business.py`, `tests/api/test_business_rbac.py`, and `tests/core/test_security.py` pass.

**Manual end-to-end per category** (identity-service running locally with RSA keys generated via `scripts/generate_keys.py`):

1. **platform_staff** — register/login via the existing platform auth flow, decode the access token, confirm claims unchanged (`group`, `roles`, `permissions`, no `active_business_id`/`active_store_id`), call a `require_platform_staff()`-gated endpoint → 200.
2. **business_staff** — `POST /api/v1/auth/register`, confirm `user_category == "business_staff"`, decode token → `active_business_id: null`. Create a business, `POST /auth/context/switch`, decode new token → `active_business_id` set, roles/permissions populated. Call a `require_business_permission(...)` endpoint → 200 with matching `business_id`, 403 with a different one.
3. **business_store_staff** — as a business_staff owner, call the new `POST /businesses/{business_id}/stores/{store_id}/staff` with a fresh phone + `business_role_id`. Have that user verify OTP/login, decode the token → `user_category == "business_store_staff"`, `active_business_id`/`active_store_id` set correctly, roles/permissions reflect the assigned role's `BusinessRolePermission` rows. Call `GET /businesses/{business_id}/stores/{store_id}` with that token → 200 for the assigned store, 403 for a different `store_id` in the same business. Separately confirm the zero-`UserStoreRole` edge case (a store-staff-category user with no assignment) yields `active_store_id: null` and a `require_store_context()`-gated endpoint 403s.
