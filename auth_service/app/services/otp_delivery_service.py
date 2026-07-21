from uuid import UUID

import structlog
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.exceptions import OtpDeliveryError
from app.models import VerificationCodePurpose, VerificationCodeType
from app.services.otp_service import generate_and_store_otp
from app.services.sms import get_sms_provider

logger = structlog.get_logger(__name__)


async def generate_and_send_otp_sms(
    session: AsyncSession,
    *,
    user_id: UUID,
    phone: str,
    purpose: VerificationCodePurpose = VerificationCodePurpose.PHONE_VERIFICATION,
) -> str:
    raw_code = await generate_and_store_otp(
        session,
        user_id=user_id,
        purpose=purpose,
        delivery_type=VerificationCodeType.SMS,
    )

    message = f"Your FoodLink verification code is: {raw_code}. It expires in 5 minutes."

    provider = get_sms_provider()
    result = await provider.send_sms(phone=phone, message=message)

    if not result.success:
        error_detail = result.error or "unknown"
        logger.error(
            "otp_sms_delivery_failed",
            user_id=str(user_id),
            phone=phone,
            error=error_detail,
        )
        raise OtpDeliveryError(f"Failed to deliver OTP via SMS: {error_detail}")

    logger.info(
        "otp_sms_delivered",
        user_id=str(user_id),
        phone=phone,
        provider_message_id=result.provider_message_id,
    )
    return raw_code
