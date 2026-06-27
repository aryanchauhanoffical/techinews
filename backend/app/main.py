import asyncio
import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import admin, articles, auth, trends
from app.core.config import get_settings
from app.services.pipeline import STORE, Pipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Auto-run pipeline once at startup if store is empty (and SKIP_BOOT_PIPELINE != 1).
    if STORE.size() == 0 and os.getenv("SKIP_BOOT_PIPELINE") != "1":
        logger.info("startup: store empty, kicking off pipeline (in background)")
        asyncio.create_task(_boot_pipeline())
    yield


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
    return {"status": "ok", "time": datetime.utcnow().isoformat()}


app.include_router(articles.router, prefix=settings.API_V1_PREFIX)
app.include_router(trends.router, prefix=settings.API_V1_PREFIX)
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(admin.router, prefix=settings.API_V1_PREFIX)
