"""Create recipe header table and rewire recipe_components to it (Stage 1).

Creates ``recipe`` (one row per sellable item's bill-of-materials, UNIQUE on
``sellable_item_id`` for the MVP one-recipe-per-sellable rule) and rewires
``recipecomponent`` from ``sellable_item_id`` to ``recipe_id``, adding a
``(recipe_id, raw_material_item_id)`` uniqueness guard so one recipe cannot
list the same ingredient twice.

INTENTIONAL LOUD FAILURE: ``recipecomponent`` was created early in the build
and deliberately never written by any code path, so it is expected to be
empty. ``recipe_id`` is therefore added ``NOT NULL`` with no backfill — if
orphan rows somehow exist, this migration errors instead of silently
orphaning them, and the operator investigates before re-running. The
downgrade cannot restore dropped ``sellable_item_id`` values; that is moot
in practice for the same reason (no legitimate rows can exist).

Revision ID: f2a3b4c5d6e7
Revises: a7b8c9d0e1f2
Create Date: 2026-09-14
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "f2a3b4c5d6e7"
down_revision: Union[str, None] = "a7b8c9d0e1f2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── recipe header ──────────────────────────────────────────────────
    op.create_table(
        "recipe",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("sellable_item_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["sellable_item_id"], ["item.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("sellable_item_id", name="uq_recipe_sellable_item"),
    )
    op.create_index(op.f("ix_recipe_business_id"), "recipe", ["business_id"])
    op.create_index(
        op.f("ix_recipe_sellable_item_id"), "recipe", ["sellable_item_id"]
    )

    # ── rewire recipecomponent: sellable_item_id -> recipe_id ──────────
    # Fails loudly on unexpected pre-existing rows (see module docstring).
    op.add_column(
        "recipecomponent",
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_recipecomponent_recipe_id",
        "recipecomponent",
        "recipe",
        ["recipe_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.drop_column("recipecomponent", "sellable_item_id")
    op.create_unique_constraint(
        "uq_recipe_components_recipe_ingredient",
        "recipecomponent",
        ["recipe_id", "raw_material_item_id"],
    )
    op.create_index(
        op.f("ix_recipecomponent_recipe_id"), "recipecomponent", ["recipe_id"]
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_recipecomponent_recipe_id"), table_name="recipecomponent")
    op.drop_constraint(
        "uq_recipe_components_recipe_ingredient",
        "recipecomponent",
        type_="unique",
    )
    # sellable_item_id values are NOT recoverable (see module docstring);
    # restored nullable so the downgrade itself never fails on data shape.
    op.add_column(
        "recipecomponent",
        sa.Column("sellable_item_id", sa.Uuid(), nullable=True),
    )
    op.drop_constraint(
        "fk_recipecomponent_recipe_id", "recipecomponent", type_="foreignkey"
    )
    op.drop_column("recipecomponent", "recipe_id")
    op.drop_index(op.f("ix_recipe_sellable_item_id"), table_name="recipe")
    op.drop_index(op.f("ix_recipe_business_id"), table_name="recipe")
    op.drop_table("recipe")
