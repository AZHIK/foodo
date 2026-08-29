"""Rename sales.business_location_id to store_id.

Part of the business_location -> store rename: a "business location" and a
"store" are the same concept, so the redundant name is dropped here to match
Identity Service's ``store`` table.

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-08-29
"""

from typing import Sequence, Union

from alembic import op

revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column("sales", "business_location_id", new_column_name="store_id")
    op.execute("ALTER INDEX ix_sales_business_location_id RENAME TO ix_sales_store_id")


def downgrade() -> None:
    op.execute("ALTER INDEX ix_sales_store_id RENAME TO ix_sales_business_location_id")
    op.alter_column("sales", "store_id", new_column_name="business_location_id")
