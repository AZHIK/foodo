"""Shared Pydantic field validators for phone, email, password, and OTP codes.

Every schema that accepts phone/email/password/OTP should reuse the types
defined here rather than duplicating validation logic.
"""

from __future__ import annotations

import re
from typing import Annotated

from pydantic import AfterValidator
from pydantic import EmailStr as PydanticEmailStr

# ── Phone number ──────────────────────────────────────────────────────────


def _validate_and_normalize_phone(v: str) -> str:
    """Validate and normalize a phone number to E.164 format.

    Defaults to Tanzania (+255) when no country code is given.
    """
    import phonenumbers

    try:
        parsed = phonenumbers.parse(v, "TZ")
    except phonenumbers.NumberParseException as exc:
        raise ValueError(f"Could not parse phone number: {exc}") from exc

    if not phonenumbers.is_valid_number(parsed):
        raise ValueError("Phone number is not valid for the inferred region")
    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)


PhoneStr = Annotated[str, AfterValidator(_validate_and_normalize_phone)]
"""Phone number validated and normalized to E.164; defaults to Tanzania (+255)."""


# ── Email ─────────────────────────────────────────────────────────────────


def _normalize_email(v: str) -> str:
    return v.lower().strip()


NormalizedEmailStr = Annotated[PydanticEmailStr, AfterValidator(_normalize_email)]
"""Pydantic EmailStr that is lowercased and stripped on validation."""

# Re-export for convenience
EmailStr = PydanticEmailStr


# ── OTP code (6-digit numeric) ────────────────────────────────────────────

_OTP_PATTERN = re.compile(r"^\d{6}$")


def _validate_otp_code(v: str) -> str:
    if not _OTP_PATTERN.match(v):
        raise ValueError("OTP code must be a 6-digit numeric string")
    return v


OTPCodeStr = Annotated[str, AfterValidator(_validate_otp_code)]
"""6-digit numeric OTP code string."""


# ── Strong password — platform staff ──────────────────────────────────────

_WEAK_PASSWORD_DENYLIST: set[str] = {
    "password",
    "password123",
    "12345678",
    "123456789",
    "qwerty123",
    "abcdefgh",
    "letmein",
    "welcome",
    "monkey",
    "dragon",
}


def _validate_strong_password(v: str) -> str:
    if len(v) < 12:
        raise ValueError("Password must be at least 12 characters long")
    if not re.search(r"[A-Z]", v):
        raise ValueError("Password must contain at least one uppercase letter")
    if not re.search(r"[a-z]", v):
        raise ValueError("Password must contain at least one lowercase letter")
    if not re.search(r"\d", v):
        raise ValueError("Password must contain at least one digit")
    if not re.search(r"[!@#$%^&*(),.?:{}|<>_\-+=\[\]\\;'\"`~]", v):
        raise ValueError("Password must contain at least one special character")
    if v.lower() in _WEAK_PASSWORD_DENYLIST:
        raise ValueError("Password is too common. Choose a stronger password.")
    return v


StrongPassword = Annotated[str, AfterValidator(_validate_strong_password)]
"""Password validated for platform-staff strength: min 12, upper+lower+digit+special, denylist."""


# ── Business password — business users / drivers / consumers ──────────────


def _validate_business_password(v: str) -> str:
    if len(v) < 8:
        raise ValueError("Password must be at least 8 characters long")
    if not re.search(r"[A-Za-z]", v):
        raise ValueError("Password must contain at least one letter")
    if not re.search(r"\d", v):
        raise ValueError("Password must contain at least one digit")
    return v


BusinessPassword = Annotated[str, AfterValidator(_validate_business_password)]
"""Password validated for business-user strength: min 8, at least one letter and one digit."""
