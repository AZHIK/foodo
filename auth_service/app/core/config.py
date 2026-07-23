"""Application settings via pydantic-settings.

All environment variables are loaded through this class.
Use `get_settings()` (cached) rather than instantiating directly.
"""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── App ────────────────────────────────────
    environment: Literal["local", "dev", "staging", "prod"] = "local"
    debug: bool = True
    app_name: str = "FoodLink Auth"
    log_level: str = "DEBUG"

    # ── Database ───────────────────────────────
    db_url: str = "postgresql+asyncpg://foodlink:foodlink@localhost:5432/foodlink_auth"

    # ── Redis ──────────────────────────────────
    redis_url: str = "redis://localhost:6379/0"

    # ── JWT (placeholder) ──────────────────────
    jwt_private_key_path: str = "keys/private.pem"
    jwt_public_key_path: str = "keys/public.pem"
    jwt_algorithm: str = "RS256"
    jwt_access_token_ttl_minutes: int = 15
    jwt_refresh_token_ttl_days: int = 7
    jwt_private_key: str | None = None
    jwt_public_key: str | None = None

    # ── OTP ────────────────────────────────────
    otp_provider: str = "twilio"
    otp_api_key: str = ""
    otp_sender_id: str = "FoodLink"
    otp_expire_minutes: int = 5
    otp_max_attempts: int = 5

    # ── Session ────────────────────────────────
    session_ttl_minutes: int = 60

    # ── SMS ────────────────────────────────────
    sms_provider: Literal["console", "africastalking"] = "console"

    # ── Africa's Talking ────────────────────────
    at_username: str = "sandbox"
    at_api_key: str = ""
    at_sender_id: str | None = None

    # ── CORS ────────────────────────────────────
    # Comma-separated list of allowed origins. In production, set this to
    # the actual Flutter app origin (e.g. https://app.foodlink.com) and the
    # Next.js admin dashboard domain. Defaults to http://localhost:3000 for
    # local Next.js dev.
    cors_allowed_origins: str = "http://localhost:3000"

    # ── Host ───────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8000

    # ── Rate limiting ──────────────────────────
    # Configurable defaults; tune per environment rather than treating these
    # as production-final abuse thresholds.
    rate_limit_login_password_phone_limit: int = 5
    rate_limit_login_password_phone_window: int = 900  # 15 min
    rate_limit_login_password_ip_limit: int = 20
    rate_limit_login_password_ip_window: int = 900

    rate_limit_otp_request_phone_limit: int = 3
    rate_limit_otp_request_phone_window: int = 600  # 10 min
    rate_limit_otp_request_ip_limit: int = 10
    rate_limit_otp_request_ip_window: int = 600

    rate_limit_password_reset_request_phone_limit: int = 3
    rate_limit_password_reset_request_phone_window: int = 600
    rate_limit_password_reset_request_ip_limit: int = 10
    rate_limit_password_reset_request_ip_window: int = 600

    rate_limit_refresh_ip_limit: int = 30
    rate_limit_refresh_ip_window: int = 600  # 10 min

    rate_limit_platform_login_email_limit: int = 5
    rate_limit_platform_login_email_window: int = 900  # 15 min
    rate_limit_platform_login_ip_limit: int = 20
    rate_limit_platform_login_ip_window: int = 900


@lru_cache
def get_settings() -> Settings:
    """Return a cached, immutable Settings singleton."""
    return Settings()


_settings = get_settings()

# Backwards-compatible named constants for route dependency construction.
RATE_LIMIT_LOGIN_PASSWORD_PHONE_LIMIT = _settings.rate_limit_login_password_phone_limit
RATE_LIMIT_LOGIN_PASSWORD_PHONE_WINDOW = _settings.rate_limit_login_password_phone_window
RATE_LIMIT_LOGIN_PASSWORD_IP_LIMIT = _settings.rate_limit_login_password_ip_limit
RATE_LIMIT_LOGIN_PASSWORD_IP_WINDOW = _settings.rate_limit_login_password_ip_window

RATE_LIMIT_OTP_REQUEST_PHONE_LIMIT = _settings.rate_limit_otp_request_phone_limit
RATE_LIMIT_OTP_REQUEST_PHONE_WINDOW = _settings.rate_limit_otp_request_phone_window
RATE_LIMIT_OTP_REQUEST_IP_LIMIT = _settings.rate_limit_otp_request_ip_limit
RATE_LIMIT_OTP_REQUEST_IP_WINDOW = _settings.rate_limit_otp_request_ip_window

RATE_LIMIT_PASSWORD_RESET_REQUEST_PHONE_LIMIT = (
    _settings.rate_limit_password_reset_request_phone_limit
)
RATE_LIMIT_PASSWORD_RESET_REQUEST_PHONE_WINDOW = (
    _settings.rate_limit_password_reset_request_phone_window
)
RATE_LIMIT_PASSWORD_RESET_REQUEST_IP_LIMIT = _settings.rate_limit_password_reset_request_ip_limit
RATE_LIMIT_PASSWORD_RESET_REQUEST_IP_WINDOW = _settings.rate_limit_password_reset_request_ip_window

RATE_LIMIT_REFRESH_IP_LIMIT = _settings.rate_limit_refresh_ip_limit
RATE_LIMIT_REFRESH_IP_WINDOW = _settings.rate_limit_refresh_ip_window

RATE_LIMIT_PLATFORM_LOGIN_EMAIL_LIMIT = _settings.rate_limit_platform_login_email_limit
RATE_LIMIT_PLATFORM_LOGIN_EMAIL_WINDOW = _settings.rate_limit_platform_login_email_window
RATE_LIMIT_PLATFORM_LOGIN_IP_LIMIT = _settings.rate_limit_platform_login_ip_limit
RATE_LIMIT_PLATFORM_LOGIN_IP_WINDOW = _settings.rate_limit_platform_login_ip_window
