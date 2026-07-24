from collections.abc import Awaitable, Callable
from uuid import UUID

from fastapi import Depends, HTTPException, Request
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_async_session
from app.core.rate_limit import RateLimitDependency
from app.models.auth import AuthEventType, AuthRiskEvent, AuthRiskLevel
from app.models.user import User


async def record_auth_risk_event(
    session: AsyncSession,
    *,
    user_id: UUID | None = None,
    session_id: UUID | None = None,
    event_type: AuthEventType,
    risk_level: AuthRiskLevel,
    reason: str | None = None,
    ip_address: str | None = None,
) -> AuthRiskEvent:
    event = AuthRiskEvent(
        user_id=user_id,
        session_id=session_id,
        event_type=event_type,
        risk_level=risk_level,
        reason=reason,
        ip_address=ip_address,
        device_fingerprint_hash=None,
    )
    session.add(event)
    return event


def rate_limit_with_risk_event(
    key_prefix: str,
    limit: int,
    window_seconds: int,
    key_source: str | Callable[[Request], Awaitable[str]],
    event_type: AuthEventType,
    risk_level: AuthRiskLevel,
    reason: str,
    identifier_field: str,
    lookup_field: str = "phone",
) -> Callable[..., Awaitable[None]]:
    """Create a FastAPI dependency combining rate-limiting with risk-event recording.

    When the rate limit is exceeded, an ``auth_risk_events`` row is recorded
    before the ``429`` response is returned.
    """

    async def dependency(
        request: Request,
        db: AsyncSession = Depends(get_async_session),  # noqa: B008
    ) -> None:
        dep = RateLimitDependency(key_prefix, limit, window_seconds, key_source)
        try:
            await dep(request)
        except HTTPException as exc:
            if exc.status_code == 429:
                body = await request.json()
                identifier = body.get(identifier_field, "")
                if lookup_field == "phone":
                    result = await db.exec(select(User).where(User.phone == identifier))
                else:
                    result = await db.exec(select(User).where(User.email == identifier))
                user = result.one_or_none()
                await record_auth_risk_event(
                    db,
                    user_id=user.id if user else None,
                    event_type=event_type,
                    risk_level=risk_level,
                    reason=reason,
                    ip_address=request.client.host if request.client else None,
                )
                await db.commit()
            raise

    return dependency
