from typing import Any


async def publish_event(event_name: str, payload: dict[str, Any]) -> None:
    """Publish an event to the shared event bus.

    This is a stub until the platform event bus is wired.
    """
