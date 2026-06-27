"""Async Redis cache helpers.

Best-effort: every operation degrades to a no-op / cache-miss if Redis is
unreachable, so a Redis outage slows the app down but never breaks it.
JSON is used as the serialization format (values are plain dict/list).
"""
from __future__ import annotations

import json
import logging
from typing import Any, Optional

from redis import asyncio as aioredis

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_redis: Optional[aioredis.Redis] = None

DEFAULT_TTL = 300  # 5 minutes


async def connect() -> Optional[aioredis.Redis]:
    global _redis
    try:
        _redis = aioredis.from_url(
            get_settings().REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
            socket_connect_timeout=8,
        )
        await _redis.ping()
        logger.info("Redis connected")
        return _redis
    except Exception as e:  # noqa: BLE001
        logger.warning("Redis unavailable (%s) — caching disabled", e)
        _redis = None
        return None


def is_connected() -> bool:
    return _redis is not None


async def get_json(key: str) -> Any | None:
    if _redis is None:
        return None
    try:
        raw = await _redis.get(key)
        return json.loads(raw) if raw else None
    except Exception as e:  # noqa: BLE001
        logger.debug("cache get failed for %s: %s", key, e)
        return None


async def set_json(key: str, value: Any, ttl: int = DEFAULT_TTL) -> None:
    if _redis is None:
        return
    try:
        await _redis.set(key, json.dumps(value), ex=ttl)
    except Exception as e:  # noqa: BLE001
        logger.debug("cache set failed for %s: %s", key, e)


async def clear_prefix(prefix: str) -> int:
    """Delete every key starting with `prefix`. Returns count removed."""
    if _redis is None:
        return 0
    removed = 0
    try:
        async for key in _redis.scan_iter(match=f"{prefix}*", count=200):
            await _redis.delete(key)
            removed += 1
    except Exception as e:  # noqa: BLE001
        logger.debug("cache clear_prefix failed for %s: %s", prefix, e)
    return removed


async def close() -> None:
    global _redis
    if _redis is not None:
        try:
            await _redis.aclose()
        except Exception:  # noqa: BLE001
            pass
    _redis = None
