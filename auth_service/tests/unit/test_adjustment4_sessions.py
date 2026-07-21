from uuid import uuid4

import pytest
import pytest_asyncio
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.exceptions import InvalidRefreshTokenError
from app.models import RefreshToken, UserSession
from app.models.user import User, UserCategory
from app.services.session_service import (
    get_usable_refresh_token,
    issue_login_session,
    list_active_sessions,
    revoke_refresh_token,
    revoke_session,
    rotate_refresh_token,
)


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    user = User(
        phone=f"+2557{uuid4().hex[:9]}",
        full_name="Test User",
        user_category=UserCategory.CONSUMER,
    )
    async with db_session.begin():
        db_session.add(user)
    return user


async def test_logging_in_creates_refresh_token_and_linked_session(
    db_session: AsyncSession, test_user: User
) -> None:
    issued = await issue_login_session(
        db_session,
        user_id=test_user.id,
        device_info="Pixel 9",
        ip_address="127.0.0.1",
        raw_token="login-token",
    )

    refresh_tokens = (await db_session.exec(select(RefreshToken))).all()
    user_sessions = (await db_session.exec(select(UserSession))).all()

    assert len(refresh_tokens) == 1
    assert len(user_sessions) == 1
    assert issued.session.refresh_token_id == issued.refresh_token.id
    assert user_sessions[0].is_active is True


async def test_refreshing_rotates_token_and_updates_existing_session(
    db_session: AsyncSession, test_user: User
) -> None:
    issued = await issue_login_session(
        db_session,
        user_id=test_user.id,
        device_info="Pixel 9",
        ip_address="127.0.0.1",
        raw_token="old-token",
    )
    original_session_id = issued.session.id
    original_activity = issued.session.last_activity_at

    rotated = await rotate_refresh_token(
        db_session,
        raw_token="old-token",
        ip_address="127.0.0.2",
        new_raw_token="new-token",
    )

    refresh_tokens = (await db_session.exec(select(RefreshToken))).all()
    user_sessions = (await db_session.exec(select(UserSession))).all()

    assert len(refresh_tokens) == 2
    assert len(user_sessions) == 1
    assert rotated.session.id == original_session_id
    assert rotated.session.refresh_token_id == rotated.refresh_token.id
    assert rotated.session.last_activity_at >= original_activity
    assert refresh_tokens[0].revoked_at is not None


async def test_revoking_session_revokes_linked_refresh_token(
    db_session: AsyncSession, test_user: User
) -> None:
    issued = await issue_login_session(
        db_session,
        user_id=test_user.id,
        device_info=None,
        ip_address=None,
        raw_token="session-token",
    )

    await revoke_session(db_session, issued.session.id)

    stored_session = await db_session.get(UserSession, issued.session.id)
    stored_token = await db_session.get(RefreshToken, issued.refresh_token.id)
    assert stored_session is not None
    assert stored_token is not None
    assert stored_session.is_active is False
    assert stored_token.revoked_at is not None
    with pytest.raises(InvalidRefreshTokenError):
        await get_usable_refresh_token(db_session, "session-token")


async def test_revoking_refresh_token_directly_marks_session_inactive(
    db_session: AsyncSession, test_user: User
) -> None:
    issued = await issue_login_session(
        db_session,
        user_id=test_user.id,
        device_info=None,
        ip_address=None,
        raw_token="direct-token",
    )

    await revoke_refresh_token(db_session, issued.refresh_token.id)

    stored_session = await db_session.get(UserSession, issued.session.id)
    assert stored_session is not None
    assert stored_session.is_active is False
    assert await list_active_sessions(db_session, test_user.id) == []
