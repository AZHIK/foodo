"""Platform-staff authentication endpoints.

Covers registration (admin-protected), login, and a placeholder MFA
verification endpoint.
"""

from typing import Any

import structlog
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import (
    RATE_LIMIT_PLATFORM_LOGIN_EMAIL_LIMIT,
    RATE_LIMIT_PLATFORM_LOGIN_EMAIL_WINDOW,
    RATE_LIMIT_PLATFORM_LOGIN_IP_LIMIT,
    RATE_LIMIT_PLATFORM_LOGIN_IP_WINDOW,
)
from app.core.database import get_async_session
from app.core.rate_limit import RateLimitDependency, body_field_source
from app.core.security import create_access_token, hash_password, verify_password
from app.deps.auth import require_role
from app.deps.permissions import require_platform_staff
from app.models.internal import Group, Role, RolePermission, UserGroup
from app.models.user import User, UserCategory, UserStatus
from app.schemas.auth import (
    PlatformStaffLoginRequest,
    PlatformStaffRegisterRequest,
    PlatformStaffVerifyMFARequest,
    TokenResponse,
)
from app.services.session_service import issue_login_session

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/api/v1/auth/platform", tags=["Platform Auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_platform_staff(
    body: PlatformStaffRegisterRequest,
    request: Request,
    # NOTE: Two guards are stacked here intentionally:
    #   1. require_platform_staff() — category gate: business_user tokens
    #      (even if they somehow carry role="admin") cannot reach this endpoint.
    #   2. require_role("admin") — role gate: platform staff must additionally
    #      hold the "admin" role within their group.
    # Self-serve internal-staff signup is unusual — platform staff accounts
    # should be created by an existing admin. If a future requirement allows
    # self-registration for certain staff tiers, add a separate endpoint or
    # remove this dependency and add an invite-based flow.
    _staff_claims: dict[str, Any] = Depends(require_platform_staff()),
    _admin_claims: dict[str, Any] = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_async_session),
) -> TokenResponse:
    async with db.begin():
        existing = await db.exec(select(User).where(User.email == body.email))
        if existing.one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )

        password_hash = hash_password(body.password)

        user = User(
            phone="",
            email=body.email,
            full_name=body.full_name,
            user_category=UserCategory.PLATFORM_STAFF,
            status=UserStatus.ACTIVE,
            password_hash=password_hash,
            is_email_verified=True,
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)

        group = await db.get(Group, body.group_id)
        if group:
            user_group = UserGroup(user_id=user.id, group_id=group.id)
            db.add(user_group)

    user_id_str = str(user.id)

    async with db.begin():
        group_roles = await db.exec(select(Role).where(Role.group_id == body.group_id))
        roles_list = [r.name for r in group_roles.all()]

        all_permissions = []
        for role in await db.exec(select(Role).where(Role.group_id == body.group_id)):
            role_perms = await db.exec(
                select(RolePermission).where(RolePermission.role_id == role.id)
            )
            for rp in role_perms.all():
                all_permissions.append(rp.permission_code)
        all_permissions = list(set(all_permissions))

    access_token = create_access_token(
        subject=user_id_str,
        user_category=UserCategory.PLATFORM_STAFF.value,
        group=group.name if group else "",
        roles=roles_list,
        permissions=all_permissions,
    )

    device_info = request.headers.get("user-agent")
    ip_address = request.client.host if request.client else None
    issued = await issue_login_session(
        db,
        user_id=user.id,
        device_info=device_info,
        ip_address=ip_address,
    )

    return TokenResponse(access_token=access_token, refresh_token=issued.raw_token)


@router.post(
    "/login",
    response_model=TokenResponse,
    dependencies=[
        Depends(
            RateLimitDependency(
                "platform_login_email",
                RATE_LIMIT_PLATFORM_LOGIN_EMAIL_LIMIT,
                RATE_LIMIT_PLATFORM_LOGIN_EMAIL_WINDOW,
                body_field_source("email"),
            )
        ),
        Depends(
            RateLimitDependency(
                "platform_login_ip",
                RATE_LIMIT_PLATFORM_LOGIN_IP_LIMIT,
                RATE_LIMIT_PLATFORM_LOGIN_IP_WINDOW,
                "ip",
            )
        ),
    ],
)
async def login_platform_staff(
    body: PlatformStaffLoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_async_session),
) -> TokenResponse:
    async with db.begin():
        result = await db.exec(
            select(User).where(
                User.email == body.email,
                User.user_category == UserCategory.PLATFORM_STAFF,
            )
        )
        user = result.one_or_none()

    if (
        user is None
        or user.password_hash is None
        or not verify_password(body.password, user.password_hash)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    group_name = ""
    roles_list: list[str] = []
    all_permissions: list[str] = []

    async with db.begin():
        ug_result = await db.exec(select(UserGroup).where(UserGroup.user_id == user.id))
        user_group = ug_result.one_or_none()

        if user_group:
            group = await db.get(Group, user_group.group_id)
            if group:
                group_name = group.name
                roles_result = await db.exec(select(Role).where(Role.group_id == group.id))
                for role in roles_result.all():
                    roles_list.append(role.name)
                    role_perms = await db.exec(
                        select(RolePermission).where(RolePermission.role_id == role.id)
                    )
                    for rp in role_perms.all():
                        all_permissions.append(rp.permission_code)
                all_permissions = list(set(all_permissions))

    user_id_str = str(user.id)
    access_token = create_access_token(
        subject=user_id_str,
        user_category=UserCategory.PLATFORM_STAFF.value,
        group=group_name,
        roles=roles_list,
        permissions=all_permissions,
    )

    device_info = request.headers.get("user-agent")
    ip_address = request.client.host if request.client else None
    issued = await issue_login_session(
        db,
        user_id=user.id,
        device_info=device_info,
        ip_address=ip_address,
    )

    return TokenResponse(access_token=access_token, refresh_token=issued.raw_token)


@router.post("/mfa/verify", status_code=status.HTTP_501_NOT_IMPLEMENTED)
async def verify_mfa_platform_staff(
    _body: PlatformStaffVerifyMFARequest,
) -> dict[str, Any]:
    """Placeholder: MFA verification for platform staff is not yet implemented."""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="MFA is not yet implemented for platform staff",
    )
