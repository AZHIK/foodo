"""pytest fixtures — async client, test database, and Redis."""

from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
import redis.asyncio as aioredis
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.database import async_session_factory, engine
from app.core.redis_client import close_redis
from app.main import app


@pytest_asyncio.fixture(scope="session")
def event_loop():
    """Single event loop for the whole session to avoid asyncpg
    'Future attached to a different loop' errors across fixtures."""
    import asyncio

    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    """FastAPI test client using ASGI transport (no server needed)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture(autouse=True)
async def _clean_redis() -> AsyncGenerator[None, None]:
    """Flush Redis around each test so rate-limit counters do not leak."""
    settings = get_settings()
    client = aioredis.from_url(settings.redis_url, decode_responses=True)
    await client.flushdb()
    await close_redis()
    yield
    await client.flushdb()
    await close_redis()
    await client.aclose()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def _apply_migrations() -> None:
    """Apply alembic migrations once per test session."""
    import subprocess

    result = subprocess.run(
        ["alembic", "upgrade", "head"], cwd="/app", capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"alembic upgrade failed: {result.stderr}")


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide an isolated DB session backed by Postgres.

    Uses the alembic-managed schema. Truncates all tables before each test
    to ensure data isolation without re-creating the schema.
    """
    # Truncate all tables before test
    async with engine.begin() as conn:
        await conn.execute(
            text("""
            TRUNCATE TABLE
                user_store_roles,
                user_business_permissions,
                user_business_roles,
                business_role_permissions,
                store_settings,
                store,
                business_roles,
                businesses,
                organizations,
                role_template_permissions,
                role_templates,
                platform_role_permissions,
                user_platform_roles,
                platform_roles,
                user_roles,
                user_group,
                role_permissions,
                roles,
                groups,
                permissions,
                verification_codes,
                refresh_tokens,
                user_sessions,
                trusted_devices,
                login_attempts,
                auth_risk_events,
                users
            RESTART IDENTITY CASCADE;
        """)
        )

    async with async_session_factory() as session:
        yield session

    # Clean up after test
    async with engine.begin() as conn:
        await conn.execute(
            text("""
            TRUNCATE TABLE
                user_store_roles,
                user_business_permissions,
                user_business_roles,
                business_role_permissions,
                store_settings,
                store,
                business_roles,
                businesses,
                organizations,
                role_template_permissions,
                role_templates,
                platform_role_permissions,
                user_platform_roles,
                platform_roles,
                user_roles,
                user_group,
                role_permissions,
                roles,
                groups,
                permissions,
                verification_codes,
                refresh_tokens,
                user_sessions,
                trusted_devices,
                login_attempts,
                auth_risk_events,
                users
            RESTART IDENTITY CASCADE;
        """)
        )


@pytest_asyncio.fixture
async def async_session(db_session: AsyncSession) -> AsyncSession:
    """Alias for db_session — matches the parameter name used by
    platform-role-permission tests and other async-SQLModel tests."""
    return db_session


@pytest_asyncio.fixture
async def redis_client() -> AsyncGenerator[aioredis.Redis, None]:
    """Provide a Redis client connected to the test instance.

    Flushes the database before and after each test to ensure isolation.
    """
    settings = get_settings()
    client = aioredis.from_url(settings.redis_url, decode_responses=True)
    await client.flushdb()
    yield client
    await client.flushdb()
    await client.aclose()
