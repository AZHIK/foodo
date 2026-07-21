from uuid import UUID

from sqlalchemy import String
from sqlmodel import Field, Relationship, SQLModel

from app.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin


class RoleTemplate(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "role_templates"

    name: str = Field(unique=True, max_length=100)
    description: str | None = Field(default=None, max_length=500)

    permissions: list["RoleTemplatePermission"] = Relationship(back_populates="role_template")


class RoleTemplatePermission(SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "role_template_permissions"

    role_template_id: UUID = Field(foreign_key="role_templates.id", primary_key=True)
    permission_code: str = Field(primary_key=True, max_length=100, sa_type=String)

    role_template: RoleTemplate = Relationship(back_populates="permissions")
