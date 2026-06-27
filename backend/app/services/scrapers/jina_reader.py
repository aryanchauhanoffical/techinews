"""Jina Reader — extract LLM-ready markdown from any URL.

Free tier: 500 RPM. Prepend r.jina.ai/ to any URL.
"""
from __future__ import annotations

from typing import Optional

import httpx

from app.core.config import get_settings


class JinaReader:
    BASE = "https://r.jina.ai"

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or get_settings().JINA_API_KEY

    async def extract(self, url: str, timeout: float = 45.0) -> Optional[str]:
        headers = {"Accept": "text/plain"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        try:
            async with httpx.AsyncClient(timeout=timeout) as c:
                r = await c.get(f"{self.BASE}/{url}", headers=headers)
                if r.status_code != 200:
                    return None
                return r.text
        except (httpx.ReadTimeout, httpx.ConnectTimeout, httpx.RemoteProtocolError):
            return None
