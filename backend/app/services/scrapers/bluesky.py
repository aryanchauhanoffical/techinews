"""Bluesky collector. Public AT Protocol API, no auth, no key.

Researchers and builders who left X post here. A post that carries an
external link becomes a story about that link, with the post text as the
summary and likes+reposts as the engagement signal. Plain posts without a
link are skipped: a feed of opinions is not news.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime
from typing import List

import httpx

from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, SourceType
from app.services.sources import BLUESKY_ACCOUNTS

logger = logging.getLogger(__name__)

API = "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed"
_SKIP_HOSTS = ("bsky.app", "twitter.com", "x.com", "instagram.com", "tiktok.com")


def _when(iso: str) -> datetime:
    try:
        return datetime.fromisoformat(iso.replace("Z", "+00:00")).replace(tzinfo=None)
    except Exception:  # noqa: BLE001
        return datetime.utcnow()


class BlueskyCollector:
    def __init__(self, accounts=None, per_account: int = 20, weight: float = 0.9):
        self.accounts = list(accounts) if accounts is not None else BLUESKY_ACCOUNTS
        self.per_account = per_account
        self.weight = weight

    async def _one(self, client: httpx.AsyncClient, name: str, handle: str) -> List[Article]:
        try:
            r = await client.get(API, params={"actor": handle, "limit": self.per_account, "filter": "posts_no_replies"})
            if r.status_code != 200:
                logger.info("bluesky %s -> %s", handle, r.status_code)
                return []
            feed = r.json().get("feed", [])
        except Exception as e:  # noqa: BLE001
            logger.info("bluesky %s failed: %s", handle, e)
            return []
        source = ArticleSource(id=f"bsky_{handle}", name=name, type=SourceType.bluesky)
        out: List[Article] = []
        for item in feed:
            post = item.get("post") or {}
            if item.get("reason"):  # repost, not the author's own link
                continue
            embed = post.get("embed") or {}
            ext = embed.get("external") if embed.get("$type", "").startswith("app.bsky.embed.external") else None
            if not ext or not ext.get("uri"):
                continue
            url = ext["uri"]
            if any(h in url for h in _SKIP_HOSTS):
                continue
            record = post.get("record") or {}
            text = (record.get("text") or "").strip()
            title = (ext.get("title") or "").strip() or text[:140]
            if len(title) < 12:
                continue
            likes = int(post.get("likeCount") or 0) + int(post.get("repostCount") or 0)
            out.append(Article(
                id=make_article_id(url), title=title[:300], url=url, source=source,
                author=name,
                summary=(text or ext.get("description") or "")[:600] or None,
                image_url=ext.get("thumb"),
                published_at=_when(record.get("createdAt") or post.get("indexedAt") or ""),
                trend_score=int(40 * self.weight + min(likes, 300) / 6),
            ))
        return out

    async def collect(self) -> List[Article]:
        async with httpx.AsyncClient(timeout=15.0, headers={"User-Agent": "TechiNews/0.2"}) as client:
            results = await asyncio.gather(*[self._one(client, n, h) for n, h in self.accounts], return_exceptions=True)
        items = [a for r in results if not isinstance(r, Exception) for a in r]
        logger.info("bluesky: %d linked posts from %d accounts", len(items), len(self.accounts))
        return items
