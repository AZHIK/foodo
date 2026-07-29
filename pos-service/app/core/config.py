"""Application settings via pydantic-settings.

All environment variables are loaded through this class.
Use `get_settings()` (cached) rather than instantiating directly.
"""

from __future__ import annotations

from decimal import Decimal
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
    service_name: str = "pos-service"
    environment: Literal["local", "dev", "staging", "prod"] = "local"
    debug: bool = True
    log_level: str = "DEBUG"

    # ── Database ───────────────────────────────
    db_url: str = "postgresql+asyncpg://foodlink:foodlink@localhost:5432/foodlink_pos"

    # ── JWT (verification only — no private key in this service) ──
    jwt_public_key_path: str = "keys/public.pem"
    jwt_algorithm: str = "RS256"
    jwt_public_key: str | None = None

    # ── RabbitMQ ───────────────────────────────
    rabbitmq_url: str = "amqp://guest:guest@localhost:5672/"
    events_exchange: str = "foodlink.events"

    # ── CORS ────────────────────────────────────
    cors_allowed_origins: str = "http://localhost:3000"

    # ── POS-specific ────────────────────────────
    # Time-drift detection thresholds (logic added in a later stage, config
    # centralized here from the start to avoid retrofitting).
    time_drift_suspect_threshold_hours: int = 48
    time_drift_future_tolerance_minutes: int = 5

    # Local tax configuration — kept in POS Service for MVP rather than
    # touching Identity Service's businesses table.
    default_tax_rate: Decimal = Decimal("0")

    # ── Host ───────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8200


@lru_cache
def get_settings() -> Settings:
    """Return a cached, immutable Settings singleton."""
    return Settings()
