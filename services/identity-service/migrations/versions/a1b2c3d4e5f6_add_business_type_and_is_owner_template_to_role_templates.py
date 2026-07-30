"""add_business_type_and_is_owner_template_to_role_templates

Revision ID: a1b2c3d4e5f6
Revises: 8f1e2d3c4b5a
Create Date: 2026-07-23 10:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "7a8b9c0d1e2f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "role_templates",
        sa.Column("business_type", sa.String(20), nullable=True),
    )
    op.add_column(
        "role_templates",
        sa.Column(
            "is_owner_template",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_role_templates_business_type",
        "role_templates",
        ["business_type"],
    )


def downgrade() -> None:
    op.drop_index("ix_role_templates_business_type", table_name="role_templates")
    op.drop_column("role_templates", "is_owner_template")
    op.drop_column("role_templates", "business_type")
