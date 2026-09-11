"""Seed the product-category taxonomy (Produce, Dairy, Beverages, ...).

Usage:
    uv run python scripts/seed_categories.py

Run this once after ``alembic upgrade head`` in every environment — the
``f1a2b3c4d5e6_create_category_and_migrate_item_category`` migration only
creates the (empty) ``category`` table; it deliberately does not insert any
rows (see that migration's docstring). This script is the one place that
does, so the taxonomy stays independent of, and re-runnable apart from,
schema migrations.

Safe to run multiple times — the upsert logic in ``seed_categories()``
guarantees idempotency.
"""

from __future__ import annotations

import asyncio

from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.db.seed_categories import seed_categories


async def main() -> None:
    settings = get_settings()
    engine = create_async_engine(settings.db_url)

    # Ensure tables exist before seeding.
    from sqlmodel import SQLModel

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    async with AsyncSession(engine) as session:

        def _run(sync_session):  # type: ignore[no-untyped-def]
            seed_categories(sync_session)

        await session.run_sync(_run)

    await engine.dispose()
    print("Categories seeded successfully.")


if __name__ == "__main__":
    asyncio.run(main())
