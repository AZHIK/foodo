"""drop redundant ix_recipe_sellable_item_id index.

``recipe.sellable_item_id`` is already covered by the ``uq_recipe_sellable_item``
unique constraint (which Postgres backs with its own index), so this plain
duplicate only taxed writes. Dropping it aligns the database with the models.

Revision ID: i6d7e8f9a0b1
Revises: h5c6d7e8f9a0
Create Date: 2026-09-14
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "i6d7e8f9a0b1"
down_revision: Union[str, None] = "h5c6d7e8f9a0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_index("ix_recipe_sellable_item_id", table_name="recipe")


def downgrade() -> None:
    op.create_index(
        "ix_recipe_sellable_item_id",
        "recipe",
        ["sellable_item_id"],
    )
