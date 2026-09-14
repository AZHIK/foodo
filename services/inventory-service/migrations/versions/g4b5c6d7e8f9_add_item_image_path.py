"""add image_path to item.

Storage key of the item's product photo (see
``app/services/item_image_storage.py``) — the relative path under the
configured image storage root, e.g. ``"<business_id>/<item_id>.jpg"``.

The column is nullable: every item created before this migration (and any
item without a photo) simply has no photo, and callers fall back to the
display placeholder. Photos are replaced in place — one photo per item —
so no history or versioning columns are needed.

Revision ID: g4b5c6d7e8f9
Revises: f3a4b5c6d7e8
Create Date: 2026-09-14
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "g4b5c6d7e8f9"
down_revision: Union[str, None] = "f3a4b5c6d7e8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "item",
        sa.Column(
            "image_path",
            sa.String(length=512),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("item", "image_path")
