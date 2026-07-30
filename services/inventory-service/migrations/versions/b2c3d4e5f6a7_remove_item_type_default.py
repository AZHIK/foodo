"""remove_item_type_default — drop the permissive 'both' default from item_type.

item_type must now be explicitly provided by the caller.  The silent
default to ``both`` was a design gap — it allowed callers to create items
without classifying them, which would break Stage 5's movement-type
compatibility checks.

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-07-28
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "b2c3d4e5f6a7"
down_revision: Union[str, None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "item",
        "item_type",
        server_default=None,
        type_=sa.Enum("sellable", "raw_material", "both", name="itemtype"),
        postgresql_using="item_type::text::itemtype",
    )


def downgrade() -> None:
    op.alter_column(
        "item",
        "item_type",
        server_default=sa.text("'both'"),
        type_=sa.Enum("sellable", "raw_material", "both", name="itemtype"),
        postgresql_using="item_type::text::itemtype",
    )