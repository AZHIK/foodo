"""Link item directly to supplier (optional preferred supplier).

Adds nullable ``supplier_id`` FK on ``item`` → ``supplier.id`` with
``ON DELETE SET NULL``: an item may declare its preferred/default supplier
for restocking, but the link is optional (null = no preferred supplier).
SET NULL (not RESTRICT) so retiring a supplier row never blocks on items
that referenced it — the items simply become unlinked.

Revision ID: l9a0b1c2d3e4
Revises: k8f9a0b1c2d3
Create Date: 2026-09-22
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "l9a0b1c2d3e4"
down_revision: Union[str, None] = "k8f9a0b1c2d3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("item", sa.Column("supplier_id", sa.Uuid(), nullable=True))
    op.create_index(op.f("ix_item_supplier_id"), "item", ["supplier_id"])
    op.create_foreign_key(
        "fk_item_supplier_id", "item", "supplier", ["supplier_id"], ["id"], ondelete="SET NULL"
    )


def downgrade() -> None:
    op.drop_constraint("fk_item_supplier_id", "item", type_="foreignkey")
    op.drop_index(op.f("ix_item_supplier_id"), table_name="item")
    op.drop_column("item", "supplier_id")
