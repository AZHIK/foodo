from uuid import UUID

import structlog
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.events import publish_event
from app.models.business import Business, BusinessRole, BusinessRolePermission, UserBusinessRole
from app.models.template import RoleTemplate, RoleTemplatePermission
from app.services.audit_events import publish_audit_recorded

logger = structlog.get_logger(__name__)


async def create_business(
    db: AsyncSession,
    *,
    creator_user_id: UUID,
    name: str,
    business_type: str,
    organization_id: UUID | None = None,
    tax_id: str | None = None,
    country_code: str = "TZ",
    city: str | None = None,
    timezone: str = "Africa/Dar_es_Salaam",
) -> Business:
    async with db.begin():
        business = Business(
            name=name,
            business_type=business_type,
            owner_user_id=creator_user_id,
            organization_id=organization_id,
            tax_id=tax_id,
            country_code=country_code,
            city=city,
            timezone=timezone,
        )
        db.add(business)
        await db.flush()
        await db.refresh(business)

        templates = (
            await db.exec(
                select(RoleTemplate).where(RoleTemplate.business_type == business_type)
            )
        ).all()

        if not templates:
            logger.error(
                "no_role_templates_for_business_type",
                business_type=business_type,
            )
            raise ValueError(
                f"No role templates found for business_type '{business_type}'. "
                "Seed role_templates first."
            )

        cloned_role_ids: list[UUID] = []
        owner_role_id: UUID | None = None
        owner_role_name: str | None = None
        role_names: list[str] = []

        for template in templates:
            role = BusinessRole(
                business_id=business.id,
                name=template.name,
                description=template.description,
                is_protected=template.is_owner_template,
            )
            db.add(role)
            await db.flush()
            await db.refresh(role)
            cloned_role_ids.append(role.id)
            role_names.append(role.name)

            template_perms = (
                await db.exec(
                    select(RoleTemplatePermission).where(
                        RoleTemplatePermission.role_template_id == template.id,
                    )
                )
            ).all()

            for tp in template_perms:
                db.add(
                    BusinessRolePermission(
                        business_role_id=role.id,
                        permission_code=tp.permission_code,
                    )
                )

            if template.is_owner_template:
                owner_role_id = role.id
                owner_role_name = role.name

        if owner_role_id is None:
            logger.error(
                "no_owner_template_found",
                business_type=business_type,
            )
            raise ValueError(
                f"No owner template found for business_type '{business_type}'. "
                "Ensure one role_template has is_owner_template=true."
            )

        db.add(
            UserBusinessRole(
                user_id=creator_user_id,
                business_id=business.id,
                business_role_id=owner_role_id,
            )
        )

    await publish_event(
        "business.created",
        {
            "business_id": str(business.id),
            "creator_user_id": str(creator_user_id),
            "business_type": business_type,
            "cloned_role_count": len(cloned_role_ids),
            "role_names": role_names,
            "owner_role_name": owner_role_name,
        },
    )

    await publish_audit_recorded(
        actor_id=creator_user_id,
        actor_type="user",
        business_id=business.id,
        action="business.created",
        resource_type="business",
        resource_id=business.id,
        details={
            "business_type": business_type,
            "cloned_role_count": len(cloned_role_ids),
        },
    )

    await publish_audit_recorded(
        actor_id=creator_user_id,
        actor_type="user",
        business_id=business.id,
        action="business_role.assigned",
        resource_type="business_role",
        resource_id=owner_role_id,
        details={
            "role_name": owner_role_name,
            "target_user_id": str(creator_user_id),
        },
    )

    return business
