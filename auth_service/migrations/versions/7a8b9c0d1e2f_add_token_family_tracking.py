"""add_token_family_tracking

Add ``family_id``, ``previous_token_id``, and ``replaced_by_token_id`` to
``refresh_tokens`` to enable token-family replay detection and full-family
revocation on theft signal.

Revision ID: 7a8b9c0d1e2f
Revises: 8f1e2d3c4b5a
Create Date: 2026-07-23 08:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID as PG_UUID

revision: str = "7a8b9c0d1e2f"
down_revision: Union[str, None] = "8f1e2d3c4b5a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add family_id — start nullable so we can backfill existing rows.
    op.add_column("refresh_tokens", sa.Column("family_id", PG_UUID, nullable=True))
    op.execute("UPDATE refresh_tokens SET family_id = id WHERE family_id IS NULL")
    op.alter_column("refresh_tokens", "family_id", nullable=False)
    op.create_index("ix_refresh_tokens_family_id", "refresh_tokens", ["family_id"])

    # 2. Self-referencing FK columns for token lineage.
    op.add_column("refresh_tokens", sa.Column("previous_token_id", PG_UUID, nullable=True))
    op.add_column("refresh_tokens", sa.Column("replaced_by_token_id", PG_UUID, nullable=True))

    op.create_foreign_key(
        "fk_refresh_tokens_previous_token_id",
        "refresh_tokens", "refresh_tokens",
        ["previous_token_id"], ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_refresh_tokens_replaced_by_token_id",
        "refresh_tokens", "refresh_tokens",
        ["replaced_by_token_id"], ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_refresh_tokens_replaced_by_token_id", "refresh_tokens", type_="foreignkey")
    op.drop_constraint("fk_refresh_tokens_previous_token_id", "refresh_tokens", type_="foreignkey")
    op.drop_column("refresh_tokens", "replaced_by_token_id")
    op.drop_column("refresh_tokens", "previous_token_id")
    op.drop_index("ix_refresh_tokens_family_id", table_name="refresh_tokens")
    op.drop_column("refresh_tokens", "family_id")
