"""remove_audit_logs

Revision ID: 5e4d74c8c2a1
Revises: 49c758156a3c
Create Date: 2026-07-10 14:30:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "5e4d74c8c2a1"
down_revision: Union[str, None] = "49c758156a3c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # audit_logs was never created by the rewritten 49c758156a3c
    # revision — this is now a no-op.
    pass


def downgrade() -> None:
    pass
