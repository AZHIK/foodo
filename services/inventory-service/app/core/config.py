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

    # Genuinely separate test database.  When set (TEST_DB_URL env var), the
    # app engine AND Alembic target this database instead of db_url.  The test
    # suite sets it so tests never touch the dev database.
    test_db_url: str | None = None

    # ── JWT (verification only — no private key in this service) ──
    jwt_public_key_path: str = "keys/public.pem"
    jwt_algorithm: str = "RS256"
    jwt_public_key: str | None = None

    # ── RabbitMQ ───────────────────────────────
    # Unused for now — see app/api/v1/endpoints/internal_events.py. POS
    # Service currently calls that endpoint directly over HTTP (MVP,
    # avoids standing up a broker) instead of publishing to a queue.
    rabbitmq_url: str = "amqp://guest:guest@localhost:5672/"
    events_exchange: str = "foodlink.events"

    # ── Inter-service events (MVP transport: synchronous HTTP) ────
    # Shared secret for service-to-service calls (e.g. POS Service's
    # publish_event) — must match the caller's own internal_service_token
    # setting exactly. Not an end-user JWT; checked by
    # app.deps.auth.require_internal_service_token.
    internal_service_token: str = "change-me-internal-token"

    # ── CORS ────────────────────────────────────
    cors_allowed_origins: str = "http://localhost:3000"

    # ── Host ───────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8100


@lru_cache
def get_settings() -> Settings:
    """Return a cached, immutable Settings singleton."""
    return Settings()