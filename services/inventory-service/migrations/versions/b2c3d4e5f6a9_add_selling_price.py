"""add selling_price to item.

Adds the current sell price for an item, sourced from Inventory Service.
POS Service continues to capture unit_price AT TIME OF SALE independently
— this column is the *current* price the Business App caches before a
sale happens.

The column is nullable because a raw_material-only item genuinely has no
selling price; do not force a value where none makes sense.

Money discipline: NUMERIC(12,2), matching POS Service's unit_price /
subtotal / total_amount columns.  Never a float — Decimal round-trips
exactly through Postgres.

Revision ID: b2c3d4e5f6a9
Revises: b2c3d4e5f6a8
Create Date: 2026-07-31
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "b2c3d4e5f6a9"
down_revision: Union[str, None] = "b2c3d4e5f6a8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "item",
        sa.Column(
            "selling_price",
            sa.Numeric(precision=12, scale=2),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("item", "selling_price")
