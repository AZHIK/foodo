"""FastAPI application factory for FoodLink Auth Service."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.v1.endpoints import auth, businesses, platform_auth
from app.core.config import get_settings
from app.core.logging import configure_logging
from app.core.redis_client import close_redis
from app.core.telemetry import configure_telemetry
from app.routers import health

settings = get_settings()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    configure_logging()
    configure_telemetry()
    try:
        yield
    finally:
        await close_redis()


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.environment != "prod" else None,
    redoc_url="/redoc" if settings.environment != "prod" else None,
)

app.include_router(health.router, prefix="")
app.include_router(auth.router)
app.include_router(platform_auth.router)
app.include_router(businesses.router)
