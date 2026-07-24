"""add_unique_constraint_to_business_roles_name_per_business

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-07-23 12:00:00.000000
"""

from typing import Sequence, Union

from alembic import op

revision: str = "b2c3d4e5f6a7"
down_revision: Union[str, None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_unique_constraint(
        "uq_business_roles_business_id_name",
        "business_roles",
        ["business_id", "name"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_business_roles_business_id_name",
        "business_roles",
        type_="unique",
    )
