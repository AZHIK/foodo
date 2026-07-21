from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import UniqueConstraint
from sqlmodel import Field, Relationship, SQLModel

from app.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User


class PlatformRole(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "platform_roles"

    name: str = Field(unique=True, max_length=100)

    user_platform_roles: list["UserPlatformRole"] = Relationship(back_populates="platform_role")


class UserPlatformRole(UUIDMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "user_platform_roles"

    user_id: UUID = Field(foreign_key="users.id")
    platform_role_id: UUID = Field(foreign_key="platform_roles.id")

    __table_args__ = (UniqueConstraint("user_id", "platform_role_id"),)

    user: "User" = Relationship(back_populates="user_platform_roles")
    platform_role: PlatformRole = Relationship(back_populates="user_platform_roles")
