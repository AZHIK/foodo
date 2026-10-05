"""Add lot_no / expiry_date to goods receipt lines for Lot + Expiry reports.

Revision ID: p8q9r0s1t2u3
Revises: n2b3c4d5e6f7
Create Date: 2026-10-05 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "p8q9r0s1t2u3"
down_revision: Union[str, None] = "n2b3c4d5e6f7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "goodsreceiptline",
        sa.Column("lot_no", sa.String(64), nullable=True),
    )
    op.add_column(
        "goodsreceiptline",
        sa.Column("expiry_date", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_goodsreceiptline_lot_no", "goodsreceiptline", ["lot_no"])
    op.create_index("ix_goodsreceiptline_expiry_date", "goodsreceiptline", ["expiry_date"])


def downgrade() -> None:
    op.drop_index("ix_goodsreceiptline_expiry_date", table_name="goodsreceiptline")
    op.drop_index("ix_goodsreceiptline_lot_no", table_name="goodsreceiptline")
    op.drop_column("goodsreceiptline", "expiry_date")
    op.drop_column("goodsreceiptline", "lot_no")
