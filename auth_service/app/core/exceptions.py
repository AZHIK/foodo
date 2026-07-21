class DomainError(Exception):
    """Base class for service-layer validation errors."""


class ProtectedRoleEditRejectedError(DomainError):
    """Raised when a protected role edit is rejected."""


class InvalidBusinessLocationTypeError(DomainError):
    """Raised when a location type is not valid for a business type."""


class InvalidRefreshTokenError(DomainError):
    """Raised when a refresh token cannot be used."""


class InvalidTokenError(DomainError):
    """Raised when a JWT access token is invalid (bad signature, malformed, or wrong type)."""


class ExpiredTokenError(InvalidTokenError):
    """Raised when a JWT access token has expired."""


class OtpCodeInvalidError(DomainError):
    """Raised when an OTP code is expired, already used, or does not exist."""


class OtpAttemptsExhaustedError(DomainError):
    """Raised when max OTP verification attempts have been reached."""


class OtpDeliveryError(DomainError):
    """Raised when SMS delivery of an OTP fails."""
