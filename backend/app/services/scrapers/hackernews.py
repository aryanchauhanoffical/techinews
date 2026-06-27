"""Hacker News scraper using the public Algolia API. No key required."""
from datetime import datetime
from typing import List

import httpx

from app.schemas.article import Article, ArticleSource, SourceType

HN_SOURCE = ArticleSource(id="src_hn", name="Hacker News", type=SourceType.hacker_news)


class HackerNewsScraper:
    BASE = "https://hn.algolia.com/api/v1"

    async def fetch_front_page(self, limit: int = 30) -> List[Article]:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.get(
                f"{self.BASE}/search",
                params={"tags": "front_page", "hitsPerPage": limit},
            )
            r.raise_for_status()
            hits = r.json().get("hits", [])

        out: List[Article] = []
        for h in hits:
            if not h.get("title") or not h.get("url"):
                continue
            out.append(
                Article(
                    id=f"hn_{h['objectID']}",
                    title=h["title"],
                    url=h["url"],
                    source=HN_SOURCE,
                    author=h.get("author"),
                    published_at=datetime.fromtimestamp(h["created_at_i"]),
                    trend_score=min(100, (h.get("points") or 0) // 5),
                )
            )
        return out
