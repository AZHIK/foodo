"""increase_auth_risk_events_event_type_length

Increase event_type column length from 20 to 50 to accommodate
enum values like 'password_reset_request' (22 chars).

Revision ID: 6c842160a0cb
Revises: c1d2e3f4a5b6
Create Date: 2026-08-04 12:29:02.056483
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6c842160a0cb'
down_revision: Union[str, None] = 'c1d2e3f4a5b6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "auth_risk_events",
        "event_type",
        existing_type=sa.String(20),
        type_=sa.String(50),
        existing_nullable=False,
    )
    op.alter_column(
        "auth_risk_events",
        "risk_level",
        existing_type=sa.String(10),
        type_=sa.String(20),
        existing_nullable=False,
    )


def downgrade() -> None:
    op.alter_column(
        "auth_risk_events",
        "event_type",
        existing_type=sa.String(50),
        type_=sa.String(20),
        existing_nullable=False,
    )
    op.alter_column(
        "auth_risk_events",
        "risk_level",
        existing_type=sa.String(20),
        type_=sa.String(10),
        existing_nullable=False,
    )