"""Generic RSS/Atom collector. Keyless. Covers press, lab blogs, newsletters,
subreddit feeds and GitHub release feeds — anything that publishes a feed."""
from __future__ import annotations

import asyncio
import html as _html
import logging
import re
from datetime import datetime, timezone
from time import mktime
from typing import Iterable, List, Optional, Tuple

import feedparser
import httpx

from app.core.config import get_settings
from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, SourceType
from app.services.sources import DEFAULT_FEEDS, RELEASE_REPOS, YOUTUBE_CHANNELS

logger = logging.getLogger(__name__)

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) TechiNews/0.2 (+https://github.com/aryanchauhanoffical/techinews)"
_TAG_RE = re.compile(r"<[^>]+>")
_WS_RE = re.compile(r"\s+")

FeedSpec = Tuple[str, str, str, SourceType, float]


def _clean(html: Optional[str], limit: int = 600) -> Optional[str]:
    if not html:
        return None
    text = _WS_RE.sub(" ", _TAG_RE.sub(" ", _html.unescape(html))).strip()
    return text[:limit] or None


def _published(entry) -> datetime:
    for key in ("published_parsed", "updated_parsed"):
        t = entry.get(key)
        if t:
            return datetime.fromtimestamp(mktime(t), tz=timezone.utc).replace(tzinfo=None)
    return datetime.utcnow()


def _image(entry) -> Optional[str]:
    for m in entry.get("media_content", []) or []:
        if m.get("url") and (m.get("medium") == "image" or "image" in (m.get("type") or "")):
            return m["url"]
    for m in entry.get("media_thumbnail", []) or []:
        if m.get("url"):
            return m["url"]
    for e in entry.get("enclosures", []) or []:
        if "image" in (e.get("type") or "") and e.get("href"):
            return e["href"]
    html = entry.get("summary") or ""
    m = re.search(r'<img[^>]+src="([^"]+)"', html)
    return m.group(1) if m else None


def release_feeds() -> List[FeedSpec]:
    return [
        (f"gh_rel_{r.replace('/', '_')}", f"{r} releases",
         f"https://github.com/{r}/releases.atom", SourceType.github, 1.0)
        for r in RELEASE_REPOS
    ]


def youtube_feeds() -> List[FeedSpec]:
    return [
        (f"yt_{cid}", name, f"https://www.youtube.com/feeds/videos.xml?channel_id={cid}", SourceType.youtube, 0.9)
        for name, cid in YOUTUBE_CHANNELS
    ]


class RssCollector:
    def __init__(self, feeds: Optional[Iterable[FeedSpec]] = None, per_feed: int = 15):
        self.feeds = list(feeds) if feeds is not None else DEFAULT_FEEDS + release_feeds() + youtube_feeds()
        self.per_feed = per_feed

    async def _fetch(self, client: httpx.AsyncClient, spec: FeedSpec) -> List[Article]:
        sid, name, url, stype, weight = spec
        try:
            r = await client.get(url, headers={"User-Agent": UA}, follow_redirects=True)
            if r.status_code != 200:
                logger.info("feed %s -> %s", sid, r.status_code)
                return []
            parsed = feedparser.parse(r.content)
        except Exception as e:  # noqa: BLE001
            logger.info("feed %s failed: %s", sid, e)
            return []
        source = ArticleSource(id=sid, name=name, type=stype)
        out: List[Article] = []
        limit = 3 if stype == SourceType.youtube else self.per_feed
        for e in parsed.entries[:limit]:
            link, title = e.get("link"), _clean(e.get("title"), 300)
            if not link or not title or title.startswith("Quoting "):
                continue
            if stype == SourceType.github and name.endswith(" releases"):
                # Release feeds also list branch/CI tags (pytorch: "ciflow/trunk/…"). Keep real releases only.
                if "/" in title or not re.search(r"\d", title):
                    continue
                title = f"{name[:-9]} {title}"  # 'ollama/ollama v0.33.1' instead of 'v0.33.1'
            out.append(Article(
                id=make_article_id(link), title=title, url=link, source=source,
                author=_clean(e.get("author"), 80),
                summary=_clean(e.get("summary") or e.get("description") or e.get("media_description")),
                image_url=_image(e), published_at=_published(e),
                # provisional score; ranker refines it
                trend_score=int(40 * weight),
            ))
        return out

    async def collect(self, concurrency: int = 8) -> List[Article]:
        """Parallel for everything except reddit, which rate-limits bursts per IP
        (serialized with a short gap instead)."""
        sem = asyncio.Semaphore(concurrency)
        fast = [f for f in self.feeds if "reddit.com" not in f[2]]
        slow = [f for f in self.feeds if "reddit.com" in f[2]]
        if get_settings().ZYTE_API_KEY:
            slow = []  # RedditCollector covers these via Zyte; RSS only when keyless
        async with httpx.AsyncClient(timeout=20.0) as client:
            async def one(spec):
                async with sem:
                    return await self._fetch(client, spec)

            async def serial():
                out = []
                for spec in slow:
                    out.extend(await self._fetch(client, spec))
                    await asyncio.sleep(6)
                return out

            results = await asyncio.gather(*[one(s) for s in fast], serial())
        items = [a for r in results for a in r]
        logger.info("rss: %d items from %d feeds", len(items), len(self.feeds))
        return items
