"""Async SQLAlchemy engine and session factory wired via Settings.

Usage:
    async with get_db() as session:
        result = await session.exec(select(Model).where(...))
        user = result.one()

Pattern: session.exec() is SQLModel's wrapper around session.execute()
that auto-unwraps Result into scalars.  Prefer session.exec() for
SQLModel models; fall back to session.execute() for raw SQL or
SQLAlchemy-core queries.
"""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    async_sessionmaker,
    create_async_engine,
)
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.db_url,
    echo=settings.debug,
    pool_pre_ping=True,
)

async_session_factory = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency that yields an async DB session."""
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()


# Alias for dependency injection consistency
get_async_session = get_db


async def create_tables() -> None:
    """Create all tables defined via SQLModel (for dev/testing only).

    In production, use Alembic migrations instead.
    """
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)


async def drop_tables() -> None:
    """Drop all tables (for test teardown only)."""
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)
