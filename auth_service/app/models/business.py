from enum import StrEnum
from typing import TYPE_CHECKING, Optional
from uuid import UUID

from sqlalchemy import String, UniqueConstraint
from sqlmodel import Field, Relationship, SQLModel

from app.models.base import SoftDeleteMixin, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User


class PermissionType(StrEnum):
    GRANT = "grant"
    DENY = "deny"


class BusinessType(StrEnum):
    RESTAURANT = "restaurant"
    SUPPLIER = "supplier"
    FARMER = "farmer"
    DISTRIBUTOR = "distributor"
    PLATFORM_OPERATOR = "platform_operator"


class LocationType(StrEnum):
    HEAD_OFFICE = "head_office"
    RESTAURANT_BRANCH = "restaurant_branch"
    KITCHEN = "kitchen"
    WAREHOUSE = "warehouse"
    FARM = "farm"
    DEPOT = "depot"


class Organization(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "organizations"

    name: str = Field(max_length=255)
    legal_name: str | None = Field(default=None, max_length=255)
    country_code: str = Field(default="TZ", max_length=2)
    default_timezone: str = Field(default="Africa/Dar_es_Salaam", max_length=64)
    owner_user_id: UUID = Field(foreign_key="users.id")

    businesses: list["Business"] = Relationship(back_populates="organization")


class Business(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "businesses"

    name: str = Field(max_length=255)
    business_type: BusinessType = Field(sa_type=String)
    owner_user_id: UUID = Field(foreign_key="users.id")
    organization_id: UUID | None = Field(
        default=None, foreign_key="organizations.id", nullable=True
    )
    tax_id: str | None = Field(default=None, max_length=100)
    country_code: str = Field(default="TZ", max_length=2)
    city: str | None = Field(default=None, max_length=100)
    timezone: str = Field(default="Africa/Dar_es_Salaam", max_length=64)

    organization: Organization | None = Relationship(back_populates="businesses")
    owner: "User" = Relationship(back_populates="businesses")
    locations: list["BusinessLocation"] = Relationship(back_populates="business")
    roles: list["BusinessRole"] = Relationship(back_populates="business")
    user_business_roles: list["UserBusinessRole"] = Relationship(back_populates="business")
    user_business_permissions: list["UserBusinessPermission"] = Relationship(
        back_populates="business"
    )


class BusinessRole(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "business_roles"

    business_id: UUID = Field(foreign_key="businesses.id")
    name: str = Field(max_length=100)
    description: str | None = Field(default=None, max_length=500)
    is_protected: bool = Field(default=False)

    business: Business = Relationship(back_populates="roles")
    permissions: list["BusinessRolePermission"] = Relationship(back_populates="business_role")
    user_assignments: list["UserBusinessRole"] = Relationship(back_populates="business_role")


class BusinessLocation(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "business_locations"

    business_id: UUID = Field(foreign_key="businesses.id")
    name: str = Field(max_length=255)
    location_type: LocationType = Field(sa_type=String)
    country_code: str = Field(default="TZ", max_length=2)
    city: str | None = Field(default=None, max_length=100)
    address: str | None = Field(default=None, max_length=500)
    timezone: str = Field(default="Africa/Dar_es_Salaam", max_length=64)
    is_primary: bool = Field(default=False)

    __table_args__ = (UniqueConstraint("business_id", "name"),)

    business: Business = Relationship(back_populates="locations")
    user_location_roles: list["UserBusinessLocationRole"] = Relationship(
        back_populates="business_location"
    )


class BusinessRolePermission(SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "business_role_permissions"

    business_role_id: UUID = Field(foreign_key="business_roles.id", primary_key=True)
    permission_code: str = Field(primary_key=True, max_length=100, sa_type=String)

    business_role: BusinessRole = Relationship(back_populates="permissions")


class UserBusinessRole(UUIDMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "user_business_roles"

    user_id: UUID = Field(foreign_key="users.id")
    business_id: UUID = Field(foreign_key="businesses.id")
    business_role_id: UUID = Field(foreign_key="business_roles.id")

    __table_args__ = (UniqueConstraint("user_id", "business_id", "business_role_id"),)

    user: "User" = Relationship(back_populates="user_business_roles")
    business: Business = Relationship(back_populates="user_business_roles")
    business_role: BusinessRole = Relationship(back_populates="user_assignments")


class UserBusinessLocationRole(UUIDMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "user_business_location_roles"

    user_id: UUID = Field(foreign_key="users.id")
    business_id: UUID = Field(foreign_key="businesses.id")
    business_location_id: UUID = Field(foreign_key="business_locations.id")
    business_role_id: UUID = Field(foreign_key="business_roles.id")

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "business_location_id",
            "business_role_id",
        ),
    )

    business_location: BusinessLocation = Relationship(back_populates="user_location_roles")


class UserBusinessPermission(UUIDMixin, TimestampMixin, SoftDeleteMixin, SQLModel, table=True):
    __tablename__ = "user_business_permissions"

    user_id: UUID = Field(foreign_key="users.id")
    business_id: UUID = Field(foreign_key="businesses.id")
    permission_code: str = Field(max_length=100, sa_type=String)
    type: PermissionType = Field(sa_type=String)
    created_by: UUID | None = Field(default=None, foreign_key="users.id", nullable=True)

    __table_args__ = (UniqueConstraint("user_id", "business_id", "permission_code"),)

    user: "User" = Relationship(
        back_populates="user_business_permissions",
        sa_relationship_kwargs={"foreign_keys": "UserBusinessPermission.user_id"},
    )
    created_by_user: Optional["User"] = Relationship(
        back_populates="created_business_permissions",
        sa_relationship_kwargs={"foreign_keys": "UserBusinessPermission.created_by"},
    )
    business: Business = Relationship(back_populates="user_business_permissions")
