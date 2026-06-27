"""Admin endpoints (dev-only — gate with auth before going to prod)."""
from fastapi import APIRouter, Query

from app.services.pipeline import STORE, Pipeline

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
    return {"size": STORE.size()}
