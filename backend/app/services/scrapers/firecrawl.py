"""Firecrawl — JS-rendered scraping fallback for sites Jina can't handle."""
from __future__ import annotations

from typing import Optional

import httpx

from app.core.config import get_settings


class Firecrawl:
    BASE = "https://api.firecrawl.dev/v1"

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or get_settings().FIRECRAWL_API_KEY

    async def scrape(self, url: str, timeout: float = 60.0) -> Optional[str]:
        if not self.api_key:
            return None
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        body = {"url": url, "formats": ["markdown"]}
        try:
            async with httpx.AsyncClient(timeout=timeout) as c:
                r = await c.post(f"{self.BASE}/scrape", headers=headers, json=body)
                if r.status_code != 200:
                    return None
                data = r.json()
                return (data.get("data") or {}).get("markdown")
        except (httpx.ReadTimeout, httpx.ConnectTimeout, httpx.RemoteProtocolError):
            return None
