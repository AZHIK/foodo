"""Seed the default internal groups, roles, and role_permissions.

Usage:
    uv run python scripts/seed_internal_rbac.py

Safe to run multiple times — the upsert logic in ``seed_internal_rbac()``
guarantees idempotency.
"""

from __future__ import annotations

import asyncio

from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.db.seed_internal_rbac import seed_internal_rbac


async def main() -> None:
    settings = get_settings()
    engine = create_async_engine(settings.db_url)

    # Ensure tables exist before seeding.
    from sqlmodel import SQLModel

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    async with AsyncSession(engine) as session:

        def _run(sync_session):  # type: ignore[no-untyped-def]
            seed_internal_rbac(sync_session)

        await session.run_sync(_run)

    await engine.dispose()
    print("Internal RBAC seeded successfully.")


if __name__ == "__main__":
    asyncio.run(main())