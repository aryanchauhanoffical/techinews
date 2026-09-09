"""Notification / card images. Order: source-provided image → OG image →
generated (Cloudflare Workers AI FLUX.1-schnell, uploaded to Supabase Storage).
Generation is reserved for top stories so the free quotas are never a concern."""
from __future__ import annotations

import asyncio
import base64
import logging
import re
from typing import List, Optional

import httpx

from app.core.config import get_settings

logger = logging.getLogger(__name__)
GENERATE_MIN_SCORE = 75


async def generate_image(prompt: str) -> Optional[bytes]:
    s = get_settings()
    if not (s.CLOUDFLARE_ACCOUNT_ID and s.CLOUDFLARE_API_TOKEN):
        return None
    url = f"https://api.cloudflare.com/client/v4/accounts/{s.CLOUDFLARE_ACCOUNT_ID}/ai/run/@cf/black-forest-labs/flux-1-schnell"
    try:
        async with httpx.AsyncClient(timeout=60.0) as c:
            r = await c.post(url, headers={"Authorization": f"Bearer {s.CLOUDFLARE_API_TOKEN}"},
                             json={"prompt": prompt, "steps": 4})
            data = r.json()
            if data.get("success"):
                return base64.b64decode(data["result"]["image"])
            logger.info("cf image failed: %s", data.get("errors"))
    except Exception as e:  # noqa: BLE001
        logger.info("cf image error: %s", e)
    return None


async def upload_image(name: str, data: bytes, content_type: str = "image/jpeg") -> Optional[str]:
    s = get_settings()
    if not (s.SUPABASE_URL and s.SUPABASE_SERVICE_ROLE_KEY):
        return None
    path = f"{s.SUPABASE_BUCKET}/{name}"
    try:
        async with httpx.AsyncClient(timeout=30.0) as c:
            r = await c.post(f"{s.SUPABASE_URL}/storage/v1/object/{path}", content=data,
                             headers={"apikey": s.SUPABASE_SERVICE_ROLE_KEY,
                                      "Authorization": f"Bearer {s.SUPABASE_SERVICE_ROLE_KEY}",
                                      "Content-Type": content_type, "x-upsert": "true"})
            if r.status_code in (200, 201):
                return f"{s.SUPABASE_URL}/storage/v1/object/public/{path}"
            logger.info("supabase upload -> %s %s", r.status_code, r.text[:120])
    except Exception as e:  # noqa: BLE001
        logger.info("supabase upload error: %s", e)
    return None


def _prompt(title: str, topics: list[str]) -> str:
    topic = ", ".join(topics[:2]) or "technology"
    return (f"Minimal editorial illustration for a tech news app about {topic}: '{title[:90]}'. "
            "Abstract geometric shapes, deep navy background, single accent color, no text, no logos, clean, high contrast.")


async def resolve_image(article_id: str, title: str, topics: list[str], score: int,
                        existing: Optional[str], og: Optional[str]) -> Optional[str]:
    if existing:
        return existing
    if og:
        return og
    if score < GENERATE_MIN_SCORE:
        return None
    data = await generate_image(_prompt(title, topics))
    if not data:
        return None
    return await upload_image(f"{article_id}.jpg", data)


_GH = re.compile(r"https?://github\.com/([\w.-]+)/([\w.-]+)")


def github_card(url: str) -> Optional[str]:
    """GitHub renders an OG card for every repository. Free, always present."""
    m = _GH.match(url)
    return f"https://opengraph.githubassets.com/1/{m.group(1)}/{m.group(2)}" if m else None


async def fill_missing_images(articles: list, limit: int = 150, concurrency: int = 10) -> int:
    """Image-only pass for items that will NOT be enriched: one HTML fetch each,
    read og:image, no LLM. GitHub URLs skip the fetch entirely."""
    from app.services.extract import Extractor
    ex = Extractor()
    sem = asyncio.Semaphore(concurrency)
    todo = []
    for a in articles:
        if a.image_url:
            continue
        card = github_card(a.url)
        if card:
            a.image_url = card
            continue
        if a.source.type.value in ("arxiv",):
            continue
        todo.append(a)
    todo = todo[:limit]

    async def one(a):
        async with sem:
            html = await ex.fetch_html(a.url)
            img = ex.og_image(html) if html else None
            if img and img.startswith("http"):
                a.image_url = img
                return 1
            return 0

    got = sum(await asyncio.gather(*[one(a) for a in todo])) if todo else 0
    logger.info("image pass: %d fetched, %d recovered", len(todo), got)
    return got
