from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_async_session
from app.core.permission_codes import PermissionCode
from app.deps.auth import get_current_user_id
from app.deps.permissions import require_business_permission
from app.models.business import Business, BusinessRole
from app.schemas.business import BusinessCreateRequest, BusinessCreateResponse, BusinessRead
from app.schemas.business_rbac import BusinessRoleRead
from app.services.business_service import create_business

router = APIRouter(prefix="/api/v1/businesses", tags=["Businesses"])


@router.post("", response_model=BusinessCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_business_endpoint(
    body: BusinessCreateRequest,
    db: AsyncSession = Depends(get_async_session),
    creator_user_id: str = Depends(get_current_user_id),
) -> BusinessCreateResponse:
    result = await create_business(
        db,
        creator_user_id=UUID(creator_user_id),
        name=body.name,
        business_type=body.business_type.value,
        organization_id=body.organization_id,
        tax_id=body.tax_id,
        registration_number=body.registration_number,
        email=body.email,
        phone=body.phone,
        address=body.address,
        status=body.status.value,
        logo=body.logo,
        country_code=body.country_code,
        city=body.city,
        timezone=body.timezone,
    )
    business = result.business

    roles = (
        await db.exec(select(BusinessRole).where(BusinessRole.business_id == business.id))
    ).all()
    role_names = [r.name for r in roles]
    owner_role = next((r for r in roles if r.is_protected), None)

    return BusinessCreateResponse(
        business=BusinessRead.model_validate(business),
        roles_created=role_names,
        owner_role_name=owner_role.name if owner_role else "",
    )


@router.get("/{business_id}", response_model=BusinessRead)
async def get_business(
    business_id: UUID,
    db: AsyncSession = Depends(get_async_session),
    _caller_business_id: str = Depends(require_business_permission(PermissionCode.BUSINESSES_VIEW)),
) -> BusinessRead:
    business = await db.get(Business, business_id)
    if business is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Business not found",
        )
    return BusinessRead.model_validate(business)


@router.get("/{business_id}/roles", response_model=list[BusinessRoleRead])
async def list_business_roles(
    business_id: UUID,
    db: AsyncSession = Depends(get_async_session),
    caller_business_id: str = Depends(
        require_business_permission(PermissionCode.BUSINESS_ROLES_VIEW)
    ),
) -> list[BusinessRoleRead]:
    if str(business_id) != caller_business_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token business context does not match the requested business",
        )

    roles = (
        await db.exec(
            select(BusinessRole)
            .where(BusinessRole.business_id == business_id)
            .where(BusinessRole.is_deleted == False)  # noqa: E712
        )
    ).all()

    return [BusinessRoleRead.model_validate(r) for r in roles]
