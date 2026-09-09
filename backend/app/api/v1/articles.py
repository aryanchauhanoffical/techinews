from typing import List, Optional

from fastapi import APIRouter, Query

from app.schemas.article import Article, FeedResponse
from app.services.feed_service import FeedService

router = APIRouter(prefix="/articles", tags=["articles"])
service = FeedService()


@router.get("/feed", response_model=FeedResponse)
async def get_feed(
    page: int = Query(0, ge=0),
    page_size: int = Query(20, ge=1, le=50),
    interests: Optional[List[str]] = Query(None),
):
    items = await service.get_feed(page=page, page_size=page_size, interests=interests or [])
    return FeedResponse(items=items, next_page=page + 1 if len(items) == page_size else None)


@router.get("/meta")
async def feed_meta():
    """When the collector last ran and when it runs next (hourly cron)."""
    from app.db import mongo
    db = mongo.get_db()
    doc = await db.meta.find_one({"_id": "pipeline"}) if db is not None else None
    return doc or {"_id": "pipeline", "last_run": None, "next_run": None, "added": 0, "interval_minutes": 60}


@router.get("/search", response_model=List[Article])
async def search(q: str = Query(..., min_length=1)):
    return await service.search(q)


@router.get("/{article_id}", response_model=Article)
async def get_article(article_id: str):
    article = await service.get_article(article_id)
    if not article:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Article not found")
    return article
