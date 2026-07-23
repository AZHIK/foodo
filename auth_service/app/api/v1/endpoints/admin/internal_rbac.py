from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_async_session
from app.core.permission_codes import PermissionCode, coerce_permission_code
from app.deps.permissions import require_permission, require_platform_staff
from app.models.internal import Group, Role, RolePermission, UserGroup, UserRole
from app.models.platform import PlatformRole, PlatformRolePermission, UserPlatformRole
from app.models.user import User
from app.schemas.rbac import (
    AssignInternalRoleRequest,
    AssignPlatformRolePermissionRequest,
    AssignPlatformRoleRequest,
    AssignRolePermissionRequest,
    AssignUserToGroupRequest,
    GroupCreate,
    GroupRead,
    GroupUpdate,
    PlatformRoleCreate,
    PlatformRoleRead,
    PlatformRoleUpdate,
    RoleCreate,
    RoleRead,
    RoleUpdate,
)

router = APIRouter(prefix="/admin", tags=["Admin Internal RBAC"])


# ── Groups ──────────────────────────────────────────────────────────────────


@router.get("/groups", response_model=list[GroupRead])
async def list_groups(
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_VIEW)),
    db: AsyncSession = Depends(get_async_session),
) -> list[Group]:
    result = await db.exec(select(Group))
    return list(result.all())


@router.get("/groups/{group_id}", response_model=GroupRead)
async def get_group(
    group_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_VIEW)),
    db: AsyncSession = Depends(get_async_session),
) -> Group:
    group = await db.get(Group, group_id)
    if group is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Group not found"
        )
    return group


@router.post("/groups", response_model=GroupRead, status_code=status.HTTP_201_CREATED)
async def create_group(
    body: GroupCreate,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_CREATE)),
    db: AsyncSession = Depends(get_async_session),
) -> Group:
    group = Group(name=body.name, description=body.description)
    async with db.begin():
        db.add(group)
    await db.refresh(group)
    return group


@router.patch("/groups/{group_id}", response_model=GroupRead)
async def update_group(
    group_id: UUID,
    body: GroupUpdate,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_UPDATE)),
    db: AsyncSession = Depends(get_async_session),
) -> Group:
    async with db.begin():
        group = await db.get(Group, group_id)
        if group is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Group not found"
            )

        update_data = body.model_dump(exclude_unset=True)
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update"
            )

        for field, value in update_data.items():
            setattr(group, field, value)
        db.add(group)
    await db.refresh(group)
    return group


@router.delete("/groups/{group_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group(
    group_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_DELETE)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        group = await db.get(Group, group_id)
        if group is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Group not found"
            )

        active_users = (
            await db.exec(select(UserGroup).where(UserGroup.group_id == group_id))
        ).all()
        if active_users:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot delete group with active user assignments",
            )

        await db.delete(group)


# ── Roles ───────────────────────────────────────────────────────────────────


@router.get("/roles", response_model=list[RoleRead])
async def list_roles(
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_VIEW)),
    db: AsyncSession = Depends(get_async_session),
) -> list[Role]:
    result = await db.exec(select(Role))
    return list(result.all())


@router.get("/roles/{role_id}", response_model=RoleRead)
async def get_role(
    role_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_VIEW)),
    db: AsyncSession = Depends(get_async_session),
) -> Role:
    role = await db.get(Role, role_id)
    if role is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
        )
    return role


@router.post("/roles", response_model=RoleRead, status_code=status.HTTP_201_CREATED)
async def create_role(
    body: RoleCreate,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_CREATE)),
    db: AsyncSession = Depends(get_async_session),
) -> Role:
    role = Role(group_id=body.group_id, name=body.name, description=body.description)
    async with db.begin():
        db.add(role)
    await db.refresh(role)
    return role


@router.patch("/roles/{role_id}", response_model=RoleRead)
async def update_role(
    role_id: UUID,
    body: RoleUpdate,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_UPDATE)),
    db: AsyncSession = Depends(get_async_session),
) -> Role:
    async with db.begin():
        role = await db.get(Role, role_id)
        if role is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )

        update_data = body.model_dump(exclude_unset=True)
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update"
            )

        for field, value in update_data.items():
            setattr(role, field, value)
        db.add(role)
    await db.refresh(role)
    return role


@router.delete("/roles/{role_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_role(
    role_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_DELETE)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        role = await db.get(Role, role_id)
        if role is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )

        active_assignments = (
            await db.exec(select(UserRole).where(UserRole.role_id == role_id))
        ).all()
        if active_assignments:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot delete role with active user assignments",
            )

        await db.delete(role)


# ── Role Permissions ────────────────────────────────────────────────────────


