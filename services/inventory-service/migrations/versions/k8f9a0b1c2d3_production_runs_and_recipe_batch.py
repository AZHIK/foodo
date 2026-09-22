"""Production runs + recipe batch formulas (Production Module).

Recipes become batch formulas: ``category`` (prep/sauce/finished dish),
``target_yield_quantity`` (default 1 — pre-batch rows are math-identical)
and ``target_yield_unit`` are added to ``recipe``.

New ``productionrun`` lifecycle table (pending → in_progress → completed)
with its ``productionruncomponent`` plan snapshot, plus ``run_id`` and
``waste_reason`` on ``productionevent`` (events published from a run link
back to it and carry the run's loss reason).

Native ``runstatus`` enum follows the existing convention (raw
``CREATE TYPE ... AS ENUM``, lowercase values matching the Python
``RunStatus`` members) — see ``a1b2c3d4e5f6``.

Revision ID: k8f9a0b1c2d3
Revises: j7e8f9a0b1c2
Create Date: 2026-09-21
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "k8f9a0b1c2d3"
down_revision: Union[str, None] = "j7e8f9a0b1c2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # NOTE: no raw CREATE TYPE here — the ``productionrun.status`` column
    # below declares ``sa.Enum(name="runstatus")``, which emits the CREATE
    # TYPE exactly once at table creation. A separate raw statement would
    # duplicate it (DuplicateObjectError).

    # ── recipe: batch formula metadata ─────────────────────────────────
    op.add_column("recipe", sa.Column("category", sa.String(50), nullable=True))
    op.add_column(
        "recipe",
        sa.Column(
            "target_yield_quantity",
            sa.Numeric(12, 3),
            nullable=False,
            server_default="1",
        ),
    )
    op.add_column(
        "recipe",
        sa.Column(
            "target_yield_unit",
            sa.String(50),
            nullable=False,
            server_default="portions",
        ),
    )

    # ── productionrun ──────────────────────────────────────────────────
    op.create_table(
        "productionrun",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("store_id", sa.Uuid(), nullable=False),
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
        sa.Column("target_output_quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("status", sa.Enum("pending", "in_progress", "completed",
                                    name="runstatus", native_enum=True),
                  nullable=False, server_default="pending"),
        sa.Column("leading_component_item_id", sa.Uuid(), nullable=True),
        sa.Column("yield_tolerance_percent", sa.Numeric(12, 3),
                  nullable=False, server_default="5"),
        sa.Column("actual_output_quantity", sa.Numeric(12, 3), nullable=True),
        sa.Column("waste_reason", sa.String(500), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by", sa.Uuid(), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["recipe_id"], ["recipe.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["leading_component_item_id"], ["item.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_productionrun_business_id"), "productionrun", ["business_id"])
    op.create_index(op.f("ix_productionrun_store_id"), "productionrun", ["store_id"])
    op.create_index(op.f("ix_productionrun_recipe_id"), "productionrun", ["recipe_id"])

    # ── productionruncomponent ─────────────────────────────────────────
    op.create_table(
        "productionruncomponent",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("production_run_id", sa.Uuid(), nullable=False),
        sa.Column("raw_material_item_id", sa.Uuid(), nullable=False),
        sa.Column("planned_quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("measured_quantity", sa.Numeric(12, 3), nullable=True),
        sa.ForeignKeyConstraint(["production_run_id"], ["productionrun.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["raw_material_item_id"], ["item.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("production_run_id", "raw_material_item_id",
                            name="uq_run_components_run_ingredient"),
    )
    op.create_index(op.f("ix_productionruncomponent_production_run_id"),
                    "productionruncomponent", ["production_run_id"])

    # ── productionevent: run linkage + waste reason ────────────────────
    op.add_column("productionevent", sa.Column("run_id", sa.Uuid(), nullable=True))
    op.add_column("productionevent", sa.Column("waste_reason", sa.String(500), nullable=True))
    op.create_index(op.f("ix_productionevent_run_id"), "productionevent", ["run_id"])
    op.create_foreign_key("fk_productionevent_run_id", "productionevent", "productionrun",
                          ["run_id"], ["id"], ondelete="RESTRICT")


def downgrade() -> None:
    op.drop_constraint("fk_productionevent_run_id", "productionevent", type_="foreignkey")
    op.drop_index(op.f("ix_productionevent_run_id"), table_name="productionevent")
    op.drop_column("productionevent", "waste_reason")
    op.drop_column("productionevent", "run_id")
    op.drop_index(op.f("ix_productionruncomponent_production_run_id"),
                   table_name="productionruncomponent")
    op.drop_table("productionruncomponent")
    op.drop_index(op.f("ix_productionrun_recipe_id"), table_name="productionrun")
    op.drop_index(op.f("ix_productionrun_store_id"), table_name="productionrun")
    op.drop_index(op.f("ix_productionrun_business_id"), table_name="productionrun")
    op.drop_table("productionrun")
    op.drop_column("recipe", "target_yield_unit")
    op.drop_column("recipe", "target_yield_quantity")
    op.drop_column("recipe", "category")
    op.execute("DROP TYPE runstatus")
