"""User self-service endpoints.

Self-service (authenticated) endpoints that act on the caller's own
account, as opposed to admin/management endpoints.
"""

from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_async_session
from app.deps.auth import get_current_user
from app.models.business import UserBusinessRole
from app.models.user import User

router = APIRouter(prefix="/api/v1/users", tags=["User Self-Service"])


@router.get("/me/onboarding-status")
async def get_onboarding_status(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_session),
) -> dict[str, str | bool | None]:
    """Whether the caller still needs to complete onboarding.

    ``needs_onboarding`` is ``true`` only when the user has zero
    business-role assignments.  Invited staff become ``false`` once the
    owner has assigned them a role, even before they first log in.

    When onboarding is complete (``needs_onboarding=false``), the response
    also includes ``business_id`` and ``business_name`` from the user's
    single business role assignment (enforced by the one-business-per-user
    constraint).
    """
    from app.models.business import Business

    result = await db.exec(
        select(UserBusinessRole, Business.name)
        .join(Business, UserBusinessRole.business_id == Business.id)  # type: ignore[arg-type]
        .where(UserBusinessRole.user_id == user.id)
        .limit(1)
    )
    first = result.one_or_none()
    if first is None:
        return {"needs_onboarding": True, "business_id": None, "business_name": None}
    ubr, business_name = first
    return {
        "needs_onboarding": False,
        "business_id": str(ubr.business_id),
        "business_name": business_name,
    }
