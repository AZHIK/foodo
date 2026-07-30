"""Base mixins for SQLModel table models.

SQLModel-compatible mixins that add common columns (UUID PK,
timestamps) without conflicting with the metaclass.
"""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlmodel import Field


class UUIDMixin:
    """Auto-generated UUID primary key."""

    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        index=True,
        nullable=False,
        sa_type=PG_UUID,
    )


class TimestampMixin:
    """created_at / updated_at with server-side defaults."""

    created_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"server_default": func.now()},  # type: ignore[call-overload]
        nullable=False,
    )
    updated_at: datetime = Field(
        default_factory=lambda: datetime.now(UTC),
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={  # type: ignore[call-overload]
            "server_default": func.now(),
            "onupdate": func.now(),
        },
        nullable=False,
    )


class SoftDeleteMixin:
    """Adds soft-delete support with is_deleted flag and deleted_at timestamp.

    Usage::

        class MyModel(SoftDeleteMixin, SQLModel, table=True):
            ...

    Call ``instance.soft_delete()`` to mark as deleted and
    ``instance.restore()`` to undo.
    """

    deleted_at: datetime | None = Field(  # type: ignore[call-overload]
        default=None,
        sa_type=DateTime(timezone=True),
        sa_column_kwargs={"nullable": True},
    )
    is_deleted: bool = Field(default=False, nullable=False)

    def soft_delete(self) -> None:
        """Mark this record as soft-deleted."""
        self.deleted_at = datetime.now(UTC)
        self.is_deleted = True

    def restore(self) -> None:
        """Restore a soft-deleted record."""
        self.deleted_at = None
        self.is_deleted = False
