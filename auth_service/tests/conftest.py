"""pytest fixtures — async client, test database, and Redis."""

from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
import redis.asyncio as aioredis
from httpx import ASGITransport, AsyncClient
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.database import async_session_factory, create_tables, drop_tables
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


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide an isolated DB session backed by Postgres.

    Creates all tables before the test and drops them afterwards.
    Each test gets a fresh set of tables, so data never leaks between tests.
    The session has no pre-existing transaction, so service functions
    can safely use ``async with session.begin():``.
    """
    await create_tables()
    async with async_session_factory() as session:
        yield session
    await drop_tables()


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
