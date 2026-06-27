"""Feed service — reads from the pipeline's article store + provides ranking
and search. The in-memory mock data has been retired; this serves real
articles produced by the Gemini pipeline."""
from __future__ import annotations

from typing import List, Optional

from app.schemas.article import Article
from app.services.pipeline import STORE


class FeedService:
    async def get_feed(
        self,
        page: int = 0,
        page_size: int = 20,
        interests: Optional[List[str]] = None,
        min_trend: int = 30,
    ) -> List[Article]:
        # Drop low-signal articles Gemini already flagged as borderline.
        items = [a for a in STORE.list_sorted() if a.trend_score >= min_trend]
        if interests:
            terms = {t.lower() for t in interests}
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
            others = [a for a in items if a not in interested]
            # interests-first, fall back to chronological for the rest
            items = interested + others
        start = page * page_size
        return items[start : start + page_size]

    async def get_article(self, article_id: str) -> Optional[Article]:
        return STORE.get(article_id)

    async def search(self, query: str) -> List[Article]:
        q = query.lower().strip()
        if not q:
            return []
        return [
            a
            for a in STORE.list_sorted()
            if q in a.title.lower()
            or (a.summary and q in a.summary.lower())
            or any(q in t.lower() for t in (a.topics or []))
            or any(q in c.lower() for c in (a.companies or []))
        ]
