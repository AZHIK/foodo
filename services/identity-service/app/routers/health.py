"""Health-check endpoints — liveness and readiness probes.

- GET /health        : liveness — always returns 200 if the process is alive.
- GET /health/ready  : readiness — returns 200 only when DB and Redis respond.
"""

import structlog
from fastapi import APIRouter
from redis import asyncio as aioredis
from sqlmodel import select

from app.core.config import get_settings
from app.core.database import async_session_factory
from app.schemas.health import HealthResponse, ReadinessResponse

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["health"])
settings = get_settings()


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse()


@router.get("/health/ready", response_model=ReadinessResponse)
async def readiness() -> ReadinessResponse:
    db_status = "unknown"
    redis_status = "unknown"

    # Check database connectivity
    try:
        async with async_session_factory() as session:
            await session.exec(select(1))
            db_status = "healthy"
    except Exception as exc:
        logger.warning("readiness_check_db_failed", error=str(exc))
        db_status = "unhealthy"

    # Check Redis connectivity
    try:
        redis_client = aioredis.from_url(settings.redis_url, socket_connect_timeout=2)
        await redis_client.ping()
        redis_status = "healthy"
        await redis_client.aclose()
    except Exception as exc:
        logger.warning("readiness_check_redis_failed", error=str(exc))
        redis_status = "unhealthy"

    overall = "healthy" if db_status == "healthy" and redis_status == "healthy" else "unhealthy"
    return ReadinessResponse(status=overall, database=db_status, redis=redis_status)
