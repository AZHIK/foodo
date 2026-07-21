from typing import TYPE_CHECKING, Optional
from uuid import UUID

from sqlalchemy import String
from sqlmodel import Field, Relationship, SQLModel

from app.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User


class Permission(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "permissions"

    code: str = Field(unique=True, max_length=100, sa_type=String)
    name: str = Field(max_length=100)
    description: str | None = Field(default=None, max_length=500)
    domain: str = Field(max_length=100)
    is_ai_sensitive: bool = Field(default=False)
    requires_human_approval: bool = Field(default=False)


class Group(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "groups"

    name: str = Field(unique=True, max_length=100)
    description: str | None = Field(default=None, max_length=500)

    roles: list["Role"] = Relationship(back_populates="group")
    user_group: Optional["UserGroup"] = Relationship(back_populates="group")


class Role(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "roles"

    group_id: UUID = Field(foreign_key="groups.id")
    name: str = Field(max_length=100)
    description: str | None = Field(default=None, max_length=500)

    group: Group = Relationship(back_populates="roles")
    permissions: list["RolePermission"] = Relationship(back_populates="role")
    user_roles: list["UserRole"] = Relationship(back_populates="role")


class RolePermission(SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "role_permissions"

    role_id: UUID = Field(foreign_key="roles.id", primary_key=True)
    permission_code: str = Field(primary_key=True, max_length=100, sa_type=String)

    role: Role = Relationship(back_populates="permissions")


class UserGroup(SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "user_group"

    user_id: UUID = Field(foreign_key="users.id", primary_key=True)
    group_id: UUID = Field(foreign_key="groups.id", primary_key=True)

    user: "User" = Relationship(back_populates="user_group")
    group: Group = Relationship(back_populates="user_group")


class UserRole(SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "user_roles"

    user_id: UUID = Field(foreign_key="users.id", primary_key=True)
    role_id: UUID = Field(foreign_key="roles.id", primary_key=True)

    user: "User" = Relationship(back_populates="user_roles")
    role: Role = Relationship(back_populates="user_roles")
