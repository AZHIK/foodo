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
    service_name: str = "inventory-service"
    environment: Literal["local", "dev", "staging", "prod"] = "local"
    debug: bool = True
    log_level: str = "DEBUG"

    # ── Database ───────────────────────────────
    db_url: str = "postgresql+asyncpg://foodlink:foodlink@localhost:5432/foodlink_inventory"

    # ── JWT (verification only — no private key in this service) ──
    jwt_public_key_path: str = "keys/public.pem"
    jwt_algorithm: str = "RS256"
    jwt_public_key: str | None = None

    # ── RabbitMQ ───────────────────────────────
    rabbitmq_url: str = "amqp://guest:guest@localhost:5672/"
    events_exchange: str = "foodlink.events"

    # ── CORS ────────────────────────────────────
    cors_allowed_origins: str = "http://localhost:3000"

    # ── Host ───────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8100


@lru_cache
def get_settings() -> Settings:
    """Return a cached, immutable Settings singleton."""
    return Settings()