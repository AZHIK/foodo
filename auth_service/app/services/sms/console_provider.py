from uuid import uuid4

import structlog

from app.services.sms.base import SMSSendResult

logger = structlog.get_logger(__name__)


class ConsoleProvider:
    async def send_sms(self, phone: str, message: str) -> SMSSendResult:
        fake_id = uuid4().hex[:16]
        logger.info("sms_console_send", phone=phone, message=message, fake_id=fake_id)
        return SMSSendResult(success=True, provider_message_id=fake_id)
