"""rename user_business_location_roles to user_store_roles

Finishes the business_location -> store rename: the resource-level
permission codes (``stores.*``) were already switched over in code, but the
employee-at-store join table and its ``user_business_location_roles.*``
permission codes were left behind. This migration:

* Renames table ``user_business_location_roles`` -> ``user_store_roles``
  (and its index/constraints) to match the ``UserStoreRole`` model.
* Rewrites any persisted ``user_business_location_roles.*`` permission-code
  strings (in ``permissions``, ``business_role_permissions``,
  ``user_business_permissions``, ``platform_role_permissions``) to
  ``user_store_roles.*``, matching the renamed ``PermissionCode.USER_STORE_ROLES_*``
  enum values.

Revision ID: a2b3c4d5e6f7
Revises: f6a7b8c9d0e1
Create Date: 2026-08-29
"""

from typing import Sequence, Union

from alembic import op

revision: str = "a2b3c4d5e6f7"
down_revision: Union[str, None] = "f6a7b8c9d0e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_PERMISSION_CODE_TABLES = (
    "permissions",
    "business_role_permissions",
    "user_business_permissions",
    "platform_role_permissions",
    "role_permissions",
)


def _rewrite_permission_codes(old_prefix: str, new_prefix: str) -> None:
    for table in _PERMISSION_CODE_TABLES:
        column = "code" if table == "permissions" else "permission_code"
        op.execute(
            f"UPDATE {table} SET {column} = replace({column}, '{old_prefix}', '{new_prefix}') "
            f"WHERE {column} LIKE '{old_prefix}%'"
        )


def upgrade() -> None:
    op.rename_table("user_business_location_roles", "user_store_roles")
    op.execute("ALTER INDEX ix_user_business_location_roles_id RENAME TO ix_user_store_roles_id")
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT "
        "user_business_location_roles_pkey TO user_store_roles_pkey"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_ublr_user_id "
        "TO fk_user_store_roles_user_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_ublr_business_id "
        "TO fk_user_store_roles_business_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_ublr_store_id "
        "TO fk_user_store_roles_store_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_ublr_business_role_id "
        "TO fk_user_store_roles_business_role_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT uq_user_business_location_roles "
        "TO uq_user_store_roles"
    )

    _rewrite_permission_codes("user_business_location_roles.", "user_store_roles.")


def downgrade() -> None:
    _rewrite_permission_codes("user_store_roles.", "user_business_location_roles.")

    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT uq_user_store_roles "
        "TO uq_user_business_location_roles"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_user_store_roles_business_role_id "
        "TO fk_ublr_business_role_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_user_store_roles_store_id "
        "TO fk_ublr_store_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_user_store_roles_business_id "
        "TO fk_ublr_business_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT fk_user_store_roles_user_id "
        "TO fk_ublr_user_id"
    )
    op.execute(
        "ALTER TABLE user_store_roles RENAME CONSTRAINT "
        "user_store_roles_pkey TO user_business_location_roles_pkey"
    )
    op.execute("ALTER INDEX ix_user_store_roles_id RENAME TO ix_user_business_location_roles_id")
    op.rename_table("user_store_roles", "user_business_location_roles")
