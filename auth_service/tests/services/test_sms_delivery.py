from uuid import uuid4

import pytest
import pytest_asyncio
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.exceptions import OtpDeliveryError
from app.models import VerificationCodePurpose
from app.models.user import User, UserCategory
from app.services.otp_delivery_service import generate_and_send_otp_sms
from app.services.sms import SMSSendResult, get_sms_provider

PURPOSE = VerificationCodePurpose.PHONE_VERIFICATION


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    user = User(
        phone=f"+2557{uuid4().hex[:9]}",
        full_name="SMS Test User",
        user_category=UserCategory.CONSUMER,
    )
    async with db_session.begin():
        db_session.add(user)
    return user


class FakeFailingProvider:
    async def send_sms(self, phone: str, message: str) -> SMSSendResult:
        _ = phone, message
        return SMSSendResult(success=False, error="simulated failure")


class TestGenerateAndSendOtpSms:
    async def test_returns_raw_code_on_success(
        self, db_session: AsyncSession, test_user: User
    ) -> None:
        raw = await generate_and_send_otp_sms(
            db_session, user_id=test_user.id, phone=test_user.phone
        )
        assert isinstance(raw, str)
        assert len(raw) == 6
        assert raw.isdigit()

    async def test_provider_is_console_by_default(self) -> None:
        settings = get_settings()
        assert settings.sms_provider == "console"
        provider = get_sms_provider()
        assert isinstance(provider.__class__.__name__, str)

    async def test_raises_otp_delivery_error_on_failure(
        self, monkeypatch: pytest.MonkeyPatch, db_session: AsyncSession, test_user: User
    ) -> None:
        monkeypatch.setattr(
            "app.services.otp_delivery_service.get_sms_provider",
            lambda: FakeFailingProvider(),
        )
        with pytest.raises(OtpDeliveryError, match="simulated failure"):
            await generate_and_send_otp_sms(db_session, user_id=test_user.id, phone=test_user.phone)
