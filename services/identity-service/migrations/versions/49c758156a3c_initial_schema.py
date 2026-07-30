"""initial_schema

Explicit ``op.create_table()`` revision that replaces the previous
``SQLModel.metadata.create_all()`` shortcut so Alembic has a real,
auditable migration history for every table.

Tables are ordered by dependency (no-FK tables first, then tables that
reference them).  Tables NOT created here:

* ``audit_logs`` — was created by the old create_all and then
  immediately dropped by revision ``5e4d74c8c2a1``; it is simply
  omitted from this revision.
* ``platform_role_permissions`` — added later by revision
  ``8f1e2d3c4b5a``.

Revision ID: 49c758156a3c
Revises:
Create Date: 2026-07-10 10:22:42.575364
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "49c758156a3c"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _uuuid() -> sa.UUID:
    return sa.UUID()


def _utcdt() -> sa.DateTime:
    return sa.DateTime(timezone=True)


# ---------------------------------------------------------------------------
# Upgrade
# ---------------------------------------------------------------------------


def upgrade() -> None:
    # ── 1. Tables with no foreign keys ──────────────────────────────────

    op.create_table(
        "users",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("phone", sa.String(20), nullable=False),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("user_category", sa.String(20), nullable=False),
        sa.Column("status", sa.String(20), server_default=sa.text("'active'"), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("is_phone_verified", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("is_email_verified", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.create_unique_constraint("uq_users_phone", "users", ["phone"])
    op.create_unique_constraint("uq_users_email", "users", ["email"])

    op.create_table(
        "permissions",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.String(500), nullable=True),
        sa.Column("domain", sa.String(100), nullable=False),
        sa.Column("is_ai_sensitive", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("requires_human_approval", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.create_unique_constraint("uq_permissions_code", "permissions", ["code"])

    op.create_table(
        "groups",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.String(500), nullable=True),
    )
    op.create_unique_constraint("uq_groups_name", "groups", ["name"])

    op.create_table(
        "platform_roles",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
    )
    op.create_unique_constraint("uq_platform_roles_name", "platform_roles", ["name"])

    op.create_table(
        "role_templates",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.String(500), nullable=True),
    )
    op.create_unique_constraint("uq_role_templates_name", "role_templates", ["name"])

    # ── 2. Tables that reference users / groups / roles / templates ──────

    op.create_table(
        "organizations",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("legal_name", sa.String(255), nullable=True),
        sa.Column("country_code", sa.String(2), server_default=sa.text("'TZ'"), nullable=False),
        sa.Column("default_timezone", sa.String(64), server_default=sa.text("'Africa/Dar_es_Salaam'"), nullable=False),
        sa.Column("owner_user_id", _uuuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_organizations_owner_user_id", "organizations", "users",
        ["owner_user_id"], ["id"], ondelete="RESTRICT",
    )

    op.create_table(
        "businesses",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("business_type", sa.String(20), nullable=False),
        sa.Column("owner_user_id", _uuuid(), nullable=False),
        sa.Column("organization_id", _uuuid(), nullable=True),
        sa.Column("tax_id", sa.String(100), nullable=True),
        sa.Column("country_code", sa.String(2), server_default=sa.text("'TZ'"), nullable=False),
        sa.Column("city", sa.String(100), nullable=True),
        sa.Column("timezone", sa.String(64), server_default=sa.text("'Africa/Dar_es_Salaam'"), nullable=False),
    )
    op.create_foreign_key(
        "fk_businesses_owner_user_id", "businesses", "users",
        ["owner_user_id"], ["id"], ondelete="RESTRICT",
    )
    op.create_foreign_key(
        "fk_businesses_organization_id", "businesses", "organizations",
        ["organization_id"], ["id"], ondelete="SET NULL",
    )
    op.create_index("ix_businesses_organization_id", "businesses", ["organization_id"])

    op.create_table(
        "roles",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("group_id", _uuuid(), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.String(500), nullable=True),
    )
    op.create_foreign_key(
        "fk_roles_group_id", "roles", "groups",
        ["group_id"], ["id"], ondelete="CASCADE",
    )
    op.create_index("ix_roles_group_id", "roles", ["group_id"])

    # ── 3. Junction / composite-PK tables ────────────────────────────────

    op.create_table(
        "role_permissions",
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("role_id", _uuuid(), nullable=False),
        sa.Column("permission_code", sa.String(100), nullable=False),
    )
    op.create_foreign_key(
        "fk_role_permissions_role_id", "role_permissions", "roles",
        ["role_id"], ["id"], ondelete="CASCADE",
    )
    op.create_primary_key("pk_role_permissions", "role_permissions", ["role_id", "permission_code"])

    op.create_table(
        "user_group",
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("group_id", _uuuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_user_group_user_id", "user_group", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_user_group_group_id", "user_group", "groups",
        ["group_id"], ["id"], ondelete="CASCADE",
    )
    op.create_primary_key("pk_user_group", "user_group", ["user_id", "group_id"])

    op.create_table(
        "user_roles",
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("role_id", _uuuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_user_roles_user_id", "user_roles", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_user_roles_role_id", "user_roles", "roles",
        ["role_id"], ["id"], ondelete="CASCADE",
    )
    op.create_primary_key("pk_user_roles", "user_roles", ["user_id", "role_id"])

    op.create_table(
        "user_platform_roles",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("platform_role_id", _uuuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_user_platform_roles_user_id", "user_platform_roles", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_user_platform_roles_platform_role_id", "user_platform_roles", "platform_roles",
        ["platform_role_id"], ["id"], ondelete="RESTRICT",
    )
    op.create_unique_constraint(
        "uq_user_platform_roles", "user_platform_roles", ["user_id", "platform_role_id"],
    )

    op.create_table(
        "role_template_permissions",
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("role_template_id", _uuuid(), nullable=False),
        sa.Column("permission_code", sa.String(100), nullable=False),
    )
    op.create_foreign_key(
        "fk_role_template_permissions_template_id", "role_template_permissions", "role_templates",
        ["role_template_id"], ["id"], ondelete="CASCADE",
    )
    op.create_primary_key(
        "pk_role_template_permissions", "role_template_permissions",
        ["role_template_id", "permission_code"],
    )

    # ── 4. Business-scoped tables ────────────────────────────────────────

    op.create_table(
        "business_roles",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("business_id", _uuuid(), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.String(500), nullable=True),
        sa.Column("is_protected", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.create_foreign_key(
        "fk_business_roles_business_id", "business_roles", "businesses",
        ["business_id"], ["id"], ondelete="CASCADE",
    )
    op.create_index("ix_business_roles_business_id", "business_roles", ["business_id"])

    op.create_table(
        "business_locations",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("business_id", _uuuid(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("location_type", sa.String(20), nullable=False),
        sa.Column("country_code", sa.String(2), server_default=sa.text("'TZ'"), nullable=False),
        sa.Column("city", sa.String(100), nullable=True),
        sa.Column("address", sa.String(500), nullable=True),
        sa.Column("timezone", sa.String(64), server_default=sa.text("'Africa/Dar_es_Salaam'"), nullable=False),
        sa.Column("is_primary", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.create_foreign_key(
        "fk_business_locations_business_id", "business_locations", "businesses",
        ["business_id"], ["id"], ondelete="CASCADE",
    )
    op.create_unique_constraint(
        "uq_business_locations_business_id_name", "business_locations", ["business_id", "name"],
    )
    op.create_index("ix_business_locations_business_id", "business_locations", ["business_id"])

    op.create_table(
        "business_role_permissions",
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("business_role_id", _uuuid(), nullable=False),
        sa.Column("permission_code", sa.String(100), nullable=False),
    )
    op.create_foreign_key(
        "fk_business_role_permissions_role_id", "business_role_permissions", "business_roles",
        ["business_role_id"], ["id"], ondelete="CASCADE",
    )
    op.create_primary_key(
        "pk_business_role_permissions", "business_role_permissions",
        ["business_role_id", "permission_code"],
    )

    op.create_table(
        "user_business_roles",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("business_id", _uuuid(), nullable=False),
        sa.Column("business_role_id", _uuuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_user_business_roles_user_id", "user_business_roles", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_user_business_roles_business_id", "user_business_roles", "businesses",
        ["business_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_user_business_roles_business_role_id", "user_business_roles", "business_roles",
        ["business_role_id"], ["id"], ondelete="RESTRICT",
    )
    op.create_unique_constraint(
        "uq_user_business_roles", "user_business_roles",
        ["user_id", "business_id", "business_role_id"],
    )

    op.create_table(
        "user_business_location_roles",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("business_id", _uuuid(), nullable=False),
        sa.Column("business_location_id", _uuuid(), nullable=False),
        sa.Column("business_role_id", _uuuid(), nullable=False),
    )
    op.create_foreign_key(
        "fk_ublr_user_id", "user_business_location_roles", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_ublr_business_id", "user_business_location_roles", "businesses",
        ["business_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_ublr_business_location_id", "user_business_location_roles", "business_locations",
        ["business_location_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_ublr_business_role_id", "user_business_location_roles", "business_roles",
        ["business_role_id"], ["id"], ondelete="RESTRICT",
    )
    op.create_unique_constraint(
        "uq_user_business_location_roles", "user_business_location_roles",
        ["user_id", "business_location_id", "business_role_id"],
    )

    op.create_table(
        "user_business_permissions",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("business_id", _uuuid(), nullable=False),
        sa.Column("permission_code", sa.String(100), nullable=False),
        sa.Column("type", sa.String(5), nullable=False),
        sa.Column("created_by", _uuuid(), nullable=True),
    )
    op.create_foreign_key(
        "fk_ubp_user_id", "user_business_permissions", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_ubp_business_id", "user_business_permissions", "businesses",
        ["business_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_ubp_created_by", "user_business_permissions", "users",
        ["created_by"], ["id"], ondelete="SET NULL",
    )
    op.create_unique_constraint(
        "uq_user_business_permissions", "user_business_permissions",
        ["user_id", "business_id", "permission_code"],
    )

    # ── 5. Auth / security tables (reference users) ──────────────────────

    op.create_table(
        "verification_codes",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("code_hash", sa.String(255), nullable=False),
        sa.Column("type", sa.String(10), nullable=False),
        sa.Column("purpose", sa.String(20), nullable=False),
        sa.Column("expires_at", _utcdt(), nullable=False),
        sa.Column("used_at", _utcdt(), nullable=True),
        sa.Column("attempts", sa.Integer(), server_default=sa.text("0"), nullable=False),
    )
    op.create_foreign_key(
        "fk_verification_codes_user_id", "verification_codes", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_index("ix_verification_codes_user_id", "verification_codes", ["user_id"])

    op.create_table(
        "refresh_tokens",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("token_hash", sa.String(255), nullable=False),
        sa.Column("device_info", sa.String(500), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("expires_at", _utcdt(), nullable=False),
        sa.Column("revoked_at", _utcdt(), nullable=True),
    )
    op.create_foreign_key(
        "fk_refresh_tokens_user_id", "refresh_tokens", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_unique_constraint("uq_refresh_tokens_token_hash", "refresh_tokens", ["token_hash"])
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])

    op.create_table(
        "user_sessions",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("refresh_token_id", _uuuid(), nullable=True),
        sa.Column("device_info", sa.String(500), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("last_activity_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("expires_at", _utcdt(), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
    )
    op.create_foreign_key(
        "fk_user_sessions_user_id", "user_sessions", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_user_sessions_refresh_token_id", "user_sessions", "refresh_tokens",
        ["refresh_token_id"], ["id"], ondelete="SET NULL",
    )
    op.create_index("ix_user_sessions_user_id", "user_sessions", ["user_id"])
    op.create_index("ix_user_sessions_refresh_token_id", "user_sessions", ["refresh_token_id"])

    op.create_table(
        "trusted_devices",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", _utcdt(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=False),
        sa.Column("device_fingerprint_hash", sa.String(255), nullable=False),
        sa.Column("device_name", sa.String(255), nullable=True),
        sa.Column("platform", sa.String(100), nullable=True),
        sa.Column("last_ip_address", sa.String(45), nullable=True),
        sa.Column("last_seen_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("revoked_at", _utcdt(), nullable=True),
    )
    op.create_foreign_key(
        "fk_trusted_devices_user_id", "trusted_devices", "users",
        ["user_id"], ["id"], ondelete="CASCADE",
    )
    op.create_unique_constraint(
        "uq_trusted_devices_user_id_device", "trusted_devices",
        ["user_id", "device_fingerprint_hash"],
    )
    op.create_index("ix_trusted_devices_user_id", "trusted_devices", ["user_id"])

    # tables without soft-delete

    op.create_table(
        "login_attempts",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=True),
        sa.Column("identifier", sa.String(255), nullable=False),
        sa.Column("success", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("failure_reason", sa.String(255), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("device_fingerprint_hash", sa.String(255), nullable=True),
        sa.Column("user_agent", sa.String(500), nullable=True),
    )
    op.create_foreign_key(
        "fk_login_attempts_user_id", "login_attempts", "users",
        ["user_id"], ["id"], ondelete="SET NULL",
    )

    op.create_table(
        "auth_risk_events",
        sa.Column("id", _uuuid(), primary_key=True, nullable=False, index=True),
        sa.Column("created_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", _utcdt(), server_default=sa.func.now(), nullable=False),
        sa.Column("user_id", _uuuid(), nullable=True),
        sa.Column("session_id", _uuuid(), nullable=True),
        sa.Column("event_type", sa.String(20), nullable=False),
        sa.Column("risk_level", sa.String(10), nullable=False),
        sa.Column("reason", sa.String(500), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("device_fingerprint_hash", sa.String(255), nullable=True),
    )
    op.create_foreign_key(
        "fk_auth_risk_events_user_id", "auth_risk_events", "users",
        ["user_id"], ["id"], ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_auth_risk_events_session_id", "auth_risk_events", "user_sessions",
        ["session_id"], ["id"], ondelete="SET NULL",
    )


# ---------------------------------------------------------------------------
# Downgrade
# ---------------------------------------------------------------------------


def downgrade() -> None:
    # Reverse order: drop dependent tables first.
    op.drop_table("auth_risk_events")
    op.drop_table("login_attempts")
    op.drop_table("trusted_devices")
    op.drop_table("user_sessions")
    op.drop_table("refresh_tokens")
    op.drop_table("verification_codes")
    op.drop_table("user_business_permissions")
    op.drop_table("user_business_location_roles")
    op.drop_table("user_business_roles")
    op.drop_table("business_role_permissions")
    op.drop_table("business_locations")
    op.drop_table("business_roles")
    op.drop_table("role_template_permissions")
    op.drop_table("user_platform_roles")
    op.drop_table("user_roles")
    op.drop_table("user_group")
    op.drop_table("role_permissions")
    op.drop_table("roles")
    op.drop_table("businesses")
    op.drop_table("organizations")
    op.drop_table("role_templates")
    op.drop_table("platform_roles")
    op.drop_table("groups")
    op.drop_table("permissions")
    op.drop_table("users")
