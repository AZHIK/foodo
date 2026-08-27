class DomainError(Exception):
    """Base class for service-layer validation errors."""


class ProtectedRoleEditRejectedError(DomainError):
    """Raised when a protected role edit is rejected."""


class InvalidStoreTypeError(DomainError):
    """Raised when a store's location type is not valid for its business type."""


class BusinessAlreadyExistsError(DomainError):
    """Raised when a user who already owns a business tries to create another one."""


class InvalidRefreshTokenError(DomainError):
    """Raised when a refresh token cannot be used."""


class TokenReuseDetectedError(DomainError):
    """Raised when an already-rotated refresh token is reused (replay/theft signal).

    The caller should still respond with a generic 401 to the client,
    but should log/fire the security event internally.
    """


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
