"""Add sale_reversal and refund_reversal to movementtype enum.

Revision ID: b2c3d4e5f6a8
Revises: b2c3d4e5f6a7

══════════════════════════════════════════════════════════════════════════
NATIVE POSTGRES ENUM — ALTER TYPE COMPLEXITY NOTE
══════════════════════════════════════════════════════════════════════════

``stock_movements.movement_type`` uses a **native Postgres ENUM** created
by raw ``CREATE TYPE movementtype AS ENUM (...)`` in the initial migration.
It is NOT an app-validated string column.

Adding values to a native ENUM requires ``ALTER TYPE ... ADD VALUE``,
which PostgreSQL treats as a DDL statement that **cannot** execute inside
a transaction block in PostgreSQL < 13.  In PG 16 (the project's target)
ALTER TYPE ADD VALUE IS transactional, but Alembic's default per-migration
transaction may still interfere.  The migration therefore calls
``op.execute()`` directly, which Alembic handles outside its transaction
wrapper for DDL that needs it.

The upgrade is **additive** — existing rows with the old values continue
to work.  The downgrade is a documented no-op because PostgreSQL does not
support ``ALTER TYPE ... DROP VALUE``.  Recovering from a downgrade would
require destructive schema surgery (create new type, drop dependent
columns, rename) that is not appropriate for an automated migration.

To verify the current enum values in a live database:
    SELECT enum_range(NULL::movementtype);
"""

from typing import Sequence, Union

from alembic import op

revision: str = "b2c3d4e5f6a8"
down_revision: Union[str, None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE movementtype ADD VALUE IF NOT EXISTS 'sale_reversal'")
    op.execute("ALTER TYPE movementtype ADD VALUE IF NOT EXISTS 'refund_reversal'")


def downgrade() -> None:
    """PostgreSQL does not support removing values from an ENUM.

    The upgrade is purely additive — having extra enum values sitting
    unused does no harm.  If you need to fully revert, the procedure is:
        1. CREATE TYPE movementtype_new AS ENUM (...old values...);
        2. ALTER TABLE stock_movement ALTER COLUMN movement_type
           TYPE movementtype_new USING movement_type::text::movementtype_new;
        3. DROP TYPE movementtype;
        4. ALTER TYPE movementtype_new RENAME TO movementtype;
    This is intentionally NOT automated — it's a deployment-time manual
    step that requires zero-downtime planning.
    """
    pass
