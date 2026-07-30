"""Seed the permissions database with all PermissionCode rows + default platform roles.

Usage:
    uv run python scripts/seed_permissions.py

This is a one-time setup step.  After running, every ``PermissionCode`` enum
member has a corresponding ``Permission`` row, and the three default
platform roles (driver, consumer, admin) are created with their standard
permission sets.

Safe to run multiple times — the upsert logic in ``seed_permissions()``
guarantees idempotency.
"""

from __future__ import annotations

import asyncio

from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.db.seed_permissions import seed_permissions


async def main() -> None:
    settings = get_settings()
    engine = create_async_engine(settings.db_url)

    # Ensure tables exist before seeding.
    from sqlmodel import SQLModel

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    async with AsyncSession(engine) as session:

        def _run(sync_session):  # type: ignore[no-untyped-def]
            seed_permissions(sync_session)

        await session.run_sync(_run)

    await engine.dispose()
    print("Permissions seeded successfully.")


if __name__ == "__main__":
    asyncio.run(main())
