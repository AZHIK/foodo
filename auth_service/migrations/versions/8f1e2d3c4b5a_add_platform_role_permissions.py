"""add_platform_role_permissions

Revision ID: 8f1e2d3c4b5a
Revises: 5e4d74c8c2a1
Create Date: 2026-07-21 17:50:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "8f1e2d3c4b5a"
down_revision: Union[str, None] = "5e4d74c8c2a1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "platform_role_permissions",
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("platform_role_id", sa.UUID(), nullable=False),
        sa.Column("permission_code", sa.String(length=100), nullable=False),
        sa.ForeignKeyConstraint(["platform_role_id"], ["platform_roles.id"]),
        sa.PrimaryKeyConstraint("platform_role_id", "permission_code"),
    )


def downgrade() -> None:
    op.drop_table("platform_role_permissions")
