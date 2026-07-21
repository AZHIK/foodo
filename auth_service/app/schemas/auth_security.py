"""Read-only schemas for auth/security models — internal/admin visibility only.

These models are written exclusively by internal auth logic, never via a
generic API surface.  Only Read schemas are provided.

Raw secrets (code_hash, token_hash, device_fingerprint_hash) are NEVER exposed.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.auth import (
    AuthEventType,
    AuthRiskLevel,
    VerificationCodePurpose,
    VerificationCodeType,
)


class VerificationCodeRead(BaseModel):
    """Verification code record — for admin audit/inspection.

    code_hash is never exposed.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    type: VerificationCodeType
    purpose: VerificationCodePurpose
    expires_at: datetime
    used_at: datetime | None = None
    attempts: int
    created_at: datetime
    updated_at: datetime


class RefreshTokenRead(BaseModel):
    """Refresh token record — for admin audit/inspection.

    token_hash is never exposed.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    device_info: str | None = None
    ip_address: str | None = None
    expires_at: datetime
    revoked_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class UserSessionRead(BaseModel):
    """Active user session — for admin session management views."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    refresh_token_id: UUID | None = None
    device_info: str | None = None
    ip_address: str | None = None
    last_activity_at: datetime
    expires_at: datetime
    is_active: bool
    created_at: datetime
    updated_at: datetime


class TrustedDeviceRead(BaseModel):
    """Trusted device record — non-sensitive metadata only.

    device_fingerprint_hash is never exposed.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    device_name: str | None = None
    platform: str | None = None
    last_ip_address: str | None = None
    last_seen_at: datetime
    revoked_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class LoginAttemptRead(BaseModel):
    """Login attempt record — for audit and security review."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID | None = None
    identifier: str
    success: bool
    failure_reason: str | None = None
    ip_address: str | None = None
    user_agent: str | None = None
    created_at: datetime
    updated_at: datetime


class AuthRiskEventRead(BaseModel):
    """Auth risk event record — for security monitoring."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID | None = None
    session_id: UUID | None = None
    event_type: AuthEventType
    risk_level: AuthRiskLevel
    reason: str | None = None
    ip_address: str | None = None
    created_at: datetime
    updated_at: datetime
