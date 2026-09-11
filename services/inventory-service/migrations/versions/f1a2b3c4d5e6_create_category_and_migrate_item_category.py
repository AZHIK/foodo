"""Create category table and migrate item.category to item.category_id.

Creates the global ``category`` table (see ``app/models/categories.py`` for
why it has no ``business_id``/soft-delete) and backfills ``item.category``
(a free-text string) into a real ``item.category_id`` FK by matching on
``category.code``, before dropping the old string column.

This migration does NOT seed any category rows — seeding is a deliberate,
separate step (``scripts/seed_categories.py``, see the README's "Seed data"
section), not something a schema migration should own. One consequence:
since ``category`` is empty at the point this migration runs, the backfill
UPDATE below will not match anything (rightly matching 0 rows on a schema
migration + seed-afterwards deployment) and every existing item's
``category_id`` will simply come out ``NULL`` — the FK is nullable, so this
is not an error, just an "uncategorized" starting state that a follow-up
categorization pass (or re-running the backfill logic manually, once
categories are seeded) can fix. On a fresh/test database with no pre-existing
``item`` rows this is moot.

Revision ID: f1a2b3c4d5e6
Revises: e4f5a6b7c8d9
Create Date: 2026-09-10
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "f1a2b3c4d5e6"
down_revision: Union[str, None] = "e4f5a6b7c8d9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── category ─────────────────────────────────────────────────────────
    op.create_table(
        "category",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("code", sa.String(64), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
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
    op.create_index(op.f("ix_category_code"), "category", ["code"], unique=True)

    # ── item.category (string) → item.category_id (FK) ─────────────────────
    op.add_column("item", sa.Column("category_id", sa.Uuid(), nullable=True))

    # Best-effort match against whatever is in `category` at migration time
    # (see module docstring — ordinarily nothing yet, since seeding is a
    # separate later step). Unmatched/no-match rows are left NULL.
    op.execute(
        """
        UPDATE item
        SET category_id = (
            SELECT category.id FROM category WHERE lower(category.code) = lower(item.category)
        )
        """
    )

    op.create_foreign_key(
        "fk_item_category_id_category",
        "item",
        "category",
        ["category_id"],
        ["id"],
        ondelete="RESTRICT",
    )
    op.create_index(op.f("ix_item_category_id"), "item", ["category_id"])
    op.drop_column("item", "category")


def downgrade() -> None:
    op.add_column("item", sa.Column("category", sa.String(255), nullable=True))
    op.execute(
        """
        UPDATE item
        SET category = (SELECT category.code FROM category WHERE category.id = item.category_id)
        """
    )
    op.drop_index(op.f("ix_item_category_id"), table_name="item")
    op.drop_constraint("fk_item_category_id_category", "item", type_="foreignkey")
    op.drop_column("item", "category_id")

    op.drop_index(op.f("ix_category_code"), table_name="category")
    op.drop_table("category")
