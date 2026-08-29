"""Rename business_location_id to store_id on item, stocklevel, stockmovement.

Part of the business_location -> store rename: a "business location" and a
"store" are the same concept, so the redundant name is dropped here to match
Identity Service's ``store`` table.

Revision ID: c2d3e4f5a6b7
Revises: b2c3d4e5f6ab
Create Date: 2026-08-29
"""

from typing import Sequence, Union

from alembic import op

revision: str = "c2d3e4f5a6b7"
down_revision: Union[str, None] = "b2c3d4e5f6ab"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE item RENAME COLUMN business_location_id TO store_id")
    op.execute("ALTER INDEX ix_item_business_location_id RENAME TO ix_item_store_id")

    op.execute("ALTER TABLE stocklevel RENAME COLUMN business_location_id TO store_id")
    op.execute("ALTER INDEX ix_stocklevel_business_location_id RENAME TO ix_stocklevel_store_id")
    op.execute(
        "ALTER TABLE stocklevel RENAME CONSTRAINT "
        "uq_stock_levels_item_location TO uq_stock_levels_item_store"
    )

    op.execute("ALTER TABLE stockmovement RENAME COLUMN business_location_id TO store_id")


def downgrade() -> None:
    op.execute("ALTER TABLE stockmovement RENAME COLUMN store_id TO business_location_id")

    op.execute(
        "ALTER TABLE stocklevel RENAME CONSTRAINT "
        "uq_stock_levels_item_store TO uq_stock_levels_item_location"
    )
    op.execute("ALTER INDEX ix_stocklevel_store_id RENAME TO ix_stocklevel_business_location_id")
    op.execute("ALTER TABLE stocklevel RENAME COLUMN store_id TO business_location_id")

    op.execute("ALTER INDEX ix_item_store_id RENAME TO ix_item_business_location_id")
    op.execute("ALTER TABLE item RENAME COLUMN store_id TO business_location_id")
