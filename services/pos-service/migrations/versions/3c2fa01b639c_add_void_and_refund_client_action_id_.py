"""add void and refund client action id columns

Revision ID: 3c2fa01b639c
Revises: c3d4e5f6a7b8
Create Date: 2026-09-07 15:29:06.289399
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel  # noqa: F401


# revision identifiers, used by Alembic.
revision: str = '3c2fa01b639c'
down_revision: Union[str, None] = 'c3d4e5f6a7b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("sales", sa.Column("void_client_action_id", sa.String(255), nullable=True))
    op.add_column("sales", sa.Column("refund_client_action_id", sa.String(255), nullable=True))
    op.create_unique_constraint(
        "uq_sales_void_client_action_id", "sales", ["void_client_action_id"]
    )
    op.create_unique_constraint(
        "uq_sales_refund_client_action_id", "sales", ["refund_client_action_id"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_sales_refund_client_action_id", "sales", type_="unique")
    op.drop_constraint("uq_sales_void_client_action_id", "sales", type_="unique")
    op.drop_column("sales", "refund_client_action_id")
    op.drop_column("sales", "void_client_action_id")
