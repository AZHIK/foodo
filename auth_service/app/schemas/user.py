"""Schemas for the User model — CRUD plus dedicated schemas for sensitive operations."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.user import UserCategory, UserStatus
from app.schemas.validators import NormalizedEmailStr, PhoneStr


class UserBase(BaseModel):
    """Shared fields present in every user schema."""

    phone: str
    email: str | None = None
    full_name: str
    user_category: UserCategory


class UserCreate(UserBase):
    """Fields required to create a user (admin-initiated, not self-registration).

    Does NOT include a password — registration flows have their own schemas in auth.py.
    """

    phone: PhoneStr
    email: NormalizedEmailStr | None = None


class UserUpdate(BaseModel):
    """Fields that may be updated on a user profile (partial update).

    Phone changes and status changes have dedicated schemas below.
    """

    full_name: str | None = None
    email: NormalizedEmailStr | None = None


class UserRead(UserBase):
    """Full user representation returned by the API.

    password_hash is never exposed.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    is_active: bool
    is_phone_verified: bool
    is_email_verified: bool
    status: UserStatus
    created_at: datetime
    updated_at: datetime


class UserPhoneChangeRequest(BaseModel):
    """Dedicated schema for changing a user's phone number (sensitive operation)."""

    phone: PhoneStr


class UserStatusUpdate(BaseModel):
    """Dedicated schema for updating a user's status (sensitive operation)."""

    status: UserStatus
