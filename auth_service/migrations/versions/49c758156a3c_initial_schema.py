"""initial_schema

Revision ID: 49c758156a3c
Revises:
Create Date: 2026-07-10 10:22:42.575364
"""

from typing import Sequence, Union

from alembic import op
from sqlmodel import SQLModel

from app.models import *  # noqa: F401, F403


revision: str = "49c758156a3c"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    SQLModel.metadata.create_all(op.get_bind())


def downgrade() -> None:
    SQLModel.metadata.drop_all(op.get_bind())
