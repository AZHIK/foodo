"""Business-scoped RBAC management endpoints.

Business owners (or anyone with the right business permission) can manage
custom roles, assign permissions to those roles, and assign/revoke staff
members.  All endpoints require an ``active_business_id`` in the JWT
(obtained via ``POST /auth/context/switch``) and the appropriate
permission code.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_async_session
from app.core.permission_codes import PermissionCode, coerce_permission_code
from app.deps.permissions import require_business_permission
from app.models.business import (
    Business,
    BusinessRole,
    BusinessRolePermission,
    UserBusinessLocationRole,
    UserBusinessRole,
)
from app.models.user import User, UserCategory, UserStatus
from app.schemas.business_rbac import (
    AddRolePermissionRequest,
    AssignStaffRequest,
    BusinessRoleCreateRequest,
    BusinessRoleRead,
    BusinessRoleUpdateRequest,
)

router = APIRouter(prefix="/api/v1/businesses", tags=["Business RBAC"])


# ── Helpers ──────────────────────────────────────────────────────────────────


async def _get_business_or_404(db: AsyncSession, business_id: UUID) -> Business:
    biz = await db.get(Business, business_id)
    if biz is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    return biz


async def _get_business_role_or_404(
    db: AsyncSession, business_id: UUID, role_id: UUID
) -> BusinessRole:
    role = await db.get(BusinessRole, role_id)
    if role is None or role.business_id != business_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business role not found")
    return role


# ── 1. Create Business Role ──────────────────────────────────────────────────


@router.post(
    "/{business_id}/roles",
    response_model=BusinessRoleRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_business_role(
    business_id: UUID,
    body: BusinessRoleCreateRequest,
    _biz_id: str = Depends(require_business_permission(PermissionCode.BUSINESS_ROLES_CREATE)),
    db: AsyncSession = Depends(get_async_session),
) -> BusinessRole:
    async with db.begin():
        await _get_business_or_404(db, business_id)

        existing = (
            await db.exec(
                select(BusinessRole).where(
                    BusinessRole.business_id == business_id,
                    BusinessRole.name == body.name,
                )
            )
        ).one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"A role named '{body.name}' already exists for this business",
            )

        role = BusinessRole(
            business_id=business_id,
            name=body.name,
            description=body.description,
            is_protected=False,
        )
        db.add(role)
    await db.refresh(role)
    return role


# ── 2. Update Business Role ──────────────────────────────────────────────────


@router.patch(
    "/{business_id}/roles/{role_id}",
    response_model=BusinessRoleRead,
)
async def update_business_role(
    business_id: UUID,
    role_id: UUID,
    body: BusinessRoleUpdateRequest,
    _biz_id: str = Depends(require_business_permission(PermissionCode.BUSINESS_ROLES_UPDATE)),
    db: AsyncSession = Depends(get_async_session),
) -> BusinessRole:
    async with db.begin():
        role = await _get_business_role_or_404(db, business_id, role_id)

        if role.is_protected:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Protected roles cannot be modified",
            )

        if body.name is not None:
            existing = (
                await db.exec(
                    select(BusinessRole).where(
                        BusinessRole.business_id == business_id,
                        BusinessRole.name == body.name,
                        BusinessRole.id != role_id,
                    )
                )
            ).one_or_none()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"A role named '{body.name}' already exists for this business",
                )
            role.name = body.name

        if body.description is not None:
            role.description = body.description

        db.add(role)
    await db.refresh(role)
    return role


# ── 3. Delete Business Role ──────────────────────────────────────────────────


@router.delete(
    "/{business_id}/roles/{role_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_business_role(
    business_id: UUID,
    role_id: UUID,
    _biz_id: str = Depends(require_business_permission(PermissionCode.BUSINESS_ROLES_DELETE)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        role = await _get_business_role_or_404(db, business_id, role_id)

        if role.is_protected:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Protected roles cannot be deleted",
            )

        active_user_roles = (
            await db.exec(
                select(UserBusinessRole).where(UserBusinessRole.business_role_id == role_id)
            )
        ).all()
        if active_user_roles:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "Cannot delete role with active user assignments. "
                    "Remove all staff assignments first."
                ),
            )

        active_location_roles = (
            await db.exec(
                select(UserBusinessLocationRole).where(
                    UserBusinessLocationRole.business_role_id == role_id
                )
            )
        ).all()
        if active_location_roles:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "Cannot delete role with active location-level user assignments. "
                    "Remove all location-based assignments first."
                ),
            )

        await db.delete(role)


# ── 4. Assign Permission to Role ─────────────────────────────────────────────


@router.post(
    "/{business_id}/roles/{role_id}/permissions",
    status_code=status.HTTP_201_CREATED,
)
async def assign_role_permission(
    business_id: UUID,
    role_id: UUID,
    body: AddRolePermissionRequest,
    _biz_id: str = Depends(
        require_business_permission(PermissionCode.BUSINESS_ROLES_MANAGE_PERMISSIONS)
    ),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        await _get_business_role_or_404(db, business_id, role_id)

        try:
            validated_code = coerce_permission_code(body.permission_code)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail=f"Invalid permission code: {body.permission_code}",
            ) from None

        existing = (
            await db.exec(
                select(BusinessRolePermission).where(
                    BusinessRolePermission.business_role_id == role_id,
                    BusinessRolePermission.permission_code == str(validated_code),
                )
            )
        ).one_or_none()
        if existing:
            return {"detail": "Permission already assigned to role"}

        rp = BusinessRolePermission(
            business_role_id=role_id,
            permission_code=str(validated_code),
        )
        db.add(rp)

    return {"detail": "Permission assigned to role"}


# ── 5. Remove Permission from Role ───────────────────────────────────────────


@router.delete(
    "/{business_id}/roles/{role_id}/permissions/{permission_code}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_role_permission(
    business_id: UUID,
    role_id: UUID,
    permission_code: str,
    _biz_id: str = Depends(
        require_business_permission(PermissionCode.BUSINESS_ROLES_MANAGE_PERMISSIONS)
    ),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        await _get_business_role_or_404(db, business_id, role_id)

        rp = (
            await db.exec(
                select(BusinessRolePermission).where(
                    BusinessRolePermission.business_role_id == role_id,
                    BusinessRolePermission.permission_code == permission_code,
                )
            )
        ).one_or_none()
        if rp is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not assigned to role",
            )

        await db.delete(rp)


# ── 6. Assign Staff to Role ──────────────────────────────────────────────────


@router.post(
    "/{business_id}/staff",
    status_code=status.HTTP_201_CREATED,
)
async def assign_staff_role(
    business_id: UUID,
    body: AssignStaffRequest,
    _biz_id: str = Depends(require_business_permission(PermissionCode.USER_BUSINESS_ROLES_ASSIGN)),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        await _get_business_or_404(db, business_id)

        target_user: User | None = None
        if body.user_id is not None:
            target_user = await db.get(User, body.user_id)
        elif body.phone is not None:
            result = await db.exec(select(User).where(User.phone == body.phone))
            target_user = result.one_or_none()
        else:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Either 'user_id' or 'phone' must be provided",
            )

        if target_user is None and body.phone is not None:
            target_user = User(
                phone=body.phone,
                full_name="",
                user_category=UserCategory.BUSINESS_USER,
                status=UserStatus.INVITED,
                password_hash=None,
                is_phone_verified=False,
            )
            db.add(target_user)
            await db.flush()
            await db.refresh(target_user)

        if target_user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        role = await db.get(BusinessRole, body.business_role_id)
        if role is None or role.business_id != business_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business role not found",
            )

        if target_user.user_category != UserCategory.BUSINESS_USER:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Only business users can be assigned business roles. "
                    "The target user's category is not 'business_user'."
                ),
            )

        existing = (
            await db.exec(
                select(UserBusinessRole).where(
                    UserBusinessRole.user_id == target_user.id,
                    UserBusinessRole.business_id == business_id,
                    UserBusinessRole.business_role_id == body.business_role_id,
                )
            )
        ).one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=("This user already has this role assignment at this business."),
            )

        ubr = UserBusinessRole(
            user_id=target_user.id,
            business_id=business_id,
            business_role_id=body.business_role_id,
        )
        db.add(ubr)

    return {"detail": "Staff role assigned"}
