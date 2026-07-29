"""initial_empty_schema

Revision ID: 02724c7d24c8
Revises: 576293729913
Create Date: 2026-07-29 10:25:05.034942
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel  # noqa: F401


# revision identifiers, used by Alembic.
revision: str = '02724c7d24c8'
down_revision: Union[str, None] = '576293729913'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
