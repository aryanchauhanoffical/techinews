"""GitHub discovery via the REST search API (5k req/h with a token).

'Trending' proxy: repos created in the last N days that already crossed a
star threshold, plus AI-topic repos pushed recently. Each becomes a `github`
article and also populates `related_repos` with itself."""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List

import httpx

from app.core.config import get_settings
from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, GithubRepo, SourceType

logger = logging.getLogger(__name__)
SOURCE = ArticleSource(id="src_github", name="GitHub", type=SourceType.github)
_BLOCK = ("undress", "nsfw", "porn", "nude", "hentai", "onlyfans", "deepnude", "sex")


class GithubCollector:
    API = "https://api.github.com/search/repositories"

    def __init__(self, days: int = 7, min_stars: int = 150, per_query: int = 15):
        self.days, self.min_stars, self.per_query = days, min_stars, per_query

    def _queries(self) -> List[str]:
        since = (datetime.utcnow() - timedelta(days=self.days)).strftime("%Y-%m-%d")
        return [
            f"created:>{since} stars:>={self.min_stars}",
            f"created:>{since} stars:>={self.min_stars // 3} topic:llm",
            f"created:>{since} stars:>={self.min_stars // 3} topic:ai-agents",
            f"created:>{since} stars:>={self.min_stars // 3} topic:mcp",
        ]

    async def collect(self) -> List[Article]:
        token = get_settings().GITHUB_TOKEN
        headers = {"Accept": "application/vnd.github+json", "User-Agent": "TechiNews/0.2"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        out, seen = [], set()
        async with httpx.AsyncClient(timeout=20.0, headers=headers) as c:
            async def run(q: str):
                try:
                    r = await c.get(self.API, params={"q": q, "sort": "stars", "order": "desc",
                                                      "per_page": self.per_query})
                    return r.json().get("items", []) if r.status_code == 200 else []
                except Exception as e:  # noqa: BLE001
                    logger.info("github query failed: %s", e)
                    return []
            results = await asyncio.gather(*[run(q) for q in self._queries()])
        for items in results:
            for it in items:
                if it["id"] in seen:
                    continue
                seen.add(it["id"])
                desc = (it.get("description") or "").strip()
                if any(b in f"{it['full_name']} {desc}".lower() for b in _BLOCK):
                    continue
                repo = GithubRepo(
                    id=f"gh_{it['id']}", full_name=it["full_name"], description=desc,
                    url=it["html_url"], language=it.get("language"),
                    stars=it.get("stargazers_count", 0), forks=it.get("forks_count", 0),
                    last_commit=datetime.fromisoformat(it["pushed_at"].rstrip("Z")) if it.get("pushed_at") else None,
                )
                stars = repo.stars
                out.append(Article(
                    id=make_article_id(it["html_url"]),
                    title=f"{it['full_name']}: {desc[:120]}" if desc else it["full_name"],
                    summary=desc or None, url=it["html_url"], source=SOURCE,
                    author=it["owner"]["login"], image_url=it["owner"].get("avatar_url"),
                    published_at=datetime.fromisoformat(it["created_at"].rstrip("Z")),
                    topics=["Open Source"] + (["AI"] if any(t in (it.get("topics") or []) for t in ("llm", "ai", "ai-agents", "mcp", "machine-learning")) else []),
                    stack=[repo.language] if repo.language else [],
                    trend_score=min(95, 40 + stars // 40),
                    related_repos=[repo],
                ))
        logger.info("github: %d repos", len(out))
        return out
