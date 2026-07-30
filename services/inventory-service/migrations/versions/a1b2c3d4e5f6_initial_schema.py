"""initial_schema — explicit op.execute() revision using raw SQL.

Creates all five inventory tables with proper foreign keys (only within
this database — business_id and business_location_id are plain indexed
UUID columns that reference Identity Service's database, not FKs),
enum types, indexes, and the composite unique constraint on stock_levels.

Uses raw SQL for `CREATE TABLE` to avoid SQLAlchemy/Alembic enum-type
re-creation issues in the installed version.  `op.drop_table()` is still
used for downgrade since no type-creation triggers are involved.

Revision ID: a1b2c3d4e5f6
Revises:
Create Date: 2026-07-28
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. Create enum types (idempotent via PL/pgSQL DO block) ──────────
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'unitofmeasure') THEN
                CREATE TYPE unitofmeasure AS ENUM ('kg', 'g', 'l', 'ml', 'unit', 'pack');
            END IF;
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'itemtype') THEN
                CREATE TYPE itemtype AS ENUM ('sellable', 'raw_material', 'both');
            END IF;
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'movementtype') THEN
                CREATE TYPE movementtype AS ENUM ('sale', 'purchase_received', 'manual_adjustment', 'waste', 'transfer_in', 'transfer_out');
            END IF;
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'actortype') THEN
                CREATE TYPE actortype AS ENUM ('user', 'system', 'service');
            END IF;
        END
        $$;
    """)

    # ── 2. Tables ────────────────────────────────────────────────────────
    # processed_events (no FK)
    op.execute("""
        CREATE TABLE processedevent (
            event_id      VARCHAR(255) PRIMARY KEY,
            processed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    """)

    # items (cross-service refs are plain UUIDs, not FKs)
    op.execute("""
        CREATE TABLE item (
            id                    UUID PRIMARY KEY,
            business_id           UUID NOT NULL,
            business_location_id  UUID NOT NULL,
            name                  VARCHAR(255) NOT NULL,
            unit_of_measure       unitofmeasure NOT NULL,
            category              VARCHAR(255),
            reorder_threshold     NUMERIC(12,3) NOT NULL,
            reorder_quantity      NUMERIC(12,3) NOT NULL,
            allow_negative_stock  BOOLEAN NOT NULL DEFAULT FALSE,
            item_type             itemtype NOT NULL DEFAULT 'both',
            is_active             BOOLEAN NOT NULL DEFAULT TRUE,
            created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    """)

    # recipe_components (FKs to item)
    op.execute("""
        CREATE TABLE recipecomponent (
            id                    UUID PRIMARY KEY,
            sellable_item_id      UUID NOT NULL REFERENCES item(id) ON DELETE CASCADE,
            raw_material_item_id  UUID NOT NULL REFERENCES item(id) ON DELETE CASCADE,
            quantity_required     NUMERIC(12,3) NOT NULL
        )
    """)

    # stock_levels (FK to item, composite unique constraint)
    op.execute("""
        CREATE TABLE stocklevel (
            id                    UUID PRIMARY KEY,
            item_id               UUID NOT NULL REFERENCES item(id) ON DELETE CASCADE,
            business_location_id  UUID NOT NULL,
            current_quantity      NUMERIC(12,3) NOT NULL,
            updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT uq_stock_levels_item_location UNIQUE (item_id, business_location_id)
        )
    """)

    # stock_movements (immutable audit trail — FK to item)
    op.execute("""
        CREATE TABLE stockmovement (
            id                    UUID PRIMARY KEY,
            item_id               UUID NOT NULL REFERENCES item(id) ON DELETE CASCADE,
            business_id           UUID NOT NULL,
            business_location_id  UUID NOT NULL,
            quantity_delta        NUMERIC(12,3) NOT NULL,
            movement_type         movementtype NOT NULL,
            reference_type        VARCHAR(100),
            reference_id          UUID,
            actor_type            actortype NOT NULL,
            actor_id              UUID,
            reason                VARCHAR(500),
            created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    """)

    # ── 3. Indexes ──────────────────────────────────────────────────────
    op.execute("CREATE INDEX ix_item_business_id ON item (business_id)")
    op.execute("CREATE INDEX ix_item_business_location_id ON item (business_location_id)")
    op.execute("CREATE INDEX ix_stockmovement_item_id ON stockmovement (item_id)")
    op.execute("CREATE INDEX ix_stockmovement_business_id ON stockmovement (business_id)")
    op.execute("CREATE INDEX ix_stockmovement_created_at ON stockmovement (created_at)")
    op.execute("CREATE INDEX ix_stocklevel_business_location_id ON stocklevel (business_location_id)")


def downgrade() -> None:
    op.drop_table("stockmovement")
    op.drop_table("stocklevel")
    op.drop_table("recipecomponent")
    op.drop_table("item")
    op.drop_table("processedevent")
    op.execute("DROP TYPE IF EXISTS actortype")
    op.execute("DROP TYPE IF EXISTS movementtype")
    op.execute("DROP TYPE IF EXISTS itemtype")
    op.execute("DROP TYPE IF EXISTS unitofmeasure")