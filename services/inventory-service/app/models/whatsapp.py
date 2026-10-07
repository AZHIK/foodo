"""WhatsApp Business connection — per-business Cloud API credentials.

One row per business holds the credentials needed to SEND purchase orders
through the WhatsApp Business Cloud API (Meta Graph API) instead of the
manual ``wa.me`` deep link:

* ``phone_number_id`` — the sender ID from the Meta dashboard (the
  ``.../messages`` endpoint is addressed to this ID).
* ``display_phone_number`` — the human-readable business number (for the UI).
* ``access_token`` — long-lived system-user token. Stored plaintext in this
  pass (same MVP tradeoff as ``internal_service_token`` in Settings); move
  to a KMS/secret manager before multi-tenant prod.
* ``verify_token`` — server-generated secret the operator pastes into the
  Meta dashboard's webhook configuration. Inbound webhook calls prove they
  target this business with ``?business_id=…&t=<verify_token>`` (plus the
  optional ``X-Hub-Signature-256`` app-secret check).
* ``status`` — ``connected`` (last live check or send succeeded),
  ``error`` (last check/send failed; see ``last_error``), ``disconnected``
  (credentials cleared).

Outbound delivery itself is tracked on ``SupplierMessage`` (provider
``wamid`` in ``provider_message_id``, failure detail in ``last_error``).
"""

from __future__ import annotations

from datetime import UTC, datetime
from enum import Enum as PyEnum
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, UniqueConstraint, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Field, SQLModel


def _enum_db_values(enum_class: type[PyEnum]) -> list[str]:
    return [member.value for member in enum_class]


class WhatsAppConnectionStatus(str, PyEnum):
    DISCONNECTED = "disconnected"
    CONNECTED = "connected"
    ERROR = "error"


class WhatsAppConnection(SQLModel, table=True):
    """Cloud API credentials for one business (at most one live row)."""

    id: UUID = Field(default_factory=uuid4, primary_key=True, nullable=False, sa_type=PG_UUID)
    business_id: UUID = Field(nullable=False, index=True, sa_type=PG_UUID)
    phone_number_id: str = Field(nullable=False, max_length=64)
    display_phone_number: str | None = Field(default=None, max_length=64)
    access_token: str = Field(nullable=False, max_length=1024)
    verify_token: str = Field(nullable=False, max_length=128)
    status: WhatsAppConnectionStatus = Field(
        default=WhatsAppConnectionStatus.DISCONNECTED,
        sa_column=Column(
            SAEnum(
                WhatsAppConnectionStatus,
                values_callable=_enum_db_values,
                name="whatsappconnectionstatus",
            ),
            nullable=False,
        ),
    )
    last_error: str | None = Field(default=None, max_length=1000)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},
        nullable=False,
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now(), "onupdate": func.now()},
        nullable=False,
    )
    last_checked_at: datetime | None = Field(default=None, sa_type=DateTime(timezone=True))

    __table_args__ = (
        UniqueConstraint("business_id", name="uq_whatsappconnection_business_id"),
    )
