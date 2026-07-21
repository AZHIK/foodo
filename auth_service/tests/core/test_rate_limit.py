"""Tests for the Redis-backed rate-limiter utility."""

import asyncio

from app.core.rate_limit import check_and_increment


class TestCheckAndIncrement:
    async def test_allows_requests_under_limit(self) -> None:
        key = "ratelimit:test:phone:under"
        for i in range(5):
            result = await check_and_increment(key, limit=5, window_seconds=60)
            assert result.allowed is True
            assert result.remaining == 4 - i

    async def test_rejects_request_over_limit(self) -> None:
        key = "ratelimit:test:phone:over"
        for _ in range(5):
            await check_and_increment(key, limit=5, window_seconds=60)

        result = await check_and_increment(key, limit=5, window_seconds=60)
        assert result.allowed is False
        assert result.remaining == 0
        assert result.retry_after_seconds is not None
        assert result.retry_after_seconds > 0

    async def test_retry_after_reflects_ttl(self) -> None:
        key = "ratelimit:test:retry_after"
        for _ in range(5):
            await check_and_increment(key, limit=5, window_seconds=60)

        result = await check_and_increment(key, limit=5, window_seconds=60)
        assert result.retry_after_seconds is not None
        assert 1 <= result.retry_after_seconds <= 60

    async def test_window_resets_after_expiry(self) -> None:
        key = "ratelimit:test:window_reset"
        for _ in range(5):
            await check_and_increment(key, limit=5, window_seconds=2)

        # Request that exceeds limit
        result = await check_and_increment(key, limit=5, window_seconds=2)
        assert result.allowed is False

        # Wait for window to expire
        await asyncio.sleep(2.1)

        # Should be allowed again
        result = await check_and_increment(key, limit=5, window_seconds=2)
        assert result.allowed is True
        assert result.remaining == 4

    async def test_different_keys_tracked_independently(self) -> None:
        key_a = "ratelimit:test:phone:a"
        key_b = "ratelimit:test:phone:b"

        # Fill up key_a
        for _ in range(5):
            await check_and_increment(key_a, limit=5, window_seconds=60)

        # key_a should be blocked
        result_a = await check_and_increment(key_a, limit=5, window_seconds=60)
        assert result_a.allowed is False

        # key_b should still allow requests
        result_b = await check_and_increment(key_b, limit=5, window_seconds=60)
        assert result_b.allowed is True
        assert result_b.remaining == 4
