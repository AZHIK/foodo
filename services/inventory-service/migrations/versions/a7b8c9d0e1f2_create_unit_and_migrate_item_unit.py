"""Create unit table and migrate item.unit_of_measure to item.unit_id.

Creates the global ``unit`` table (see ``app/models/units.py`` for why it
has no ``business_id``/soft-delete) and backfills ``item.unit_of_measure``
(the ``unitofmeasure`` Postgres enum) into a real ``item.unit_id`` FK by
matching on ``unit.code`` — the seed data's codes are exactly the old
enum's values — before dropping the old enum column and the enum type
itself.

This migration does NOT seed any unit rows — seeding is a deliberate,
separate step (``scripts/seed_units.py``, see the README's "Seed data"
section), not something a schema migration should own, exactly like
``f1a2b3c4d5e6_create_category_and_migrate_item_category``. One
consequence: since ``unit`` is empty at the point this migration runs, the
backfill UPDATE below will not match anything and every existing item's
``unit_id`` will come out ``NULL`` — the FK is nullable, so this is not an
error, just a "no unit resolved" state that a follow-up reconciliation pass
(re-running the backfill UPDATE once ``unit`` is seeded) can fix. On a
fresh/test database with no pre-existing ``item`` rows this is moot.

``item.unit_id`` is nullable at the database level (mirroring
``item.category_id``'s migration), even though a unit is conceptually
mandatory for a real item — the write API (``ItemCreate.unit_id``) still
requires it for every new item; only pre-existing rows can transiently hold
NULL until reconciled.

Revision ID: a7b8c9d0e1f2
Revises: f1a2b3c4d5e6
Create Date: 2026-09-11
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a7b8c9d0e1f2"
down_revision: Union[str, None] = "f1a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── unit ─────────────────────────────────────────────────────────────
    op.create_table(
        "unit",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("code", sa.String(64), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("abbreviation", sa.String(16), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_unit_code"), "unit", ["code"], unique=True)

    # ── item.unit_of_measure (enum) → item.unit_id (FK) ─────────────────────
    op.add_column("item", sa.Column("unit_id", sa.Uuid(), nullable=True))

    # Best-effort match against whatever is in `unit` at migration time (see
    # module docstring — ordinarily nothing yet, since seeding is a separate
    # later step). Unmatched/no-match rows are left NULL.
    op.execute(
        """
        UPDATE item
        SET unit_id = (
            SELECT unit.id FROM unit WHERE unit.code = item.unit_of_measure::text
        )
        """
    )

    op.create_foreign_key(
        "fk_item_unit_id_unit",
        "item",
        "unit",
        ["unit_id"],
        ["id"],
        ondelete="RESTRICT",
    )
    op.create_index(op.f("ix_item_unit_id"), "item", ["unit_id"])
    op.drop_column("item", "unit_of_measure")
    op.execute("DROP TYPE IF EXISTS unitofmeasure")


def downgrade() -> None:
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'unitofmeasure') THEN
                CREATE TYPE unitofmeasure AS ENUM ('kg', 'g', 'l', 'ml', 'unit', 'pack');
            END IF;
        END
        $$;
    """)
    op.add_column(
        "item",
        sa.Column("unit_of_measure", sa.Enum(name="unitofmeasure"), nullable=True),
    )
    op.execute(
        """
        UPDATE item
        SET unit_of_measure = (SELECT unit.code FROM unit WHERE unit.id = item.unit_id)::unitofmeasure
        """
    )
    op.drop_index(op.f("ix_item_unit_id"), table_name="item")
    op.drop_constraint("fk_item_unit_id_unit", "item", type_="foreignkey")
    op.drop_column("item", "unit_id")

    op.drop_index(op.f("ix_unit_code"), table_name="unit")
    op.drop_table("unit")
