"""Article repository — persistent store for enriched articles.

Primary backend is MongoDB (collection `articles`). When Mongo is not connected
(`app.db.mongo.get_db()` is None) every method falls back to a thread-safe
in-memory dict, so the pipeline and feed still work offline.

Documents use the deterministic `article.id` (see app.core.ids) as `_id`, so
upserts are idempotent on URL without a separate unique-key dance.
"""
from __future__ import annotations

from datetime import datetime, timedelta

import logging
import threading

from pymongo.errors import DuplicateKeyError
from typing import Dict, List, Optional

from app.db import mongo
from app.schemas.article import Article

logger = logging.getLogger(__name__)

# How many recent docs to pull as feed candidates before in-app ranking.
FEED_CANDIDATE_LIMIT = 500


def _to_doc(a: Article) -> dict:
    doc = a.model_dump(mode="json")
    doc["_id"] = doc.pop("id")
    # Keep published_at as a real datetime so Mongo sorts chronologically
    # (model_dump(mode="json") would stringify it).
    doc["published_at"] = a.published_at
    return doc


def _from_doc(doc: dict) -> Article:
    data = dict(doc)
    data["id"] = data.pop("_id")
    return Article(**data)


class ArticleRepository:
    def __init__(self, max_items: int = 500):
        self._mem: Dict[str, Article] = {}
        self._lock = threading.RLock()
        self.max_items = max_items

    # ---- writes -------------------------------------------------------------
    async def upsert_many(self, articles: List[Article]) -> int:
        db = mongo.get_db()
        if db is None:
            return self._mem_upsert(articles)
        added = 0
        for a in articles:
            doc = _to_doc(a)
            doc_id = doc.pop("_id")
            try:
                res = await db.articles.update_one(
                    {"_id": doc_id}, {"$set": doc}, upsert=True
                )
            except DuplicateKeyError:
                # Same URL already stored under a different id (e.g. an HN item
                # and the direct feed entry). Keep the first; skip this one.
                logger.info("skip duplicate url: %s", a.url)
                continue
            if res.upserted_id is not None:
                added += 1
        return added

    def _mem_upsert(self, articles: List[Article]) -> int:
        added = 0
        with self._lock:
            for a in articles:
                if a.id not in self._mem:
                    added += 1
                self._mem[a.id] = a
            if len(self._mem) > self.max_items:
                kept = sorted(
                    self._mem.items(),
                    key=lambda kv: kv[1].published_at,
                    reverse=True,
                )[: self.max_items]
                self._mem = dict(kept)
        return added

    # ---- reads --------------------------------------------------------------
    async def existing_ids(self) -> set[str]:
        db = mongo.get_db()
        if db is None:
            with self._lock:
                return set(self._mem.keys())
        ids = await db.articles.distinct("_id")
        return set(ids)

    async def feed_candidates(self, min_trend: int = 0, window_days: int = 10) -> List[Article]:
        """Recent items (last `window_days`), best first: trend_score desc, then newest.
        Enriched top stories therefore lead; the long tail of unenriched feed
        items fills in behind them."""
        since = datetime.utcnow() - timedelta(days=window_days)
        db = mongo.get_db()
        if db is None:
            with self._lock:
                items = [a for a in self._mem.values()
                         if a.trend_score >= min_trend and a.published_at >= since]
            return sorted(items, key=lambda a: (a.trend_score, a.published_at), reverse=True)
        cursor = (
            db.articles.find({"trend_score": {"$gte": min_trend}, "published_at": {"$gte": since}})
            .sort([("trend_score", -1), ("published_at", -1)])
            .limit(FEED_CANDIDATE_LIMIT)
        )
        return [_from_doc(d) async for d in cursor]

    async def get(self, article_id: str) -> Optional[Article]:
        db = mongo.get_db()
        if db is None:
            with self._lock:
                return self._mem.get(article_id)
        doc = await db.articles.find_one({"_id": article_id})
        return _from_doc(doc) if doc else None

    async def search(self, query: str, limit: int = 50) -> List[Article]:
        q = query.lower().strip()
        if not q:
            return []
        db = mongo.get_db()
        if db is None:
            with self._lock:
                pool = sorted(
                    self._mem.values(), key=lambda a: a.published_at, reverse=True
                )
            return [a for a in pool if _matches_text(a, q)][:limit]
        # Case-insensitive regex across the text-bearing fields. Fine at MVP
        # scale; Phase 11 swaps this for Typesense.
        rx = {"$regex": _escape_regex(q), "$options": "i"}
        cursor = (
            db.articles.find(
                {
                    "$or": [
                        {"title": rx},
                        {"summary": rx},
                        {"topics": rx},
                        {"companies": rx},
                    ]
                }
            )
            .sort("published_at", -1)
            .limit(limit)
        )
        return [_from_doc(d) async for d in cursor]

    async def count(self) -> int:
        db = mongo.get_db()
        if db is None:
            with self._lock:
                return len(self._mem)
        return await db.articles.count_documents({})


def _matches_text(a: Article, q: str) -> bool:
    return (
        q in a.title.lower()
        or (a.summary and q in a.summary.lower())
        or any(q in t.lower() for t in (a.topics or []))
        or any(q in c.lower() for c in (a.companies or []))
    )


def _escape_regex(s: str) -> str:
    import re

    return re.escape(s)


# Singleton shared across the process.
articles = ArticleRepository()
