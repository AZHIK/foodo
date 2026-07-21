import asyncio
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
import pytest_asyncio
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.database import async_session_factory
from app.core.exceptions import OtpAttemptsExhaustedError, OtpCodeInvalidError
from app.models import VerificationCode, VerificationCodePurpose, VerificationCodeType
from app.models.user import User, UserCategory
from app.services.otp_service import generate_and_store_otp, verify_otp


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


PURPOSE = VerificationCodePurpose.PHONE_VERIFICATION
DELIVERY = VerificationCodeType.SMS


def _settings():
    return get_settings()


class TestGenerateAndStoreOtp:
    async def test_stores_hashed_code_not_raw(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        raw = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        codes = (await db_session.exec(select(VerificationCode))).all()
        assert len(codes) == 1
        stored = codes[0]
        assert stored.code_hash != raw
        assert stored.purpose == PURPOSE
        assert stored.type == DELIVERY
        assert stored.user_id == test_user.id
        assert stored.attempts == 0
        assert stored.used_at is None
        assert stored.expires_at > datetime.now(UTC)

    async def test_second_otp_invalidates_first(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        raw1 = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        raw2 = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        assert not await verify_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code=raw1
        )
        assert await verify_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code=raw2
        )

    async def test_generates_different_codes_each_time(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        raw1 = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        raw2 = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        assert raw1 != raw2


class TestVerifyOtp:
    async def test_correct_code_succeeds(self, db_session: AsyncSession, test_user: User) -> None:
        raw = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        result = await verify_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code=raw
        )
        assert result is True
        codes = (await db_session.exec(select(VerificationCode))).all()
        assert codes[-1].used_at is not None

    async def test_correct_code_twice_fails_second_time(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        raw = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        assert await verify_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code=raw
        )
        with pytest.raises(OtpCodeInvalidError):
            await verify_otp(db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code=raw)

    async def test_incorrect_code_fails_and_increments_attempts(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        result = await verify_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code="000000"
        )
        assert result is False
        codes = (await db_session.exec(select(VerificationCode))).all()
        assert codes[-1].attempts == 1

    async def test_expired_code_fails(self, db_session: AsyncSession, test_user: User) -> None:
        raw = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        async with async_session_factory() as sess:
            codes = (await sess.exec(select(VerificationCode))).all()
            stored = codes[-1]
            stored.expires_at = datetime.now(UTC) - timedelta(minutes=1)
            sess.add(stored)
            await sess.commit()
        with pytest.raises(OtpCodeInvalidError):
            await verify_otp(db_session, user_id=test_user.id, purpose=PURPOSE, submitted_code=raw)

    async def test_no_code_raises_error(self, db_session: AsyncSession, test_user: User) -> None:
        with pytest.raises(OtpCodeInvalidError):
            await verify_otp(
                db_session,
                user_id=test_user.id,
                purpose=PURPOSE,
                submitted_code="123456",
            )


class TestAttemptLockout:
    async def test_max_wrong_attempts_locks_out(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        settings = _settings()
        raw = await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        for _ in range(settings.otp_max_attempts):
            result = await verify_otp(
                db_session,
                user_id=test_user.id,
                purpose=PURPOSE,
                submitted_code="000000",
            )
            if _ < settings.otp_max_attempts - 1:
                assert result is False
            else:
                assert result is False
        with pytest.raises(OtpAttemptsExhaustedError):
            await verify_otp(
                db_session,
                user_id=test_user.id,
                purpose=PURPOSE,
                submitted_code=raw,
            )

    async def test_concurrent_verify_near_limit_serialized_by_for_update(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        settings = _settings()
        await generate_and_store_otp(
            db_session, user_id=test_user.id, purpose=PURPOSE, delivery_type=DELIVERY
        )
        async with async_session_factory() as prep_sess:
            codes = (await prep_sess.exec(select(VerificationCode))).all()
            stored = codes[-1]
            stored.attempts = settings.otp_max_attempts - 1
            code_id = stored.id
            prep_sess.add(stored)
            await prep_sess.commit()

        async def attempt_in_session(wrong_code: str) -> type | None:
            async with async_session_factory() as sess:
                try:
                    await verify_otp(
                        sess,
                        user_id=test_user.id,
                        purpose=PURPOSE,
                        submitted_code=wrong_code,
                    )
                    return None
                except Exception as exc:
                    return type(exc)

        results = await asyncio.gather(attempt_in_session("111111"), attempt_in_session("222222"))
        nones = sum(1 for r in results if r is None)
        exhausted = sum(1 for r in results if r is OtpAttemptsExhaustedError)
        assert nones == 1
        assert exhausted == 1

        async with async_session_factory() as check_sess:
            final = await check_sess.get(VerificationCode, code_id)
        assert final is not None
        assert final.attempts == settings.otp_max_attempts
        assert final.used_at is None
