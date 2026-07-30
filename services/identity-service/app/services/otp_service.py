from datetime import UTC, datetime, timedelta
from secrets import randbelow
from uuid import UUID

from sqlmodel import desc, select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.events import publish_event
from app.core.exceptions import OtpAttemptsExhaustedError, OtpCodeInvalidError
from app.core.security import hash_otp_code, verify_otp_code
from app.models import VerificationCode, VerificationCodePurpose, VerificationCodeType


async def generate_and_store_otp(
    session: AsyncSession,
    *,
    user_id: UUID,
    purpose: VerificationCodePurpose,
    delivery_type: VerificationCodeType,
) -> str:
    """Generate a 6-digit OTP, hash it, store it, and return the raw code.

    Invalidates any existing unconsumed unexpired code for the same
    ``user_id`` + ``purpose`` by marking it as used (``used_at = now``).
    This prevents multiple valid codes from existing simultaneously for
    the same purpose — a security requirement inherited from the
    principle that only one outstanding verification flow per purpose
    should be active at any time.

    Deletion would also prevent multiple valid codes, but marking as
    used preserves the audit trail (the row stays in the table with a
    non-null ``used_at``) so the caller can inspect the history of
    generated codes without relying on separate audit logs.
    """
    settings = get_settings()
    now = datetime.now(UTC)
    code = f"{randbelow(1_000_000):06d}"
    code_hash = hash_otp_code(code)
    expires_at = now + timedelta(minutes=settings.otp_expire_minutes)

    async with session.begin():
        old_codes_result = await session.exec(
            select(VerificationCode).where(
                VerificationCode.user_id == user_id,
                VerificationCode.purpose == purpose,
                VerificationCode.used_at.is_(None),
                VerificationCode.expires_at > now,
            )
        )
        for old_code in old_codes_result.all():
            old_code.used_at = now

        verification_code = VerificationCode(
            user_id=user_id,
            code_hash=code_hash,
            type=delivery_type,
            purpose=purpose,
            expires_at=expires_at,
            attempts=0,
        )
        session.add(verification_code)

    await publish_event(
        "otp.generated",
        {
            "user_id": str(user_id),
            "purpose": purpose.value,
            "delivery_type": delivery_type.value,
        },
    )

    return code


async def verify_otp(
    session: AsyncSession,
    *,
    user_id: UUID,
    purpose: VerificationCodePurpose,
    submitted_code: str,
) -> bool:
    """Verify a submitted OTP code against the most recent stored code.

    Uses ``SELECT ... FOR UPDATE`` to prevent a concurrent read of the
    same row's ``attempts`` counter from bypassing the attempt cap when
    two verifications arrive near-simultaneously at the boundary.

    Raises:
        OtpCodeInvalidError — no code exists, expired, or already used.
        OtpAttemptsExhaustedError — max verification attempts reached.
    """
    settings = get_settings()
    now = datetime.now(UTC)

    async with session.begin():
        result = await session.exec(
            select(VerificationCode)
            .where(
                VerificationCode.user_id == user_id,
                VerificationCode.purpose == purpose,
                VerificationCode.used_at.is_(None),
            )
            .order_by(desc(VerificationCode.created_at))
            .limit(1)
            .with_for_update()
        )
        code = result.one_or_none()

        if code is None:
            raise OtpCodeInvalidError("No verification code found for this user and purpose.")

        if code.expires_at < now:
            raise OtpCodeInvalidError("Verification code has expired.")

        if code.attempts >= settings.otp_max_attempts:
            code.attempts = min(code.attempts + 1, settings.otp_max_attempts)
            raise OtpAttemptsExhaustedError(
                "Maximum verification attempts reached. Please request a new code."
            )

        if not verify_otp_code(submitted_code, code.code_hash):
            code.attempts += 1
            return False

        code.used_at = now
        return True