@router.post(
    "/roles/{role_id}/permissions", status_code=status.HTTP_201_CREATED
)
async def assign_role_permission(
    role_id: UUID,
    body: AssignRolePermissionRequest,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_MANAGE_PERMISSIONS)),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        role = await db.get(Role, role_id)
        if role is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )

        try:
            validated_code = coerce_permission_code(body.permission_code)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid permission code: {body.permission_code}",
            ) from None

        existing = (
            await db.exec(
                select(RolePermission).where(
                    RolePermission.role_id == role_id,
                    RolePermission.permission_code == str(validated_code),
                )
            )
        ).one_or_none()
        if existing:
            return {"detail": "Permission already assigned"}

        rp = RolePermission(role_id=role_id, permission_code=str(validated_code))
        db.add(rp)

    return {"detail": "Permission assigned"}


@router.delete("/roles/{role_id}/permissions", status_code=status.HTTP_204_NO_CONTENT)
async def remove_role_permission(
    role_id: UUID,
    permission_code: str = Query(...),
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_MANAGE_PERMISSIONS)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        role = await db.get(Role, role_id)
        if role is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )

        rp = (
            await db.exec(
                select(RolePermission).where(
                    RolePermission.role_id == role_id,
                    RolePermission.permission_code == permission_code,
                )
            )
        ).one_or_none()
        if rp is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not assigned to role",
            )

        await db.delete(rp)


# ── Platform Roles ───────────────────────────────────────────────────────────


@router.get("/platform-roles", response_model=list[PlatformRoleRead])
async def list_platform_roles(
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_VIEW)),
    db: AsyncSession = Depends(get_async_session),
) -> list[PlatformRole]:
    result = await db.exec(select(PlatformRole))
    return list(result.all())


@router.get("/platform-roles/{platform_role_id}", response_model=PlatformRoleRead)
async def get_platform_role(
    platform_role_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_VIEW)),
    db: AsyncSession = Depends(get_async_session),
) -> PlatformRole:
    pr = await db.get(PlatformRole, platform_role_id)
    if pr is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Platform role not found"
        )
    return pr


@router.post(
    "/platform-roles",
    response_model=PlatformRoleRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_platform_role(
    body: PlatformRoleCreate,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_CREATE)),
    db: AsyncSession = Depends(get_async_session),
) -> PlatformRole:
    pr = PlatformRole(name=body.name)
    async with db.begin():
        db.add(pr)
    await db.refresh(pr)
    return pr


@router.patch(
    "/platform-roles/{platform_role_id}", response_model=PlatformRoleRead
)
async def update_platform_role(
    platform_role_id: UUID,
    body: PlatformRoleUpdate,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_UPDATE)),
    db: AsyncSession = Depends(get_async_session),
) -> PlatformRole:
    async with db.begin():
        pr = await db.get(PlatformRole, platform_role_id)
        if pr is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Platform role not found"
            )

        update_data = body.model_dump(exclude_unset=True)
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update"
            )

        for field, value in update_data.items():
            setattr(pr, field, value)
        db.add(pr)
    await db.refresh(pr)
    return pr


@router.delete(
    "/platform-roles/{platform_role_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_platform_role(
    platform_role_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_DELETE)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        pr = await db.get(PlatformRole, platform_role_id)
        if pr is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Platform role not found"
            )

        active_assignments = (
            await db.exec(
                select(UserPlatformRole).where(
                    UserPlatformRole.platform_role_id == platform_role_id
                )
            )
        ).all()
        if active_assignments:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot delete platform role with active user assignments",
            )

        await db.delete(pr)


# ── Platform Role Permissions ────────────────────────────────────────────────


@router.post(
    "/platform-roles/{platform_role_id}/permissions",
    status_code=status.HTTP_201_CREATED,
)
async def assign_platform_role_permission(
    platform_role_id: UUID,
    body: AssignPlatformRolePermissionRequest,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_MANAGE_PERMISSIONS)),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        pr = await db.get(PlatformRole, platform_role_id)
        if pr is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Platform role not found"
            )

        try:
            validated_code = coerce_permission_code(body.permission_code)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid permission code: {body.permission_code}",
            ) from None

        existing = (
            await db.exec(
                select(PlatformRolePermission).where(
                    PlatformRolePermission.platform_role_id == platform_role_id,
                    PlatformRolePermission.permission_code == str(validated_code),
                )
            )
        ).one_or_none()
        if existing:
            return {"detail": "Permission already assigned"}

        prp = PlatformRolePermission(
            platform_role_id=platform_role_id, permission_code=str(validated_code)
        )
        db.add(prp)

    return {"detail": "Permission assigned"}


