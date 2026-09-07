"""add unit_cost to item.

Cost basis for the inventory-value reporting metric (stock * unit_cost).
Distinct from selling_price (retail): a raw_material item typically has a
cost but no selling_price, and the two can legitimately differ for a
`both`-type item.

The column is nullable for the same reason selling_price is — plenty of
items (and every item created before this migration) have no cost on file
yet.

Money discipline: NUMERIC(12,4) — one more decimal place than
selling_price/POS's money columns, since a per-unit cost for something
priced by weight/volume (e.g. cost per gram) needs finer precision than a
per-sale line total.

Revision ID: d3e4f5a6b7c8
Revises: c2d3e4f5a6b7
Create Date: 2026-09-07
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "d3e4f5a6b7c8"
down_revision: Union[str, None] = "c2d3e4f5a6b7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "item",
        sa.Column(
            "unit_cost",
            sa.Numeric(precision=12, scale=4),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("item", "unit_cost")
