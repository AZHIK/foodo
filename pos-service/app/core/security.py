"""JWT token verification — public-key-only, no signing capability.

POS Service never possesses a private key.  It only verifies tokens
issued by Identity Service using the shared public key.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import jwt

from app.core.config import get_settings
from app.core.exceptions import ExpiredTokenError, InvalidTokenError


def _load_public_key() -> str:
    """Load the RSA public key from the configured path or inline setting."""
    settings = get_settings()
    if settings.jwt_public_key:
        return settings.jwt_public_key
    path = Path(settings.jwt_public_key_path)
    try:
        return path.read_text()
    except FileNotFoundError:
        raise RuntimeError(
            f"JWT public key not found at {settings.jwt_public_key_path}. "
            "Copy the public key from Identity Service's keys/ directory."
        ) from None


def decode_and_verify_access_token(token: str) -> dict[str, Any]:
    """Decode and verify an RS256 JWT access token.

    Steps:
        1. Verify the RSA signature using the published public key.
        2. Reject if the token is expired.
        3. Reject if the ``type`` claim is not ``"access"``
           (prevents a refresh token JWT from being accepted as an access token).

    Returns the decoded payload dict on success.

    Raises:
        ExpiredTokenError — the token's ``exp`` claim is in the past.
        InvalidTokenError — signature invalid, malformed, or wrong type.
    """
    settings = get_settings()
    public_key = _load_public_key()
    try:
        payload: dict[str, Any] = jwt.decode(
            token,
            public_key,
            algorithms=[settings.jwt_algorithm],
            options={"require": ["exp", "iat", "type"]},
        )
    except jwt.ExpiredSignatureError:
        raise ExpiredTokenError("Access token has expired") from None
    except jwt.InvalidTokenError as exc:
        raise InvalidTokenError(str(exc)) from None
    if payload.get("type") != "access":
        raise InvalidTokenError("Token type is not 'access' — possibly a refresh token")
    return payload