@router.delete(
    "/platform-roles/{platform_role_id}/permissions",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_platform_role_permission(
    platform_role_id: UUID,
    permission_code: str = Query(...),
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_MANAGE_PERMISSIONS)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        pr = await db.get(PlatformRole, platform_role_id)
        if pr is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Platform role not found"
            )

        prp = (
            await db.exec(
                select(PlatformRolePermission).where(
                    PlatformRolePermission.platform_role_id == platform_role_id,
                    PlatformRolePermission.permission_code == permission_code,
                )
            )
        ).one_or_none()
        if prp is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not assigned to platform role",
            )

        await db.delete(prp)


# ── User → Group Assignment ──────────────────────────────────────────────────


@router.post(
    "/users/{user_id}/group",
    status_code=status.HTTP_201_CREATED,
)
async def assign_user_to_group(
    user_id: UUID,
    body: AssignUserToGroupRequest,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_ASSIGN_USER)),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        user = await db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        group = await db.get(Group, body.group_id)
        if group is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Group not found"
            )

        existing = (
            await db.exec(select(UserGroup).where(UserGroup.user_id == user_id))
        ).one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "User already has a group assignment. "
                    "Remove the existing assignment first via DELETE "
                    "/admin/users/{user_id}/group before reassigning."
                ),
            )

        ug = UserGroup(user_id=user_id, group_id=body.group_id)
        db.add(ug)

    return {"detail": "User assigned to group"}


@router.delete(
    "/users/{user_id}/group",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_user_from_group(
    user_id: UUID,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.GROUPS_ASSIGN_USER)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        user = await db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        ug = (
            await db.exec(select(UserGroup).where(UserGroup.user_id == user_id))
        ).one_or_none()
        if ug is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User has no group assignment",
            )

        await db.delete(ug)


# ── User → Internal Role Assignment ──────────────────────────────────────────


@router.post(
    "/users/{user_id}/roles",
    status_code=status.HTTP_201_CREATED,
)
async def assign_user_role(
    user_id: UUID,
    body: AssignInternalRoleRequest,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_ASSIGN_TO_USER)),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        user = await db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        role = await db.get(Role, body.role_id)
        if role is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )

        user_group = (
            await db.exec(select(UserGroup).where(UserGroup.user_id == user_id))
        ).one_or_none()
        if user_group is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User has no group assignment. Assign a group first.",
            )

        if role.group_id != user_group.group_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Role's group does not match the user's group. "
                    "A user can only be assigned roles that belong to their group."
                ),
            )

        existing = (
            await db.exec(
                select(UserRole).where(
                    UserRole.user_id == user_id, UserRole.role_id == body.role_id
                )
            )
        ).one_or_none()
        if existing:
            return {"detail": "Role already assigned to user"}

        ur = UserRole(user_id=user_id, role_id=body.role_id)
        db.add(ur)

    return {"detail": "Role assigned to user"}


@router.delete(
    "/users/{user_id}/roles",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_user_role(
    user_id: UUID,
    role_id: UUID = Query(...),
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.ROLES_ASSIGN_TO_USER)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        user = await db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        ur = (
            await db.exec(
                select(UserRole).where(
                    UserRole.user_id == user_id, UserRole.role_id == role_id
                )
            )
        ).one_or_none()
        if ur is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role assignment not found",
            )

        await db.delete(ur)


# ── User → Platform Role Assignment ──────────────────────────────────────────


@router.post(
    "/users/{user_id}/platform-roles",
    status_code=status.HTTP_201_CREATED,
)
async def assign_user_platform_role(
    user_id: UUID,
    body: AssignPlatformRoleRequest,
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_ASSIGN_TO_USER)),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    async with db.begin():
        user = await db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        pr = await db.get(PlatformRole, body.platform_role_id)
        if pr is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Platform role not found"
            )

        existing = (
            await db.exec(
                select(UserPlatformRole).where(
                    UserPlatformRole.user_id == user_id,
                    UserPlatformRole.platform_role_id == body.platform_role_id,
                )
            )
        ).one_or_none()
        if existing:
            return {"detail": "Platform role already assigned to user"}

        upr = UserPlatformRole(user_id=user_id, platform_role_id=body.platform_role_id)
        db.add(upr)

    return {"detail": "Platform role assigned to user"}


@router.delete(
    "/users/{user_id}/platform-roles",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_user_platform_role(
    user_id: UUID,
    platform_role_id: UUID = Query(...),
    _staff: None = Depends(require_platform_staff()),
    _perm: None = Depends(require_permission(PermissionCode.PLATFORM_ROLES_ASSIGN_TO_USER)),
    db: AsyncSession = Depends(get_async_session),
) -> None:
    async with db.begin():
        user = await db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        upr = (
            await db.exec(
                select(UserPlatformRole).where(
                    UserPlatformRole.user_id == user_id,
                    UserPlatformRole.platform_role_id == platform_role_id,
                )
            )
        ).one_or_none()
        if upr is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Platform role assignment not found",
            )

        await db.delete(upr)
