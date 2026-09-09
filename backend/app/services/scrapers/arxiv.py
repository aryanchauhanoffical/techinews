"""arXiv API collector (keyless Atom). cs.AI / cs.LG / cs.CL, newest first."""
from __future__ import annotations

import logging
from typing import List

import feedparser
import httpx

from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, SourceType
from app.services.scrapers.rss import _clean, _published

logger = logging.getLogger(__name__)
SOURCE = ArticleSource(id="src_arxiv", name="arXiv", type=SourceType.arxiv)


class ArxivCollector:
    API = "https://export.arxiv.org/api/query"

    async def collect(self, limit: int = 25) -> List[Article]:
        params = {"search_query": "cat:cs.AI OR cat:cs.LG OR cat:cs.CL",
                  "sortBy": "submittedDate", "sortOrder": "descending", "max_results": limit}
        try:
            async with httpx.AsyncClient(timeout=25.0, follow_redirects=True) as c:
                r = await c.get(self.API, params=params)
                feed = feedparser.parse(r.content)
        except Exception as e:  # noqa: BLE001
            logger.info("arxiv failed: %s", e)
            return []
        out = []
        for e in feed.entries:
            link = e.get("link")
            if not link:
                continue
            authors = ", ".join(a.get("name", "") for a in e.get("authors", [])[:3])
            out.append(Article(
                id=make_article_id(link), title=_clean(e.get("title"), 300), url=link,
                source=SOURCE, author=authors or None, summary=_clean(e.get("summary")),
                published_at=_published(e), topics=["AI"], trend_score=30,
            ))
        logger.info("arxiv: %d papers", len(out))
        return out
