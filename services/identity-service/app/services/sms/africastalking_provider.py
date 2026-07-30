from __future__ import annotations

from functools import cache
from typing import Any

import structlog

from app.core.config import get_settings
from app.services.sms.base import SMSSendResult

logger = structlog.get_logger(__name__)

_SUCCESS_CODES = {100, 101, 102}
"""
AT recipient-level status codes considered successful:
  100 = Processed, 101 = Sent, 102 = Queued
Other codes (401-502) represent failures — see ``_map_error`` below.

⚠  VERIFY BEFORE PRODUCTION: The ``Recipients`` list field names
(``statusCode``, ``messageId``, ``number``, ``cost``) are based on
the Africa's Talking REST API docs. The Python SDK wraps this into
``SMSMessageData`` objects.  If the SDK version installed returns
different attribute names, adjust field access accordingly.
"""


@cache
def _get_at_sdk() -> Any:
    """Lazy-init the Africa's Talking SDK once and cache the SMS service handle.

    ``africastalking.initialize`` is safe to call multiple times but
    we cache after the first call to avoid repeated global-state setup.
    """
    import africastalking

    settings = get_settings()
    africastalking.initialize(settings.at_username, settings.at_api_key)
    return africastalking.SMS


_FAILURE_MAP: dict[int, str] = {
    401: "Risk hold — message flagged by AT fraud detection",
    402: "Invalid sender ID",
    403: "Invalid phone number",
    404: "Unsupported number type",
    405: "Insufficient account balance",
    406: "Recipient is in blacklist",
    407: "Could not route message",
    500: "AT internal server error",
    501: "AT gateway error",
    502: "Rejected by gateway",
}


def _map_error(status_code: int) -> str:
    return _FAILURE_MAP.get(status_code, f"Unknown AT status code {status_code}")


class AfricasTalkingProvider:
    def __init__(self) -> None:
        self._sms = _get_at_sdk()

    async def send_sms(self, phone: str, message: str) -> SMSSendResult:
        settings = get_settings()
        try:
            response = self._sms.send(
                message,
                [phone],
                sender_id=settings.at_sender_id,
            )
        except Exception as exc:
            logger.error(
                "sms_at_sdk_exception",
                phone=phone,
                error=str(exc),
            )
            return SMSSendResult(success=False, error=str(exc))

        """
        Expected response shape (from AT Python SDK):

            {
                "SMSMessageData": {
                    "Message": "Sent to 1 recipients",
                    "Recipients": [
                        {
                            "statusCode": 101,
                            "number": "+2557xxxxxxxx",
                            "cost": "TZS 10.0000",
                            "messageId": "ATXid_xxxxx",
                        }
                    ]
                }
            }

        ⚠  VERIFY BEFORE PRODUCTION: The exact attribute nesting and key
        casing depends on the SDK version.  If ``response`` is already a
        dict, adjust access accordingly; if it is an SDK-specific object,
        use its attribute accessors.  The code below assumes
        ``response["SMSMessageData"]["Recipients"]`` is a list of dicts.
        """

        try:
            data = response["SMSMessageData"]
            recipients = data["Recipients"]
        except Exception as exc:
            logger.error(
                "sms_at_unexpected_response_shape",
                response=response,
                error=str(exc),
            )
            return SMSSendResult(
                success=False,
                error=f"Unexpected AT response shape: {exc}",
            )

        if not recipients:
            logger.error("sms_at_empty_recipients", response=response)
            return SMSSendResult(success=False, error="AT returned no recipients")

        recipient = recipients[0]
        status_code = recipient.get("statusCode", 0)
        message_id = recipient.get("messageId")

        if status_code in _SUCCESS_CODES:
            return SMSSendResult(success=True, provider_message_id=message_id)

        error_text = _map_error(status_code)
        logger.warning(
            "sms_at_recipient_failure",
            phone=phone,
            status_code=status_code,
            error=error_text,
        )
        return SMSSendResult(success=False, error=error_text)
