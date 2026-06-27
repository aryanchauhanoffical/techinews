"""Admin endpoints (dev-only — gate with auth before going to prod)."""
from fastapi import APIRouter, Query

from app.db import mongo, redis_cache
from app.services.article_repo import articles as repo
from app.services.notifications import send_to_token
from app.services.pipeline import Pipeline

router = APIRouter(prefix="/admin", tags=["admin"])


@router.post("/pipeline/run")
async def run_pipeline(
    limit: int = Query(15, ge=1, le=50),
    concurrency: int = Query(3, ge=1, le=8),
):
    stats = await Pipeline().run(limit=limit, concurrency=concurrency)
    return stats


@router.get("/store")
async def store_status():
    return {
        "size": await repo.count(),
        "mongo": mongo.is_connected(),
        "redis": redis_cache.is_connected(),
    }


@router.post("/fcm/test")
async def fcm_test(token: str = Query(..., min_length=10)):
    """Send a test push to a single FCM device token."""
    try:
        message_id = send_to_token(
            token,
            title="TechiNews",
            body="🔔 Push notifications are working.",
            data={"type": "test"},
        )
        return {"ok": True, "message_id": message_id}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "error": str(e)}
