"""End-to-end ingestion pipeline.

Stages:
  1. Discover  — NewsAPI top tech headlines + topic searches
  2. Extract   — Jina Reader pulls clean markdown; Firecrawl fallback
  3. Summarize — Gemini structured JSON: summary, key points, why-it-matters, tags
  4. Store     — keep newest N articles in an in-memory list (Mongo-backed later)

Idempotent on article URL — re-running won't duplicate.
"""
from __future__ import annotations

import asyncio
import logging
import threading
from datetime import datetime
from typing import Dict, List, Optional

from app.schemas.article import Article
from app.services.ai.summarizer import Summarizer
from app.services.scrapers.firecrawl import Firecrawl
from app.services.scrapers.jina_reader import JinaReader
from app.services.scrapers.newsapi import NewsApiScraper

logger = logging.getLogger(__name__)


# Topic queries — replace NewsAPI's noisy `category=technology` (which leaks
# sports/entertainment) with focused full-text searches.
TOPIC_QUERIES = [
    "artificial intelligence OR LLM OR OpenAI OR Anthropic",
    "(startup OR YC OR Y Combinator) AND (funding OR raised OR Series A OR Series B OR Series C)",
    "open source OR GitHub trending OR developer tools",
    "cybersecurity OR data breach OR vulnerability",
    "AI agents OR autonomous agents OR coding assistant",
    "Apple OR Google OR Microsoft OR NVIDIA OR Meta",
    "venture capital OR acquisition tech",
]


class ArticleStore:
    """Tiny thread-safe in-memory article cache. Swap with Mongo later."""

    def __init__(self, max_items: int = 200):
        self._items: Dict[str, Article] = {}
        self._lock = threading.RLock()
        self.max_items = max_items

    def upsert_many(self, articles: List[Article]) -> int:
        added = 0
        with self._lock:
            for a in articles:
                key = a.url
                if key not in self._items:
                    added += 1
                self._items[key] = a
            # Trim oldest if over capacity
            if len(self._items) > self.max_items:
                sorted_items = sorted(
                    self._items.items(),
                    key=lambda kv: kv[1].published_at,
                    reverse=True,
                )[: self.max_items]
                self._items = dict(sorted_items)
        return added

    def list_sorted(self) -> List[Article]:
        with self._lock:
            return sorted(self._items.values(), key=lambda a: a.published_at, reverse=True)

    def get(self, article_id: str) -> Optional[Article]:
        with self._lock:
            for a in self._items.values():
                if a.id == article_id:
                    return a
            return None

    def size(self) -> int:
        with self._lock:
            return len(self._items)


# Singleton store shared across the process.
STORE = ArticleStore()


class Pipeline:
    def __init__(self):
        self.news = NewsApiScraper()
        self.jina = JinaReader()
        self.firecrawl = Firecrawl()
        self.summarizer = Summarizer()

    async def discover(self, per_query: int = 8) -> List[Article]:
        """Pull headlines via NewsAPI topic searches (focused queries beat
        the broad `category=technology` feed, which leaks sports/entertainment)."""
        tasks = [
            self.news.search_everything(q, page_size=per_query)
            for q in TOPIC_QUERIES
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        seen: set[str] = set()
        deduped: List[Article] = []
        for r in results:
            if isinstance(r, Exception):
                logger.warning("discover task failed: %s", r)
                continue
            for a in r:
                if a.url in seen:
                    continue
                seen.add(a.url)
                deduped.append(a)
        # Drop ones we've already processed in a previous run
        existing = {a.url for a in STORE.list_sorted()}
        return [a for a in deduped if a.url not in existing]

    async def extract(self, article: Article) -> str:
        """Try Jina first (fast + free), fall back to Firecrawl."""
        text = await self.jina.extract(article.url)
        if text and len(text) > 400:
            return text
        text = await self.firecrawl.scrape(article.url)
        return text or ""

    async def enrich(self, article: Article) -> Article:
        """Run extract + summarize for one article."""
        try:
            content = await self.extract(article)
            ext_len = len(content) if content else 0
            base = content if ext_len > 200 else (article.body or article.summary or article.title)
            result = await self.summarizer.summarize(
                title=article.title,
                body=base or article.title,
                source_name=article.source.name,
            )
            logger.info(
                "enriched: %r | extract=%d ai_summary=%d topics=%d trend=%d",
                article.title[:70], ext_len,
                len(result.summary), len(result.topics), result.trend_score,
            )
            return article.model_copy(
                update={
                    "summary": result.summary or article.summary,
                    "key_points": result.key_points,
                    "why_it_matters": result.why_it_matters,
                    "topics": result.topics,
                    "companies": result.companies,
                    "stack": result.stack,
                    "trend_score": result.trend_score,
                    "body": (content[:8000] if content else article.body),
                }
            )
        except Exception as e:  # noqa: BLE001
            logger.exception("enrich failed for %s: %s", article.url, e)
            return article

    async def run(self, limit: int = 20, concurrency: int = 4) -> Dict[str, int]:
        """End-to-end run. Returns stats dict."""
        t0 = datetime.utcnow()
        discovered = await self.discover()
        logger.info("discover -> %d new articles", len(discovered))

        to_process = discovered[:limit]
        sem = asyncio.Semaphore(concurrency)

        async def _one(a: Article) -> Article:
            async with sem:
                return await self.enrich(a)

        enriched = await asyncio.gather(*[_one(a) for a in to_process])
        added = STORE.upsert_many(enriched)
        dt = (datetime.utcnow() - t0).total_seconds()
        stats = {
            "discovered": len(discovered),
            "processed": len(enriched),
            "added": added,
            "store_size": STORE.size(),
            "duration_sec": int(dt),
        }
        logger.info("pipeline run: %s", stats)
        return stats
