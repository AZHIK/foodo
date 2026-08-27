"""enforce one business per owner, add license_document_url and cuisine_type

* ``businesses.owner_user_id`` gets a unique constraint — one business per
  owner from here on. This will fail to apply if any existing owner already
  has more than one non-deleted business; de-duplicate that data first.
* ``businesses.license_document_url`` — placeholder URL/path column for a
  business license/registration document, same non-upload pattern as
  ``logo``.
* ``businesses.cuisine_type`` — free-text cuisine classification.

Revision ID: f6a7b8c9d0e1
Revises: d4e5f6a7b8c9
Create Date: 2026-08-27
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f6a7b8c9d0e1"
down_revision: Union[str, None] = "d4e5f6a7b8c9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_unique_constraint("uq_businesses_owner_user_id", "businesses", ["owner_user_id"])
    op.add_column("businesses", sa.Column("license_document_url", sa.String(500), nullable=True))
    op.add_column("businesses", sa.Column("cuisine_type", sa.String(100), nullable=True))


def downgrade() -> None:
    op.drop_column("businesses", "cuisine_type")
    op.drop_column("businesses", "license_document_url")
    op.drop_constraint("uq_businesses_owner_user_id", "businesses", type_="unique")
