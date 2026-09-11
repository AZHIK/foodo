"""Seed the platform-wide product-category taxonomy.

Categories are a global, not per-business, reference table (see
``app/models/categories.py``). Deliberately NOT seeded by the
``f1a2b3c4d5e6_create_category_and_migrate_item_category`` migration, which
only creates the empty table — seeding is applied independently via
``scripts/seed_categories.py``, mirroring Identity Service's
``seed_permissions.py`` pattern of keeping schema migrations and data
seeding as two separate, explicit steps.

Upserts by ``code`` (the stable slug), not by id — editing a category's
``name``/``sort_order`` here and re-running is always safe.
"""

from __future__ import annotations

from dataclasses import dataclass

from sqlmodel import Session, select

from app.models.categories import Category


@dataclass(frozen=True)
class CategorySeed:
    code: str
    name: str
    sort_order: int


CATEGORY_SEEDS: tuple[CategorySeed, ...] = (
    CategorySeed("produce", "Produce", 10),
    CategorySeed("meat", "Meat & Fish", 20),
    CategorySeed("dairy", "Dairy", 30),
    CategorySeed("dry", "Dry goods", 40),
    CategorySeed("drinks", "Beverages", 50),
    CategorySeed("supplies", "Supplies", 60),
    CategorySeed("starters", "Starters", 70),
    CategorySeed("mains", "Mains", 80),
    CategorySeed("sides", "Sides", 90),
    CategorySeed("desserts", "Desserts", 100),
    # Fallback for items whose free-text category couldn't be matched during
    # the backfill migration — never deactivated, since existing items may
    # still point at it.
    CategorySeed("uncategorized", "Uncategorized", 999),
)


def seed_categories(session: Session) -> None:
    for seed in CATEGORY_SEEDS:
        category = session.exec(
            select(Category).where(Category.code == seed.code)
        ).one_or_none()
        if category is None:
            session.add(
                Category(code=seed.code, name=seed.name, sort_order=seed.sort_order)
            )
            continue

        category.name = seed.name
        category.sort_order = seed.sort_order

    session.commit()
