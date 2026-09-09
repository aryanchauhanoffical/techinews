"""Listing-page collector for sites with no feed (Anthropic, Meta AI).

Fetches one index page, pulls post links by regex, then reads og:title /
og:image / published date from each of the newest few posts. Cheap: one
index request + ≤ N page requests per source per run."""
from __future__ import annotations

import asyncio
import html as _html
import logging
import re
from datetime import datetime, timedelta
from typing import List, Optional, Tuple

import httpx

from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, SourceType

logger = logging.getLogger(__name__)
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) TechiNews/0.2"

# (source_id, name, index_url, link_regex, url_prefix_for_relative_links)
LISTINGS: List[Tuple[str, str, str, str, str]] = [
    ("anthropic_news", "Anthropic", "https://www.anthropic.com/news",
     r'href="(/news/[a-z0-9-]+)"', "https://www.anthropic.com"),
    ("meta_ai_blog", "Meta AI", "https://ai.meta.com/blog/",
     r'href="((?:https://ai\.meta\.com)?/blog/[a-z0-9-]+/?)"', "https://ai.meta.com"),
]
_META = {
    "title": re.compile(r'<meta[^>]+property="og:title"[^>]+content="([^"]+)"', re.I),
    "image": re.compile(r'<meta[^>]+property="og:image"[^>]+content="([^"]+)"', re.I),
    "desc": re.compile(r'<meta[^>]+(?:property="og:description"|name="description")[^>]+content="([^"]+)"', re.I),
    "date": re.compile(r'<meta[^>]+property="article:published_time"[^>]+content="([^"]+)"', re.I),
    "html_title": re.compile(r"<title>([^<]+)</title>", re.I),
}


def _slug_title(url: str) -> str:
    return url.rstrip("/").rsplit("/", 1)[-1].replace("-", " ").title()


class HtmlListCollector:
    def __init__(self, per_source: int = 8):
        self.per_source = per_source

    async def _page(self, c: httpx.AsyncClient, url: str) -> dict:
        try:
            r = await c.get(url)
            html = r.text if r.status_code == 200 else ""
        except Exception:  # noqa: BLE001
            html = ""
        out = {}
        for k, rx in _META.items():
            m = rx.search(html)
            out[k] = _html.unescape(m.group(1).strip()) if m else None
        return out

    async def collect(self) -> List[Article]:
        out: List[Article] = []
        async with httpx.AsyncClient(timeout=20.0, follow_redirects=True, headers={"User-Agent": UA}) as c:
            for sid, name, index, rx, base in LISTINGS:
                try:
                    r = await c.get(index)
                    if r.status_code != 200:
                        logger.info("listing %s -> %s", sid, r.status_code)
                        continue
                    links, seen = [], set()
                    for m in re.finditer(rx, r.text):
                        href = m.group(1)
                        url = href if href.startswith("http") else base + href
                        url = url.rstrip("/")
                        if url not in seen:
                            seen.add(url)
                            links.append(url)
                    links = links[: self.per_source]
                    metas = await asyncio.gather(*[self._page(c, u) for u in links])
                except Exception as e:  # noqa: BLE001
                    logger.info("listing %s failed: %s", sid, e)
                    continue
                source = ArticleSource(id=sid, name=name, type=SourceType.blog)
                for url, meta in zip(links, metas):
                    # Unknown date → neutral recency (2 days) rather than a fake "just now" boost.
                    published = datetime.utcnow() - timedelta(days=2)
                    if meta.get("date"):
                        try:
                            published = datetime.fromisoformat(meta["date"].rstrip("Z").split("+")[0])
                        except ValueError:
                            pass
                    out.append(Article(
                        id=make_article_id(url), title=meta.get("title") or (meta.get("html_title") or "").split(" | ")[0].split(" \\ ")[0] or _slug_title(url), url=url,
                        source=source, summary=meta.get("desc"), image_url=meta.get("image"),
                        published_at=published, trend_score=55,
                    ))
        logger.info("html_list: %d items", len(out))
        return out
