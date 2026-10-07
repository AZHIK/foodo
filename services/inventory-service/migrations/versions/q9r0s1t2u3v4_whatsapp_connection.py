"""WhatsApp Business Cloud API connection + message tracking columns.

Revision ID: q9r0s1t2u3v4
Revises: p8q9r0s1t2u3
Create Date: 2026-10-06 00:00:00.000000

Additive:
* NEW ``whatsappconnection`` table (+ native enum
  ``whatsappconnectionstatus``): one row per business holding the Cloud API
  sender credentials (phone_number_id, display number, access token,
  webhook verify token, live status).
* ``suppliermessage`` gains ``provider_message_id`` (Cloud API ``wamid`` —
  joins status webhooks back to the row) + ``last_error`` (provider
  rejection detail); ``po_id`` becomes nullable so unmatched inbound
  supplier replies can be stored; ``messagestatus`` gains ``received``
  (inbound rows).
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "q9r0s1t2u3v4"
down_revision: Union[str, None] = "p8q9r0s1t2u3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "CREATE TYPE whatsappconnectionstatus AS ENUM "
        "('disconnected', 'connected', 'error')"
    )
    op.execute("ALTER TYPE messagestatus ADD VALUE IF NOT EXISTS 'received'")

    op.create_table(
        "whatsappconnection",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("business_id", sa.Uuid(), nullable=False),
        sa.Column("phone_number_id", sa.String(64), nullable=False),
        sa.Column("display_phone_number", sa.String(64), nullable=True),
        sa.Column("access_token", sa.String(1024), nullable=False),
        sa.Column("verify_token", sa.String(128), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM(
                "disconnected",
                "connected",
                "error",
                name="whatsappconnectionstatus",
                create_type=False,
            ),
            nullable=False,
        ),
        sa.Column("last_error", sa.String(1000), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("last_checked_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("business_id", name="uq_whatsappconnection_business_id"),
    )
    op.create_index(
        op.f("ix_whatsappconnection_business_id"), "whatsappconnection", ["business_id"]
    )

    op.add_column(
        "suppliermessage",
        sa.Column("provider_message_id", sa.String(255), nullable=True),
    )
    op.add_column(
        "suppliermessage",
        sa.Column("last_error", sa.String(1000), nullable=True),
    )
    op.alter_column("suppliermessage", "po_id", existing_type=sa.Uuid(), nullable=True)
    op.create_index(
        op.f("ix_suppliermessage_provider_message_id"),
        "suppliermessage",
        ["provider_message_id"],
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_suppliermessage_provider_message_id"), table_name="suppliermessage"
    )
    op.alter_column("suppliermessage", "po_id", existing_type=sa.Uuid(), nullable=False)
    op.drop_column("suppliermessage", "last_error")
    op.drop_column("suppliermessage", "provider_message_id")
    op.drop_index(op.f("ix_whatsappconnection_business_id"), table_name="whatsappconnection")
    op.drop_table("whatsappconnection")
    op.execute("DROP TYPE IF EXISTS whatsappconnectionstatus")
    # NOTE: Postgres cannot drop enum VALUES; the added ``received``
    # messagestatus value intentionally persists on downgrade.
