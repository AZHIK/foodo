from uuid import UUID

from sqlmodel.ext.asyncio.session import AsyncSession

from app.models.auth import LoginAttempt


async def record_login_attempt(
    session: AsyncSession,
    *,
    user_id: UUID | None = None,
    identifier: str,
    success: bool,
    failure_reason: str | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> LoginAttempt:
    attempt = LoginAttempt(
        user_id=user_id,
        identifier=identifier,
        success=success,
        failure_reason=failure_reason,
        ip_address=ip_address,
        device_fingerprint_hash=None,
        user_agent=user_agent,
    )
    session.add(attempt)
    return attempt
