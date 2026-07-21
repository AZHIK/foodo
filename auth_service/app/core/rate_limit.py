"""Generic fixed-window rate-limiter backed by Redis.

Kept intentionally generic — no auth-specific logic lives here.
"""

from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from hashlib import sha256
from typing import Any

from fastapi import HTTPException, Request, status

from app.core.events import publish_event
from app.core.redis_client import get_redis


@dataclass
class RateLimitResult:
    allowed: bool
    remaining: int
    retry_after_seconds: int | None = field(default=None)


async def check_and_increment(
    key: str,
    limit: int,
    window_seconds: int,
) -> RateLimitResult:
    """Fixed-window counter: INCR, set EXPIRE on first creation, compare.

    Returns a ``RateLimitResult`` describing whether the request is allowed
    and how long the caller should wait before retrying.
    """
    r = await get_redis()
    count = await r.incr(key)

    if count == 1:
        await r.expire(key, window_seconds)

    ttl = await r.ttl(key)

    if count > limit:
        return RateLimitResult(
            allowed=False,
            remaining=0,
            retry_after_seconds=max(ttl, 1) if ttl > 0 else None,
        )

    return RateLimitResult(
        allowed=True,
        remaining=int(limit - count),
        retry_after_seconds=None,
    )


def body_field_source(field_name: str) -> Callable[[Request], Awaitable[str]]:
    """Return an async callable that extracts ``field_name`` from the request body."""

    async def _extract(request: Request) -> str:
        body: dict[str, Any] = await request.json()
        return str(body.get(field_name, "unknown"))

    return _extract


def _safe_key_part(value: str) -> str:
    """Keep identifiers out of Redis key names and emitted events."""
    return sha256(value.encode("utf-8")).hexdigest()


class RateLimitDependency:
    """FastAPI dependency that checks (and increments) a rate-limit counter.

    Usage::

        dependencies=[
            Depends(RateLimitDependency(
                key_prefix="login_password_phone",
                limit=5,
                window_seconds=900,
                key_source=body_field_source("phone"),
            )),
            Depends(RateLimitDependency(
                key_prefix="login_password_ip",
                limit=20,
                window_seconds=900,
                key_source="ip",
            )),
        ]

    When the limit is exceeded a ``429 Too Many Requests`` response is returned
    with a ``Retry-After`` header.  An ``auth.rate_limit_exceeded`` event is
    also published so operators can monitor abuse.
    """

    def __init__(
        self,
        key_prefix: str,
        limit: int,
        window_seconds: int,
        key_source: str | Callable[[Request], Awaitable[str]],
    ) -> None:
        self.key_prefix = key_prefix
        self.limit = limit
        self.window_seconds = window_seconds
        self.key_source = key_source

    async def __call__(self, request: Request) -> None:
        if self.key_source == "ip":
            key = request.client.host if request.client else "unknown"
        elif callable(self.key_source):
            key = await self.key_source(request)
        else:
            key = str(self.key_source)

        full_key = f"ratelimit:{self.key_prefix}:{_safe_key_part(key)}"
        result = await check_and_increment(full_key, self.limit, self.window_seconds)

        if not result.allowed:
            await publish_event(
                "auth.rate_limit_exceeded",
                {
                    "endpoint": request.url.path,
                    "key": full_key,
                    "limit_type": self.key_prefix.rsplit("_", 1)[-1],
                },
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many attempts, please try again later",
                headers={"Retry-After": str(result.retry_after_seconds)},
            )
