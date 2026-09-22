"""Add target_output_quantity to productionevent (target-based flow).

The cook enters a goal ("I need N products") before measuring; the plan
endpoint recommends per-ingredient amounts, the produce endpoint stores
the goal, and reads compute the above/within/below-threshold verdict
against it. Nullable so pre-target runs keep a NULL goal and fall back
to the suggestion as the verdict baseline.

Revision ID: j7e8f9a0b1c2
Revises: i6d7e8f9a0b1
Create Date: 2026-09-20
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "j7e8f9a0b1c2"
down_revision: Union[str, None] = "i6d7e8f9a0b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "productionevent",
        sa.Column("target_output_quantity", sa.Numeric(12, 3), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("productionevent", "target_output_quantity")
