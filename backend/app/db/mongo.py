"""Async MongoDB (Motor) connection lifecycle + index setup.

Connection is best-effort: if Mongo is unreachable the app still boots, and
repositories transparently fall back to an in-memory store. This keeps local
dev and tests working without a database.
"""
from __future__ import annotations

import logging

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def connect() -> AsyncIOMotorDatabase | None:
    """Connect + verify with a ping. Returns the db handle, or None on failure."""
    global _client, _db
    settings = get_settings()
    try:
        _client = AsyncIOMotorClient(
            settings.MONGO_URI,
            serverSelectionTimeoutMS=8000,
            uuidRepresentation="standard",
        )
        await _client.admin.command("ping")
        _db = _client[settings.MONGO_DB]
        await ensure_indexes()
        logger.info("MongoDB connected: db=%s", settings.MONGO_DB)
        return _db
    except Exception as e:  # noqa: BLE001
        logger.warning("MongoDB unavailable (%s) — falling back to in-memory store", e)
        _client = None
        _db = None
        return None


async def ensure_indexes() -> None:
    if _db is None:
        return
    await _db.articles.create_index("url", unique=True)
    await _db.articles.create_index([("published_at", -1)])
    await _db.articles.create_index([("trend_score", -1)])
    await _db.articles.create_index("topics")
    await _db.users.create_index("uid", unique=True)
    await _db.users.create_index("email")


def get_db() -> AsyncIOMotorDatabase | None:
    return _db


def is_connected() -> bool:
    return _db is not None


async def close() -> None:
    global _client, _db
    if _client is not None:
        _client.close()
    _client = None
    _db = None
