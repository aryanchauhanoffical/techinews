import asyncio
import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import admin, articles, auth, trends, notifications
from app.core.config import get_settings
from app.db import mongo, redis_cache
from app.services import firebase
from app.services.article_repo import articles as repo
from app.services.pipeline import Pipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Connect infra (all best-effort — failures degrade gracefully).
    await mongo.connect()
    await redis_cache.connect()
    firebase.init()

    # Auto-run pipeline once at startup if store is empty (and SKIP_BOOT_PIPELINE != 1).
    if os.getenv("SKIP_BOOT_PIPELINE") != "1" and await repo.count() == 0:
        logger.info("startup: store empty, kicking off pipeline (in background)")
        asyncio.create_task(_boot_pipeline())
    yield

    await redis_cache.close()
    await mongo.close()


async def _boot_pipeline() -> None:
    try:
        stats = await Pipeline().run(limit=15, concurrency=3)
        logger.info("boot pipeline done: %s", stats)
    except Exception as e:  # noqa: BLE001
        logger.exception("boot pipeline failed: %s", e)


app = FastAPI(
    title=settings.APP_NAME,
    version="0.1.0",
    debug=settings.DEBUG,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": "0.1.0",
        "env": settings.APP_ENV,
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "time": datetime.utcnow().isoformat(),
        "mongo": mongo.is_connected(),
        "redis": redis_cache.is_connected(),
        "firebase": firebase.available(),
    }


app.include_router(articles.router, prefix=settings.API_V1_PREFIX)
app.include_router(trends.router, prefix=settings.API_V1_PREFIX)
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(admin.router, prefix=settings.API_V1_PREFIX)
app.include_router(notifications.router, prefix=settings.API_V1_PREFIX)
