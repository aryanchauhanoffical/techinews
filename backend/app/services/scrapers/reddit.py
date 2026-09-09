"""Reddit top posts via Zyte's browser render.

Reddit answers 403 to its own JSON endpoint and serves an interstitial to any
plain HTML fetch (verified; see the user's reddit.py notes). Zyte renders the
subreddit page like a browser; each <shreddit-post> element carries the post
as attributes, so one render gives ~100 posts with score, comment count and
the outbound link. One render per subreddit per run; RSS remains the fallback
when no key is configured.
"""
from __future__ import annotations

import asyncio
import base64
import html as _html
import logging
import re
from datetime import datetime
from typing import List, Optional

import httpx

from app.core.config import get_settings
from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, SourceType

logger = logging.getLogger(__name__)

# (source id, subreddit, weight)
SUBREDDITS = [
    ("r_localllama", "LocalLLaMA", 1.0),
    ("r_ml", "MachineLearning", 0.9),
    ("r_artificial", "artificial", 0.7),
    ("r_programming", "programming", 0.7),
]

_POST = re.compile(r"<shreddit-post\b([^>]*)>", re.S)
_ATTR = re.compile(r'([a-z-]+)="([^"]*)"')
_IMG_HOSTS = ("i.redd.it", "preview.redd.it", "i.imgur.com")


def _attrs(tag: str) -> dict:
    return {k: _html.unescape(v) for k, v in _ATTR.findall(tag)}


def _when(v: Optional[str]) -> datetime:
    try:
        return datetime.fromisoformat((v or "").replace("Z", "+00:00")).replace(tzinfo=None)
    except Exception:  # noqa: BLE001
        return datetime.utcnow()


def parse_posts(html: str, sid: str, sub: str, weight: float, limit: int) -> List[Article]:
    source = ArticleSource(id=sid, name=f"r/{sub}", type=SourceType.reddit)
    out: List[Article] = []
    seen: set = set()
    for tag in _POST.findall(html):
        a = _attrs(tag)
        title = (a.get("post-title") or "").strip()
        permalink = a.get("permalink") or ""
        if not title or not permalink or permalink in seen:
            continue
        seen.add(permalink)
        reddit_url = f"https://www.reddit.com{permalink}"
        href = a.get("content-href") or ""
        external = href and "reddit.com" not in href and "v.redd.it" not in href and not href.startswith("/")
        image = href if external and any(h in href for h in _IMG_HOSTS) else None
        url = href if external and not image else reddit_url
        score = int(a.get("score") or 0)
        comments = int(a.get("comment-count") or 0)
        out.append(Article(
            id=make_article_id(url), title=title[:300], url=url, source=source,
            author=a.get("author"),
            summary=None,
            image_url=image,
            published_at=_when(a.get("created-timestamp")),
            trend_score=int(40 * weight + min(score, 1500) / 30 + min(comments, 400) / 20),
            discussions=[],
        ))
        if len(out) >= limit:
            break
    return out


class RedditCollector:
    def __init__(self, subreddits=None, per_sub: int = 12):
        self.subs = list(subreddits) if subreddits is not None else SUBREDDITS
        self.per_sub = per_sub

    async def _render(self, client: httpx.AsyncClient, key: str, url: str) -> Optional[str]:
        try:
            r = await client.post(
                "https://api.zyte.com/v1/extract", auth=(key, ""),
                json={"url": url, "browserHtml": True, "geolocation": "US"},
            )
            if r.status_code != 200:
                logger.info("zyte %s -> %s %s", url, r.status_code, r.text[:120])
                return None
            return r.json().get("browserHtml")
        except Exception as e:  # noqa: BLE001
            logger.info("zyte %s failed: %s", url, e)
            return None

    async def collect(self) -> List[Article]:
        key = get_settings().ZYTE_API_KEY
        if not key:
            logger.info("reddit: no ZYTE_API_KEY, relying on RSS feeds")
            return []
        sem = asyncio.Semaphore(2)
        async with httpx.AsyncClient(timeout=180.0) as client:
            async def one(sid, sub, weight):
                async with sem:
                    html = await self._render(client, key, f"https://www.reddit.com/r/{sub}/top/?t=day")
                    if not html or "<shreddit-post" not in html:
                        return []
                    return parse_posts(html, sid, sub, weight, self.per_sub)
            results = await asyncio.gather(*[one(*s) for s in self.subs], return_exceptions=True)
        items = [a for r in results if not isinstance(r, Exception) for a in r]
        logger.info("reddit: %d posts from %d subreddits via zyte", len(items), len(self.subs))
        return items
