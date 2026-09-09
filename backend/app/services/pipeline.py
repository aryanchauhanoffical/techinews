"""End-to-end ingestion pipeline (v2 — keyless structured sources).

Stages:
  1. Collect   — RSS/Atom (press, lab blogs, newsletters, subreddits, GitHub
                 releases) + Hacker News + GitHub search + arXiv + HF papers/models
  2. Rank      — heuristic score + cross-source dedup (no LLM cost)
  3. Enrich    — top-N only: local extraction (trafilatura → Jina → Firecrawl),
                 Gemini structured summary, image resolution (OG → generated)
  4. Store     — upsert everything (ranked-but-unenriched items keep their
                 feed summary so the feed stays fresh at zero cost)

Idempotent on article ID (deterministic from URL); re-runs skip known IDs.
Designed to run as a cron (GitHub Actions) — no long-lived worker needed.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List

from app.schemas.article import Article
from app.services.ai.summarizer import Summarizer
from pymongo import UpdateOne

from app.services.article_repo import _from_doc, articles as repo
from app.services.extract import Extractor
from app.services.images import fill_missing_images, github_card, resolve_image
from app.services.ranking import rank
from app.services.scrapers.arxiv import ArxivCollector
from app.services.scrapers.github_trending import GithubCollector
from app.services.scrapers.hackernews import HackerNewsScraper
from app.services.scrapers.html_list import HtmlListCollector
from app.services.scrapers.bluesky import BlueskyCollector
from app.services.scrapers.reddit import RedditCollector
from app.services.scrapers.huggingface import HuggingFaceCollector
from app.services.scrapers.rss import RssCollector

logger = logging.getLogger(__name__)


class Pipeline:
    def __init__(self):
        self.rss = RssCollector()
        self.hn = HackerNewsScraper()
        self.github = GithubCollector()
        self.arxiv = ArxivCollector()
        self.hf = HuggingFaceCollector()
        self.listings = HtmlListCollector()
        self.bluesky = BlueskyCollector()
        self.reddit = RedditCollector()
        self.extractor = Extractor()
        self.summarizer = Summarizer()

    async def collect(self) -> List[Article]:
        tasks = [self.rss.collect(), self.hn.fetch_front_page(30), self.github.collect(),
                 self.arxiv.collect(), self.hf.collect(), self.listings.collect(), self.bluesky.collect(), self.reddit.collect()]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        items: List[Article] = []
        for r in results:
            if isinstance(r, Exception):
                logger.warning("collector failed: %s", r)
            else:
                items.extend(r)
        return items

    async def discover(self) -> List[Article]:
        """Collect → rank/dedup → drop already-stored IDs."""
        items = rank(await self.collect())
        existing = await repo.existing_ids()
        fresh = [a for a in items if a.id not in existing]
        logger.info("discover: %d collected, %d after dedup, %d new", len(items), len(items), len(fresh))
        return fresh

    async def enrich(self, article: Article) -> Article:
        try:
            content, og = await self.extractor.extract(article.url)
            base = content if len(content) > 200 else (article.summary or article.title)
            result = await self.summarizer.summarize(
                title=article.title, body=base, source_name=article.source.name)
            # Blend: heuristic ranker knows engagement, LLM knows significance.
            score = int(round(0.5 * article.trend_score + 0.5 * result.trend_score))
            topics = result.topics or article.topics
            image = await resolve_image(article.id, article.title, topics, score, article.image_url or github_card(article.url), og)
            logger.info("enriched: %r | text=%d score=%d img=%s", article.title[:60], len(content), score, bool(image))
            return article.model_copy(update={
                "summary": result.summary or article.summary,
                "key_points": result.key_points, "why_it_matters": result.why_it_matters,
                "topics": topics, "companies": result.companies, "stack": result.stack or article.stack,
                "trend_score": score, "image_url": image, "llm_score": result.trend_score,
                "body": content[:8000] if content else article.body,
            })
        except Exception as e:  # noqa: BLE001
            logger.exception("enrich failed for %s: %s", article.url, e)
            return article

    async def run(self, limit: int = 30, concurrency: int = 4, store_unenriched: bool = True) -> Dict[str, int]:
        t0 = datetime.utcnow()
        fresh = await self.discover()
        head, tail = fresh[:limit], fresh[limit:]
        sem = asyncio.Semaphore(concurrency)

        async def one(a: Article) -> Article:
            async with sem:
                return await self.enrich(a)

        enriched = list(await asyncio.gather(*[one(a) for a in head]))
        recovered = await fill_missing_images(tail) if store_unenriched else 0
        to_store = enriched + (tail if store_unenriched else [])
        added = await repo.upsert_many(to_store) if to_store else 0
        if added:
            from app.db import redis_cache
            await redis_cache.clear_prefix("feed:")

        rescored = await self.rescore_recent()

        # Uniqueness metric: how much of what we surfaced is NOT on the HN front page.
        hn_urls = {a.url for a in fresh if a.source.id == "src_hn"}
        non_hn = sum(1 for a in head if a.url not in hn_urls)
        stats = {
            "collected_new": len(fresh), "enriched": len(enriched), "stored": len(to_store),
            "added": added, "unique_vs_hn": non_hn, "images_recovered": recovered, "rescored": rescored, "store_size": await repo.count(),
            "duration_sec": int((datetime.utcnow() - t0).total_seconds()),
        }
        logger.info("pipeline run: %s", stats)
        await self._record_run(stats)
        return stats

    async def rescore_recent(self, window_days: int = 10, image_backfill: int = 40) -> int:
        """Scores decay with time and clusters grow as coverage arrives, so the
        recent window is re-ranked every run and written back. Also backfills
        images for a few older items each run so the archive fills in."""
        from app.db import mongo
        db = mongo.get_db()
        if db is None:
            return 0
        since = datetime.utcnow() - timedelta(days=window_days)
        recent = [_from_doc(d) async for d in db.articles.find({"published_at": {"$gte": since}})]
        if not recent:
            return 0
        ranked = rank(recent)
        missing = [a for a in ranked if not a.image_url]
        await fill_missing_images(missing, limit=image_backfill)
        imgs = {a.id: a.image_url for a in missing if a.image_url}
        ops = []
        for a in ranked:
            score = a.trend_score if a.llm_score is None else int(round(0.5 * a.trend_score + 0.5 * a.llm_score))
            upd = {"trend_score": min(100, score), "coverage": a.coverage, "related_ids": a.related_ids}
            if a.id in imgs:
                upd["image_url"] = imgs[a.id]
            ops.append(UpdateOne({"_id": a.id}, {"$set": upd}))
        if ops:
            await db.articles.bulk_write(ops, ordered=False)
        logger.info("rescored %d recent items, %d images backfilled", len(ops), len(imgs))
        return len(ops)

    async def _record_run(self, stats: Dict[str, int], interval_minutes: int = 60) -> None:
        from app.db import mongo
        db = mongo.get_db()
        if db is None:
            return
        now = datetime.utcnow()
        await db.meta.update_one({"_id": "pipeline"}, {"$set": {
            "last_run": now, "next_run": now + timedelta(minutes=interval_minutes),
            "interval_minutes": interval_minutes, **stats}}, upsert=True)
