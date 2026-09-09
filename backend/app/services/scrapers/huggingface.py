"""Hugging Face daily papers + trending models (keyless; HF_TOKEN optional)."""
from __future__ import annotations

import logging
from datetime import datetime
from typing import List

import httpx

from app.core.config import get_settings
from app.core.ids import make_article_id
from app.schemas.article import Article, ArticleSource, SourceType

logger = logging.getLogger(__name__)
PAPERS = ArticleSource(id="src_hf_papers", name="HF Daily Papers", type=SourceType.huggingface)
MODELS = ArticleSource(id="src_hf_models", name="HF Trending Models", type=SourceType.huggingface)


class HuggingFaceCollector:
    async def collect(self, papers: int = 20, models: int = 15) -> List[Article]:
        headers = {"User-Agent": "TechiNews/0.2"}
        if get_settings().HF_TOKEN:
            headers["Authorization"] = f"Bearer {get_settings().HF_TOKEN}"
        out: List[Article] = []
        async with httpx.AsyncClient(timeout=20.0, headers=headers) as c:
            try:
                r = await c.get("https://huggingface.co/api/daily_papers", params={"limit": papers})
                for it in r.json() if r.status_code == 200 else []:
                    p = it.get("paper") or {}
                    pid = p.get("id")
                    if not pid:
                        continue
                    url = f"https://huggingface.co/papers/{pid}"
                    ups = p.get("upvotes") or 0
                    out.append(Article(
                        id=make_article_id(url), title=p.get("title") or pid, url=url, source=PAPERS,
                        summary=(p.get("summary") or "")[:600] or None,
                        image_url=it.get("thumbnail"),
                        published_at=datetime.fromisoformat((it.get("publishedAt") or p.get("publishedAt") or datetime.utcnow().isoformat()).rstrip("Z").split(".")[0]),
                        topics=["AI"], trend_score=min(90, 30 + ups * 2),
                    ))
            except Exception as e:  # noqa: BLE001
                logger.info("hf papers failed: %s", e)
            try:
                r = await c.get("https://huggingface.co/api/models",
                                params={"sort": "trendingScore", "direction": -1, "limit": models})
                for it in r.json() if r.status_code == 200 else []:
                    mid = it.get("id") or it.get("modelId")
                    if not mid:
                        continue
                    url = f"https://huggingface.co/{mid}"
                    out.append(Article(
                        id=make_article_id(url), title=f"Trending model: {mid}", url=url, source=MODELS,
                        summary=f"{it.get('pipeline_tag') or 'model'} · {it.get('likes', 0)} likes · {it.get('downloads', 0)} downloads",
                        published_at=datetime.fromisoformat((it.get("createdAt") or datetime.utcnow().isoformat()).rstrip("Z").split(".")[0]),
                        topics=["AI", "Open Source"], trend_score=min(85, 35 + (it.get("likes") or 0) // 20),
                    ))
            except Exception as e:  # noqa: BLE001
                logger.info("hf models failed: %s", e)
        logger.info("huggingface: %d items", len(out))
        return out
