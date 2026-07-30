"""Seed role_templates and role_template_permissions with Owner templates.

Usage:
    uv run python scripts/seed_role_templates.py

Safe to run multiple times — upsert logic guarantees idempotency.
"""

from __future__ import annotations

import asyncio

from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.db.seed_role_templates import seed_role_templates


async def main() -> None:
    settings = get_settings()
    engine = create_async_engine(settings.db_url)

    # Ensure tables exist before seeding.
    from sqlmodel import SQLModel

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    async with AsyncSession(engine) as session:

        def _run(sync_session):  # type: ignore[no-untyped-def]
            seed_role_templates(sync_session)

        await session.run_sync(_run)

    await engine.dispose()
    print("Role templates seeded successfully.")


if __name__ == "__main__":
    asyncio.run(main())
