"""rename business_locations to store, add store settings

Corrects the earlier collapsed approach:

* ``business_locations`` → ``store`` (table rename). The store now carries
  only location/identity fields plus ``token`` (unique identifier, no auth
  semantics), ``status`` (same enum pattern as businesses), and real
  soft-delete columns (``is_deleted`` / ``deleted_at`` already existed;
  ``deleted_by`` is added as a real FK to ``users.id``). The earlier
  (unapplied) idea of putting email/phone/lat/long directly on the store
  is deliberately NOT implemented here — those columns belong on the new
  ``store_settings`` table below.
* ``store_settings`` — new one-to-one table (unique ``store_id``) holding
  address/coordinates/contact/preferences. A row is backfilled for every
  existing store and is always created alongside new stores by the
  business-creation flow.
* ``businesses`` — adds the previously-deferred fields (registration
  number, email, phone, address, status, logo) plus real ``deleted_by`` FK.

The ``user_business_location_roles`` table (employee-at-store mapping) is
preserved unchanged except its ``business_location_id`` column is renamed
to ``store_id`` to follow the store rename. No employee table is duplicated.

Revision ID: d4e5f6a7b8c9
Revises: 6c842160a0cb
Create Date: 2026-08-06
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d4e5f6a7b8c9"
down_revision: Union[str, None] = "6c842160a0cb"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _uuuid() -> sa.UUID:
    return sa.UUID()


def _utcdt() -> sa.DateTime:
    return sa.DateTime(timezone=True)


def upgrade() -> None:
    # ── 1. Rename business_locations → store (and its constraints) ────────
    op.rename_table("business_locations", "store")

    op.drop_index("ix_business_locations_business_id", table_name="store")
    op.create_index("ix_store_business_id", "store", ["business_id"])

    op.drop_constraint(
        "uq_business_locations_business_id_name", "store", type_="unique"
    )
    op.create_unique_constraint("uq_store_business_id_name", "store", ["business_id", "name"])

    op.drop_constraint("fk_business_locations_business_id", "store", type_="foreignkey")
    op.create_foreign_key(
        "fk_store_business_id", "store", "businesses", ["business_id"], ["id"],
        ondelete="CASCADE",
    )

    # ── 2. New store columns ───────────────────────────────────────────────
    op.add_column("store", sa.Column("token", sa.String(64), nullable=True))
    op.execute("UPDATE store SET token = gen_random_uuid()::text WHERE token IS NULL")
    op.alter_column("store", "token", existing_type=sa.String(64), nullable=False)
    op.create_unique_constraint("uq_store_token", "store", ["token"])

    op.add_column(
        "store",
        sa.Column("status", sa.String(20), server_default=sa.text("'active'"), nullable=False),
    )
    op.add_column("store", sa.Column("deleted_by", _uuuid(), nullable=True))
    op.create_foreign_key("fk_store_deleted_by", "store", "users", ["deleted_by"], ["id"])

    # ── 3. employee mapping: business_location_id → store_id ──────────────
    op.drop_constraint("uq_user_business_location_roles", "user_business_location_roles", type_="unique")
    op.drop_constraint("fk_ublr_business_location_id", "user_business_location_roles", type_="foreignkey")
    op.alter_column("user_business_location_roles", "business_location_id", new_column_name="store_id")
    op.create_foreign_key(
        "fk_ublr_store_id", "user_business_location_roles", "store", ["store_id"], ["id"],
        ondelete="CASCADE",
    )
    op.create_unique_constraint(
        "uq_user_business_location_roles",
        "user_business_location_roles",
        ["user_id", "store_id", "business_role_id"],
    )

    # ── 4. New businesses columns ─────────────────────────────────────────
    op.add_column("businesses", sa.Column("registration_number", sa.String(100), nullable=True))
    op.add_column("businesses", sa.Column("email", sa.String(255), nullable=True))
    op.add_column("businesses", sa.Column("phone", sa.String(20), nullable=True))
    op.add_column("businesses", sa.Column("address", sa.String(500), nullable=True))
    op.add_column(
        "businesses",
        sa.Column("status", sa.String(20), server_default=sa.text("'active'"), nullable=False),
    )
    op.add_column("businesses", sa.Column("logo", sa.String(500), nullable=True))
    op.add_column("businesses", sa.Column("deleted_by", _uuuid(), nullable=True))
    op.create_foreign_key("fk_businesses_deleted_by", "businesses", "users", ["deleted_by"], ["id"])

    # ── 5. store_settings (one-to-one with store) ─────────────────────────
    op.create_table(
        "store_settings",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("store_id", _uuuid(), nullable=False),
        sa.Column("active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("address", sa.String(500), nullable=True),
        sa.Column("latitude", sa.Numeric(9, 6), nullable=True),
        sa.Column("longitude", sa.Numeric(9, 6), nullable=True),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("phone", sa.String(20), nullable=True),
        sa.Column("preferred_currency", sa.String(3), server_default=sa.text("'TZS'"), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=True),
        sa.Column("max_payment_time_minutes", sa.Integer(), nullable=True),
        sa.Column("logo", sa.String(500), nullable=True),
        sa.Column("offer_retail", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("offer_wholesale", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column(
            "display_prices_inclusive_of_tax",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
        sa.Column("deleted_by", _uuuid(), nullable=True),
    )
    op.create_unique_constraint("uq_store_settings_store_id", "store_settings", ["store_id"])
    op.create_foreign_key(
        "fk_store_settings_store_id", "store_settings", "store", ["store_id"], ["id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_store_settings_deleted_by", "store_settings", "users", ["deleted_by"], ["id"],
    )

    # Backfill: every existing store gets its default settings row.
    op.execute(
        "INSERT INTO store_settings (id, created_at, updated_at, active, is_deleted, store_id) "
        "SELECT gen_random_uuid(), now(), now(), true, false, id FROM store"
    )


def downgrade() -> None:
    op.drop_table("store_settings")

    op.drop_constraint("fk_businesses_deleted_by", "businesses", type_="foreignkey")
    op.drop_column("businesses", "deleted_by")
    op.drop_column("businesses", "logo")
    op.drop_column("businesses", "status")
    op.drop_column("businesses", "address")
    op.drop_column("businesses", "phone")
    op.drop_column("businesses", "email")
    op.drop_column("businesses", "registration_number")

    # Employee mapping: drop store-scoped constraints, rename the column back.
    op.drop_constraint("uq_user_business_location_roles", "user_business_location_roles", type_="unique")
    op.drop_constraint("fk_ublr_store_id", "user_business_location_roles", type_="foreignkey")
    op.alter_column("user_business_location_roles", "store_id", new_column_name="business_location_id")

    # Store: drop all store-scoped columns/constraints before renaming the table.
    op.drop_constraint("fk_store_deleted_by", "store", type_="foreignkey")
    op.drop_column("store", "deleted_by")
    op.drop_constraint("uq_store_token", "store", type_="unique")
    op.drop_column("store", "token")
    op.drop_column("store", "status")
    op.drop_constraint("fk_store_business_id", "store", type_="foreignkey")
    op.drop_constraint("uq_store_business_id_name", "store", type_="unique")
    op.drop_index("ix_store_business_id", table_name="store")

    # Rename the table back, then restore the employee-mapping FK (which must
    # reference the now-existing business_locations table).
    op.rename_table("store", "business_locations")

    op.create_foreign_key(
        "fk_ublr_business_location_id",
        "user_business_location_roles",
        "business_locations",
        ["business_location_id"], ["id"],
        ondelete="CASCADE",
    )
    op.create_unique_constraint(
        "uq_user_business_location_roles",
        "user_business_location_roles",
        ["user_id", "business_location_id", "business_role_id"],
    )

    op.create_index("ix_business_locations_business_id", "business_locations", ["business_id"])
    op.create_unique_constraint(
        "uq_business_locations_business_id_name", "business_locations", ["business_id", "name"],
    )
    op.create_foreign_key(
        "fk_business_locations_business_id",
        "business_locations", "businesses",
        ["business_id"], ["id"], ondelete="CASCADE",
    )
