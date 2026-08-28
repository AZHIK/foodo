"""Schemas for business-level RBAC: business roles, permissions, and grant/deny overrides."""

from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator

from app.core.permission_codes import PermissionCode
from app.models.user import UserStatus
from app.schemas.validators import PhoneStr

# ── BusinessRole ──────────────────────────────────────────────────────────


class BusinessRoleBase(BaseModel):
    """Shared fields for business role schemas."""

    business_id: UUID
    name: str
    description: str | None = None
    is_protected: bool = False


class BusinessRoleCreate(BusinessRoleBase):
    """Fields required to create a business role (admin use)."""


class BusinessRoleCreateRequest(BaseModel):
    """Request body for POST /businesses/{business_id}/roles.

    ``business_id`` is taken from the URL path, and ``is_protected`` is
    always ``false`` for roles created by business owners.
    """

    name: str
    description: str | None = None


class BusinessRoleUpdate(BaseModel):
    """Fields that may be updated on a business role (partial update, admin use)."""

    name: str | None = None
    description: str | None = None
    is_protected: bool | None = None


class BusinessRoleUpdateRequest(BaseModel):
    """Request body for PATCH /businesses/{business_id}/roles/{role_id}.

    ``is_protected`` is never settable via this endpoint — only the seeded
    Owner role carries ``is_protected=true``.
    """

    name: str | None = None
    description: str | None = None


class BusinessRoleRead(BusinessRoleBase):
    """Full business role representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


# ── BusinessRolePermission (pure join table — no extra fields) ────────────


class BusinessRolePermissionCreate(BaseModel):
    """Fields required to attach a permission code to a business role.

    This is a pure many-to-many join — no Update schema.
    """

    business_role_id: UUID
    permission_code: str


class AddRolePermissionRequest(BaseModel):
    """Request body for POST /businesses/{business_id}/roles/{role_id}/permissions."""

    permission_code: str


class AssignStaffRequest(BaseModel):
    """Request body for POST /businesses/{business_id}/staff.

    The target user can be identified by ``phone`` (looked up server-side)
    or by ``user_id``.  At least one must be provided.
    """

    business_role_id: UUID
    phone: PhoneStr | None = None
    user_id: UUID | None = None


class BusinessRolePermissionRead(BaseModel):
    """Business-role–permission association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    business_role_id: UUID
    permission_code: str


# ── UserBusinessRole (pure join table — no extra fields) ──────────────────


class UserBusinessRoleCreate(BaseModel):
    """Fields required to assign a business role to a user within a business.

    This is a pure many-to-many join — no Update schema.
    """

    user_id: UUID
    business_id: UUID
    business_role_id: UUID


class UserBusinessRoleRead(BaseModel):
    """User–business-role association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    business_id: UUID
    business_role_id: UUID


# ── UserBusinessLocationRole (employee-at-store mapping — pure join table) ──


class UserBusinessLocationRoleCreate(BaseModel):
    """Fields required to assign a business role to a user at a specific store.

    This is a pure many-to-many join — no Update schema.
    """

    user_id: UUID
    business_id: UUID
    store_id: UUID
    business_role_id: UUID


class UserBusinessLocationRoleRead(BaseModel):
    """User–store–role association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    business_id: UUID
    store_id: UUID
    business_role_id: UUID


# ── UserBusinessPermission (grant/deny override — has extra fields) ───────

_GrantDeny = Literal["grant", "deny"]


class UserBusinessPermissionBase(BaseModel):
    """Shared fields for user business permission override schemas."""

    user_id: UUID
    business_id: UUID
    permission_code: str
    type: _GrantDeny


class UserBusinessPermissionCreate(UserBusinessPermissionBase):
    """Fields required to create a grant or deny override for a user within a business.

    permission_code is validated against the PermissionCode enum at the schema level.
    """

    @field_validator("permission_code")
    @classmethod
    def _validate_permission_code(cls, v: str) -> str:
        PermissionCode(v)  # raises ValueError if invalid
        return v


class UserBusinessPermissionUpdate(BaseModel):
    """Fields that may be updated on a grant/deny override (toggle the type)."""

    type: _GrantDeny | None = None


class UserBusinessPermissionRead(UserBusinessPermissionBase):
    """Full user business permission override representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_by: UUID | None = None
    created_at: datetime
    updated_at: datetime


# ── Staff list (GET /businesses/{business_id}/staff) ──────────────────────


class StaffRoleSummary(BaseModel):
    """One role a staff member holds, as returned within a staff list entry."""

    business_role_id: UUID
    name: str


class StaffMemberRead(BaseModel):
    """One staff member and every role they hold at this business.

    A user can hold more than one ``UserBusinessRole`` row at the same
    business — this groups all of them under a single entry rather than
    returning one row per role.
    """

    user_id: UUID
    phone: str
    full_name: str
    email: str | None
    status: UserStatus
    roles: list[StaffRoleSummary]
