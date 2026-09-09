"""Article text + OG image extraction. Local first (trafilatura, free,
no network hop beyond the page itself), Jina second, Firecrawl last."""
from __future__ import annotations

import asyncio
import logging
import re
from typing import Optional, Tuple

import httpx
import trafilatura

from app.services.scrapers.firecrawl import Firecrawl
from app.services.scrapers.jina_reader import JinaReader

logger = logging.getLogger(__name__)
UA = "Mozilla/5.0 (compatible; TechiNews/0.2; +https://github.com/aryanchauhanoffical/techinews)"
_OG = re.compile(r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)', re.I)
_OG2 = re.compile(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']', re.I)


class Extractor:
    def __init__(self):
        self.jina = JinaReader()
        self.firecrawl = Firecrawl()

    async def fetch_html(self, url: str) -> Optional[str]:
        try:
            async with httpx.AsyncClient(timeout=20.0, follow_redirects=True,
                                         headers={"User-Agent": UA}) as c:
                r = await c.get(url)
                if r.status_code == 200 and "html" in r.headers.get("content-type", ""):
                    return r.text
        except Exception as e:  # noqa: BLE001
            logger.debug("fetch %s failed: %s", url, e)
        return None

    @staticmethod
    def og_image(html: str) -> Optional[str]:
        m = _OG.search(html) or _OG2.search(html)
        return m.group(1) if m else None

    async def extract(self, url: str) -> Tuple[str, Optional[str]]:
        """Returns (text, og_image_url). Text may be '' if every path fails."""
        html = await self.fetch_html(url)
        image = self.og_image(html) if html else None
        if html:
            text = await asyncio.to_thread(
                trafilatura.extract, html, include_comments=False, include_tables=False, favor_precision=True
            )
            if text and len(text) > 400:
                return text, image
        text = await self.jina.extract(url)
        if text and len(text) > 400:
            return text, image
        text = await self.firecrawl.scrape(url)
        return text or "", image
