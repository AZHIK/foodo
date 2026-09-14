"""Production events + production movement types (Stage 2).

Creates ``productionevent`` (one row per production run) and
``productioneventcomponent`` (one row per ingredient consumed), and adds
``production_input`` / ``production_output`` to the native ``movementtype``
ENUM.

NATIVE POSTGRES ENUM — same handling as ``b2c3d4e5f6a8`` (which added
``sale_reversal``/``refund_reversal``): ``ALTER TYPE ... ADD VALUE`` via
``op.execute()``. The upgrade is additive; the downgrade drops the two
new tables but is a documented no-op for the enum values (PostgreSQL
cannot drop enum values — see that migration's docstring for the manual
recovery procedure).

Table names are SQLModel's lowercase-class-name default
(``productionevent``, ``productioneventcomponent``), matching the
existing ``recipecomponent`` / ``stocklevel`` convention.

``productionevent.recipe_id`` is ON DELETE RESTRICT (not CASCADE): a
recipe with production history cannot be deleted out from under its
records — the recipes endpoint maps the violation to a 409.

Revision ID: f3a4b5c6d7e8
Revises: f2a3b4c5d6e7
Create Date: 2026-09-14
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "f3a4b5c6d7e8"
down_revision: Union[str, None] = "f2a3b4c5d6e7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE movementtype ADD VALUE IF NOT EXISTS 'production_input'")
    op.execute("ALTER TYPE movementtype ADD VALUE IF NOT EXISTS 'production_output'")

    # ── productionevent ────────────────────────────────────────────────
    op.create_table(
        "productionevent",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
        sa.Column("leading_component_item_id", sa.Uuid(), nullable=False),
        sa.Column("leading_quantity_used", sa.Numeric(12, 3), nullable=False),
        sa.Column("suggested_output_quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("actual_output_quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("actor_id", sa.Uuid(), nullable=True),
        sa.Column(
            "occurred_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["recipe_id"], ["recipe.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(
            ["leading_component_item_id"], ["item.id"], ondelete="RESTRICT"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_productionevent_business_id"), "productionevent", ["business_id"]
    )
    op.create_index(
        op.f("ix_productionevent_store_id"), "productionevent", ["store_id"]
    )
    op.create_index(
        op.f("ix_productionevent_recipe_id"), "productionevent", ["recipe_id"]
    )

    # ── productioneventcomponent ───────────────────────────────────────
    op.create_table(
        "productioneventcomponent",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("production_event_id", sa.Uuid(), nullable=False),
        sa.Column("raw_material_item_id", sa.Uuid(), nullable=False),
        sa.Column("quantity_consumed", sa.Numeric(12, 3), nullable=False),
        sa.ForeignKeyConstraint(
            ["production_event_id"], ["productionevent.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["raw_material_item_id"], ["item.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "production_event_id",
            "raw_material_item_id",
            name="uq_production_components_event_ingredient",
        ),
    )
    op.create_index(
        op.f("ix_productioneventcomponent_production_event_id"),
        "productioneventcomponent",
        ["production_event_id"],
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_productioneventcomponent_production_event_id"),
        table_name="productioneventcomponent",
    )
    op.drop_table("productioneventcomponent")
    op.drop_index(op.f("ix_productionevent_recipe_id"), table_name="productionevent")
    op.drop_index(op.f("ix_productionevent_store_id"), table_name="productionevent")
    op.drop_index(
        op.f("ix_productionevent_business_id"), table_name="productionevent"
    )
    op.drop_table("productionevent")
    # ENUM values intentionally left in place — see module docstring.
