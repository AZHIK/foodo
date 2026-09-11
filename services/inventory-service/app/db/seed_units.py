"""Seed the platform-wide unit-of-measure taxonomy.

Units are a global, not per-business, reference table (see
``app/models/units.py``). Deliberately NOT seeded by the
``a7b8c9d0e1f2_create_unit_and_migrate_item_unit`` migration, which only
creates the empty table — seeding is applied independently via
``scripts/seed_units.py``, mirroring ``app/db/seed_categories.py``'s
pattern of keeping schema migrations and data seeding as two separate,
explicit steps.

The six codes below are exactly the old ``UnitOfMeasure`` enum's values —
seeding these first keeps every existing item's unit resolvable once a
follow-up backfill (see the migration's docstring) sets ``item.unit_id``.

Upserts by ``code`` (the stable slug), not by id — editing a unit's
``name``/``abbreviation``/``sort_order`` here and re-running is always safe.
"""

from __future__ import annotations

from dataclasses import dataclass

from sqlmodel import Session, select

from app.models.units import Unit


@dataclass(frozen=True)
class UnitSeed:
    code: str
    name: str
    abbreviation: str
    sort_order: int


UNIT_SEEDS: tuple[UnitSeed, ...] = (
    UnitSeed("kg", "Kilogram", "kg", 10),
    UnitSeed("g", "Gram", "g", 20),
    UnitSeed("l", "Liter", "L", 30),
    UnitSeed("ml", "Milliliter", "ml", 40),
    UnitSeed("unit", "Each", "ea", 50),
    UnitSeed("pack", "Pack", "pack", 60),
)


def seed_units(session: Session) -> None:
    for seed in UNIT_SEEDS:
        unit = session.exec(select(Unit).where(Unit.code == seed.code)).one_or_none()
        if unit is None:
            session.add(
                Unit(
                    code=seed.code,
                    name=seed.name,
                    abbreviation=seed.abbreviation,
                    sort_order=seed.sort_order,
                )
            )
            continue

        unit.name = seed.name
        unit.abbreviation = seed.abbreviation
        unit.sort_order = seed.sort_order

    session.commit()
