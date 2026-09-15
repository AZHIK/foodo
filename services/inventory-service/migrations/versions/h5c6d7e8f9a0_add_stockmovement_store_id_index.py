"""add ix_stockmovement_store_id index.

``StockMovement.store_id`` is declared ``index=True`` in the model, but no
migration ever created the index — every movement-history query filters by
store, so the lookup was scanning. Purely additive: creates the one index,
drops it on downgrade.

Revision ID: h5c6d7e8f9a0
Revises: g4b5c6d7e8f9
Create Date: 2026-09-14
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "h5c6d7e8f9a0"
down_revision: Union[str, None] = "g4b5c6d7e8f9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index(
        "ix_stockmovement_store_id",
        "stockmovement",
        ["store_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_stockmovement_store_id", table_name="stockmovement")
