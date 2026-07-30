from app.core.config import get_settings
from app.services.sms.africastalking_provider import AfricasTalkingProvider
from app.services.sms.base import SMSProvider, SMSSendResult
from app.services.sms.console_provider import ConsoleProvider


def get_sms_provider() -> SMSProvider:
    settings = get_settings()
    if settings.sms_provider == "africastalking":
        return AfricasTalkingProvider()
    return ConsoleProvider()


__all__ = ["SMSProvider", "SMSSendResult", "get_sms_provider"]
