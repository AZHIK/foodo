"""Schemas for RoleTemplate and RoleTemplatePermission models."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RoleTemplateBase(BaseModel):
    """Shared fields for role template schemas."""

    name: str
    description: str | None = None


class RoleTemplateCreate(RoleTemplateBase):
    """Fields required to create a role template."""


class RoleTemplateUpdate(BaseModel):
    """Fields that may be updated on a role template (partial update)."""

    name: str | None = None
    description: str | None = None


class RoleTemplateRead(RoleTemplateBase):
    """Full role template representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


class RoleTemplatePermissionCreate(BaseModel):
    """Fields required to attach a permission code to a role template.

    Pure many-to-many join — no Update schema.
    """

    role_template_id: UUID
    permission_code: str


class RoleTemplatePermissionRead(BaseModel):
    """Role-template–permission association as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    role_template_id: UUID
    permission_code: str
