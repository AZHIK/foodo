from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class SMSSendResult:
    success: bool
    provider_message_id: str | None = None
    error: str | None = None


class SMSProvider(Protocol):
    async def send_sms(self, phone: str, message: str) -> SMSSendResult: ...
