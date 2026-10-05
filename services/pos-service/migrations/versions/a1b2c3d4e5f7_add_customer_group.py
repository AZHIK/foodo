"""Add customers.customer_group for the Customer Groups Report.

Revision ID: a1b2c3d4e5f7
Revises: 3c2fa01b639c
Create Date: 2026-10-05 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f7"
down_revision: Union[str, None] = "f6a7b8c9d0e2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("customers", sa.Column("customer_group", sa.String(100), nullable=True))
    op.create_index("ix_customers_customer_group", "customers", ["customer_group"])


def downgrade() -> None:
    op.drop_index("ix_customers_customer_group", table_name="customers")
    op.drop_column("customers", "customer_group")
