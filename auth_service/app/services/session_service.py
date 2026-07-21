from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from hashlib import sha256
from secrets import token_urlsafe
from uuid import UUID

from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.exceptions import InvalidRefreshTokenError
from app.models import RefreshToken, UserSession


@dataclass(frozen=True)
class IssuedRefreshToken:
    raw_token: str
    refresh_token: RefreshToken
    session: UserSession


def hash_refresh_token(raw_token: str) -> str:
    return sha256(raw_token.encode("utf-8")).hexdigest()


async def issue_login_session(
    session: AsyncSession,
    *,
    user_id: UUID,
    device_info: str | None,
    ip_address: str | None,
    ttl: timedelta = timedelta(days=7),
    raw_token: str | None = None,
) -> IssuedRefreshToken:
    now = datetime.now(UTC)
    token = raw_token or token_urlsafe(48)
    expires_at = now + ttl
    refresh_token = RefreshToken(
        user_id=user_id,
        token_hash=hash_refresh_token(token),
        device_info=device_info,
        ip_address=ip_address,
        expires_at=expires_at,
    )
    user_session = UserSession(
        user_id=user_id,
        refresh_token_id=refresh_token.id,
        device_info=device_info,
        ip_address=ip_address,
        last_activity_at=now,
        expires_at=expires_at,
        is_active=True,
    )
    async with session.begin():
        session.add(refresh_token)
        session.add(user_session)
    return IssuedRefreshToken(token, refresh_token, user_session)


async def get_usable_refresh_token(session: AsyncSession, raw_token: str) -> RefreshToken:
    result = await session.exec(
        select(RefreshToken).where(
            RefreshToken.token_hash == hash_refresh_token(raw_token),
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at > datetime.now(UTC),
        )
    )
    refresh_token = result.one_or_none()
    if refresh_token is None:
        raise InvalidRefreshTokenError("Refresh token is invalid, expired, or revoked.")
    return refresh_token


async def rotate_refresh_token(
    session: AsyncSession,
    *,
    raw_token: str,
    device_info: str | None = None,
    ip_address: str | None = None,
    ttl: timedelta = timedelta(days=7),
    new_raw_token: str | None = None,
) -> IssuedRefreshToken:
    now = datetime.now(UTC)
    token = new_raw_token or token_urlsafe(48)
    expires_at = now + ttl
    token_hash = hash_refresh_token(token)

    async with session.begin():
        old_result = await session.exec(
            select(RefreshToken).where(
                RefreshToken.token_hash == hash_refresh_token(raw_token),
                RefreshToken.revoked_at.is_(None),
                RefreshToken.expires_at > now,
            )
        )
        old = old_result.one_or_none()
        if old is None:
            raise InvalidRefreshTokenError("Refresh token is invalid, expired, or revoked.")

        sess_result = await session.exec(
            select(UserSession).where(
                UserSession.refresh_token_id == old.id,
                UserSession.is_active.is_(True),  # type: ignore[attr-defined]
            )
        )
        sess = sess_result.one()

        old.revoked_at = now
        new_refresh_token = RefreshToken(
            user_id=old.user_id,
            token_hash=token_hash,
            device_info=device_info or old.device_info,
            ip_address=ip_address or old.ip_address,
            expires_at=expires_at,
        )
        session.add(new_refresh_token)
        sess.refresh_token_id = new_refresh_token.id
        sess.device_info = new_refresh_token.device_info
        sess.ip_address = new_refresh_token.ip_address
        sess.last_activity_at = now
        sess.expires_at = expires_at
        sess.is_active = True

    return IssuedRefreshToken(token, new_refresh_token, sess)


async def revoke_refresh_token(session: AsyncSession, refresh_token_id: UUID) -> None:
    now = datetime.now(UTC)

    async with session.begin():
        refresh_token = await session.get(RefreshToken, refresh_token_id)
        if refresh_token is None:
            raise InvalidRefreshTokenError("Refresh token does not exist.")

        result = await session.exec(
            select(UserSession).where(UserSession.refresh_token_id == refresh_token_id)
        )
        user_session = result.one_or_none()

        refresh_token.revoked_at = refresh_token.revoked_at or now
        if user_session is not None:
            user_session.is_active = False


async def list_active_sessions(session: AsyncSession, user_id: UUID) -> list[UserSession]:
    result = await session.exec(
        select(UserSession).where(
            UserSession.user_id == user_id,
            UserSession.is_active.is_(True),  # type: ignore[attr-defined]
            UserSession.expires_at > datetime.now(UTC),
        )
    )
    return list(result.all())


async def revoke_session(session: AsyncSession, session_id: UUID) -> None:
    async with session.begin():
        user_session = await session.get(UserSession, session_id)
        if user_session is None:
            return

        user_session.is_active = False
        if user_session.refresh_token_id is not None:
            refresh_token = await session.get(RefreshToken, user_session.refresh_token_id)
            if refresh_token is not None:
                refresh_token.revoked_at = refresh_token.revoked_at or datetime.now(UTC)


async def revoke_all_sessions_for_user(session: AsyncSession, user_id: UUID) -> None:
    now = datetime.now(UTC)
    async with session.begin():
        active_sessions = await session.exec(
            select(UserSession).where(
                UserSession.user_id == user_id,
                UserSession.is_active,
            )
        )
        for user_session in active_sessions.all():
            user_session.is_active = False
            if user_session.refresh_token_id is not None:
                refresh_token = await session.get(RefreshToken, user_session.refresh_token_id)
                if refresh_token is not None:
                    refresh_token.revoked_at = refresh_token.revoked_at or now
