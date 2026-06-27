"""NewsAPI.org client — discovers tech headlines + URLs to feed downstream."""
from __future__ import annotations

from datetime import datetime
from typing import List, Optional

import httpx

from app.core.config import get_settings
from app.schemas.article import Article, ArticleSource, SourceType

# Map domain → friendly source for nicer attribution in the UI.
_SOURCE_OVERRIDES = {
    "techcrunch.com": "TechCrunch",
    "theverge.com": "The Verge",
    "arstechnica.com": "Ars Technica",
    "wired.com": "Wired",
    "engadget.com": "Engadget",
    "venturebeat.com": "VentureBeat",
    "9to5mac.com": "9to5Mac",
    "macrumors.com": "MacRumors",
    "bloomberg.com": "Bloomberg",
    "reuters.com": "Reuters",
    "bbc.com": "BBC",
    "bbc.co.uk": "BBC",
    "wsj.com": "WSJ",
    "nytimes.com": "The New York Times",
    "ft.com": "Financial Times",
}


class NewsApiScraper:
    BASE = "https://newsapi.org/v2"

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or get_settings().NEWSAPI_KEY

    async def fetch_top_tech(
        self,
        page_size: int = 30,
        country: str = "us",
    ) -> List[Article]:
        """Top tech headlines via NewsAPI /top-headlines."""
        params = {
            "category": "technology",
            "language": "en",
            "country": country,
            "pageSize": min(100, page_size),
            "apiKey": self.api_key,
        }
        async with httpx.AsyncClient(timeout=20) as c:
            r = await c.get(f"{self.BASE}/top-headlines", params=params)
            r.raise_for_status()
        return [_to_article(h) for h in r.json().get("articles", []) if _valid(h)]

    async def search_everything(
        self,
        query: str,
        page_size: int = 30,
        sort_by: str = "publishedAt",  # publishedAt | popularity | relevancy
        from_iso: Optional[str] = None,
    ) -> List[Article]:
        """Full-text search via NewsAPI /everything."""
        params = {
            "q": query,
            "language": "en",
            "pageSize": min(100, page_size),
            "sortBy": sort_by,
            "apiKey": self.api_key,
        }
        if from_iso:
            params["from"] = from_iso
        async with httpx.AsyncClient(timeout=20) as c:
            r = await c.get(f"{self.BASE}/everything", params=params)
            r.raise_for_status()
        return [_to_article(h) for h in r.json().get("articles", []) if _valid(h)]


def _valid(h: dict) -> bool:
    return bool(h.get("title")) and bool(h.get("url"))


def _domain(url: str) -> str:
    try:
        from urllib.parse import urlparse
        host = urlparse(url).netloc.lower()
        return host[4:] if host.startswith("www.") else host
    except Exception:
        return ""


def _to_article(h: dict) -> Article:
    url = h["url"]
    domain = _domain(url)
    source_name = _SOURCE_OVERRIDES.get(domain) or (h.get("source") or {}).get("name") or domain or "Web"
    published = h.get("publishedAt")
    try:
        published_dt = datetime.fromisoformat(published.replace("Z", "+00:00")) if published else datetime.utcnow()
    except Exception:
        published_dt = datetime.utcnow()
    return Article(
        id=f"newsapi_{abs(hash(url))}",
        title=h["title"],
        summary=h.get("description"),
        body=h.get("content"),
        image_url=h.get("urlToImage"),
        url=url,
        source=ArticleSource(
            id=f"src_{domain or 'web'}",
            name=source_name,
            type=SourceType.news,
        ),
        author=h.get("author"),
        published_at=published_dt,
    )
