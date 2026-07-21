"""Schemas for platform-level RBAC: groups, roles, platform roles, and associations."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

# ── Group ─────────────────────────────────────────────────────────────────


class GroupBase(BaseModel):
    """Shared fields for group schemas."""

    name: str
    description: str | None = None


class GroupCreate(GroupBase):
    """Fields required to create a group."""


class GroupUpdate(BaseModel):
    """Fields that may be updated on a group (partial update)."""

    name: str | None = None
    description: str | None = None


class GroupRead(GroupBase):
    """Full group representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


# ── Role ──────────────────────────────────────────────────────────────────


class RoleBase(BaseModel):
    """Shared fields for role schemas."""

    group_id: UUID
    name: str
    description: str | None = None


class RoleCreate(RoleBase):
    """Fields required to create a role."""


class RoleUpdate(BaseModel):
    """Fields that may be updated on a role (partial update)."""

    group_id: UUID | None = None
    name: str | None = None
    description: str | None = None


class RoleRead(RoleBase):
    """Full role representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


# ── RolePermission (pure join table — no extra fields) ────────────────────


class RolePermissionCreate(BaseModel):
    """Fields required to assign a permission to a role.

    This is a pure many-to-many join — no Update schema (delete-and-recreate pattern).
    """

    role_id: UUID
    permission_code: str


class RolePermissionRead(BaseModel):
    """Role–permission association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    role_id: UUID
    permission_code: str


# ── UserGroup (pure join table — no extra fields) ─────────────────────────


class UserGroupCreate(BaseModel):
    """Fields required to assign a user to a group.

    This is a pure many-to-many join — no Update schema.
    """

    user_id: UUID
    group_id: UUID


class UserGroupRead(BaseModel):
    """User–group association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    group_id: UUID


# ── UserRole (pure join table — no extra fields) ──────────────────────────


class UserRoleCreate(BaseModel):
    """Fields required to assign a role to a user.

    This is a pure many-to-many join — no Update schema.
    """

    user_id: UUID
    role_id: UUID


class UserRoleRead(BaseModel):
    """User–role association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    role_id: UUID


# ── PlatformRole ──────────────────────────────────────────────────────────


class PlatformRoleBase(BaseModel):
    """Shared fields for platform role schemas."""

    name: str


class PlatformRoleCreate(PlatformRoleBase):
    """Fields required to create a platform role."""


class PlatformRoleUpdate(BaseModel):
    """Fields that may be updated on a platform role (partial update)."""

    name: str | None = None


class PlatformRoleRead(PlatformRoleBase):
    """Full platform role representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


# ── UserPlatformRole (pure join table — no extra fields) ──────────────────


class UserPlatformRoleCreate(BaseModel):
    """Fields required to assign a platform role to a user.

    This is a pure many-to-many join — no Update schema.
    """

    user_id: UUID
    platform_role_id: UUID


class UserPlatformRoleRead(BaseModel):
    """User–platform-role association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    platform_role_id: UUID
