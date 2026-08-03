"""relax_role_templates_name_uniqueness_to_name_plus_business_type

Role template names are identical across business types by design (e.g. supplier
and distributor both define "Sales Admin" / "Warehouse Staff").  The global
unique constraint on ``role_templates.name`` prevented that, so it is replaced
with a composite unique on (name, business_type).

Revision ID: c1d2e3f4a5b6
Revises: b2c3d4e5f6a7
Create Date: 2026-08-03 12:00:00.000000
"""

from typing import Sequence, Union

from alembic import op

revision: str = "c1d2e3f4a5b6"
down_revision: Union[str, None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint("uq_role_templates_name", "role_templates", type_="unique")
    op.create_unique_constraint(
        "uq_role_templates_name_business_type",
        "role_templates",
        ["name", "business_type"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_role_templates_name_business_type",
        "role_templates",
        type_="unique",
    )
    op.create_unique_constraint("uq_role_templates_name", "role_templates", ["name"])
