"""Seed the unit-of-measure taxonomy (Kilogram, Gram, Liter, ...).

Usage:
    uv run python scripts/seed_units.py

Run this once after ``alembic upgrade head`` in every environment — the
``a7b8c9d0e1f2_create_unit_and_migrate_item_unit`` migration only creates
the (empty) ``unit`` table; it deliberately does not insert any rows (see
that migration's docstring). This script is the one place that does, so the
taxonomy stays independent of, and re-runnable apart from, schema
migrations — mirrors ``scripts/seed_categories.py``.

Safe to run multiple times — the upsert logic in ``seed_units()`` guarantees
idempotency.
"""

from __future__ import annotations

import asyncio

from sqlalchemy.ext.asyncio import create_async_engine
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.db.seed_units import seed_units


async def main() -> None:
    settings = get_settings()
    engine = create_async_engine(settings.db_url)

    # Ensure tables exist before seeding.
    from sqlmodel import SQLModel

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    async with AsyncSession(engine) as session:

        def _run(sync_session):  # type: ignore[no-untyped-def]
            seed_units(sync_session)

        await session.run_sync(_run)

    await engine.dispose()
    print("Units seeded successfully.")


if __name__ == "__main__":
    asyncio.run(main())
