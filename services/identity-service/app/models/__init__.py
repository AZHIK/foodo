"""SQLModel table=True models (DB-backed).

Each model defined here inherits from SQLModel and has table=True,
meaning it maps to a Postgres table.

Import all models here so SQLModel.metadata is complete for Alembic.
"""

__all__ = [
    "AuthEventType",
    "AuthRiskEvent",
    "AuthRiskLevel",
    "Business",
    "BusinessRole",
    "BusinessRolePermission",
    "BusinessStatus",
    "BusinessType",
    "Group",
    "LocationType",
    "LoginAttempt",
    "Organization",
    "Permission",
    "PermissionType",
    "PlatformRole",
    "PlatformRolePermission",
    "RefreshToken",
    "Role",
    "RolePermission",
    "RoleTemplate",
    "RoleTemplatePermission",
    "Store",
    "StoreSetting",
    "User",
    "UserBusinessPermission",
    "UserBusinessLocationRole",
    "UserBusinessRole",
    "UserCategory",
    "UserGroup",
    "UserPlatformRole",
    "UserRole",
    "UserSession",
    "VerificationCode",
    "VerificationCodePurpose",
    "VerificationCodeType",
    "TrustedDevice",
    "UserStatus",
]

from app.models.auth import (
    AuthEventType,
    AuthRiskEvent,
    AuthRiskLevel,
    LoginAttempt,
    RefreshToken,
    TrustedDevice,
    UserSession,
    VerificationCode,
    VerificationCodePurpose,
    VerificationCodeType,
)
from app.models.business import (
    Business,
    BusinessRole,
    BusinessRolePermission,
    BusinessStatus,
    BusinessType,
    LocationType,
    Organization,
    PermissionType,
    Store,
    StoreSetting,
    UserBusinessLocationRole,
    UserBusinessPermission,
    UserBusinessRole,
)
from app.models.internal import (
    Group,
    Permission,
    Role,
    RolePermission,
    UserGroup,
    UserRole,
)
from app.models.platform import PlatformRole, PlatformRolePermission, UserPlatformRole
from app.models.template import RoleTemplate, RoleTemplatePermission
from app.models.user import User, UserCategory, UserStatus
