"""Feed service — reads enriched articles from the repository, applies
interests-first ranking, and caches feed pages in Redis (5-min TTL).
Search is delegated to the repository."""
from __future__ import annotations

from typing import List, Optional

from app.db import redis_cache
from app.schemas.article import Article
from app.services.article_repo import articles as repo


class FeedService:
    async def get_feed(
        self,
        page: int = 0,
        page_size: int = 20,
        interests: Optional[List[str]] = None,
        min_trend: int = 30,
    ) -> List[Article]:
        norm_interests = sorted({i.strip() for i in (interests or []) if i.strip()})
        cache_key = (
            f"feed:{page}:{page_size}:{min_trend}:{','.join(norm_interests)}"
        )
        cached = await redis_cache.get_json(cache_key)
        if cached is not None:
            return [Article(**d) for d in cached]

        # Candidates already trend-filtered + chronologically sorted by Mongo.
        items = await repo.feed_candidates(min_trend=min_trend)

        if norm_interests:
            terms = {t.lower() for t in norm_interests}

            def matches(a: Article) -> bool:
                bag = {x.lower() for x in (a.topics or []) + (a.companies or [])}
                if any(t in bag for t in terms):
                    return True
                # substring fallback so "AI" matches "Artificial Intelligence"
                for t in terms:
                    for x in bag:
                        if t in x or x in t:
                            return True
                return False

            interested = [a for a in items if matches(a)]
            interested_ids = {a.id for a in interested}
            others = [a for a in items if a.id not in interested_ids]
            items = interested + others

        start = page * page_size
        page_items = items[start : start + page_size]

        await redis_cache.set_json(
            cache_key, [a.model_dump(mode="json") for a in page_items], ttl=300
        )
        return page_items

    async def get_article(self, article_id: str) -> Optional[Article]:
        return await repo.get(article_id)

    async def search(self, query: str) -> List[Article]:
        return await repo.search(query)
