"""Ping every API listed in everyapi.md once and report status.

Usage:
    cd backend
    python3 scripts/test_apis.py

Runs minimal cheapest calls only so we don't burn quota.
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Optional

import httpx
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


@dataclass
class Result:
    name: str
    ok: bool
    status: Optional[int]
    ms: int
    detail: str


def _short(s: str, n: int = 220) -> str:
    s = s.replace("\n", " ").strip()
    return s if len(s) <= n else s[: n - 1] + "…"


async def _run(name: str, fn: Callable) -> Result:
    t0 = time.time()
    try:
        status, detail = await fn()
        ms = int((time.time() - t0) * 1000)
        return Result(name=name, ok=200 <= status < 300, status=status, ms=ms, detail=detail)
    except Exception as e:  # noqa: BLE001
        ms = int((time.time() - t0) * 1000)
        return Result(name=name, ok=False, status=None, ms=ms, detail=f"{type(e).__name__}: {e}")


# ------- 1. Gemini -------
async def test_gemini() -> tuple[int, str]:
    key = os.environ["GEMINI_API_KEY"]
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
    body = {"contents": [{"parts": [{"text": "Reply with exactly: OK"}]}]}
    async with httpx.AsyncClient(timeout=30) as c:
        r = await c.post(url, json=body)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        data = r.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        return 200, f"reply={_short(text, 80)}"


# ------- Cloudflare Workers AI helpers -------
# cfut_ tokens are Cloudflare User API Tokens. The public AI Gateway run endpoint:
#   POST https://api.cloudflare.com/client/v4/ai/run/{model}
#   Authorization: Bearer {cfut_token}
CF_RUN_URL = "https://api.cloudflare.com/client/v4/ai/run/{model}"


async def _cf_chat(token: str, model: str) -> tuple[int, str]:
    url = CF_RUN_URL.format(model=model)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {
        "messages": [{"role": "user", "content": "Reply with exactly: OK"}],
        "max_tokens": 16,
    }
    async with httpx.AsyncClient(timeout=45) as c:
        r = await c.post(url, headers=headers, json=body)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        try:
            data = r.json()
        except Exception:
            return r.status_code, _short(r.text)
        return 200, _short(json.dumps(data), 200)


async def _cf_image(token: str, model: str) -> tuple[int, str]:
    url = CF_RUN_URL.format(model=model)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {"prompt": "a tiny red dot on white background"}
    async with httpx.AsyncClient(timeout=60) as c:
        r = await c.post(url, headers=headers, json=body)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        ctype = r.headers.get("content-type", "")
        if "image" in ctype:
            return 200, f"image bytes={len(r.content)} content-type={ctype}"
        return 200, _short(r.text)


# ------- 2/3 Claude via Cloudflare -------
async def test_claude_opus() -> tuple[int, str]:
    return await _cf_chat(os.environ["CF_CLAUDE_OPUS_TOKEN"], os.environ["CF_CLAUDE_OPUS_MODEL"])


async def test_claude_sonnet() -> tuple[int, str]:
    return await _cf_chat(os.environ["CF_CLAUDE_SONNET_TOKEN"], os.environ["CF_CLAUDE_SONNET_MODEL"])


# ------- 4. Grok image -------
async def test_grok_image() -> tuple[int, str]:
    return await _cf_image(os.environ["CF_GROK_IMAGE_TOKEN"], os.environ["CF_GROK_IMAGE_MODEL"])


# ------- 5. OpenAI GPT via Cloudflare -------
async def test_cf_openai_gpt() -> tuple[int, str]:
    token = os.environ["CF_OPENAI_GPT_TOKEN"]
    model = os.environ["CF_OPENAI_GPT_MODEL"]
    url = CF_RUN_URL.format(model=model)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {"input": "Reply with exactly: OK"}
    async with httpx.AsyncClient(timeout=45) as c:
        r = await c.post(url, headers=headers, json=body)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        return 200, _short(r.text, 200)


# ------- 6/7 image gen via Cloudflare -------
async def test_cf_openai_image() -> tuple[int, str]:
    return await _cf_image(os.environ["CF_OPENAI_IMAGE_TOKEN"], os.environ["CF_OPENAI_IMAGE_MODEL"])


async def test_cf_alibaba_image() -> tuple[int, str]:
    return await _cf_image(os.environ["CF_ALIBABA_IMAGE_TOKEN"], os.environ["CF_ALIBABA_IMAGE_MODEL"])


# ------- 8. Jina Reader -------
async def test_jina() -> tuple[int, str]:
    token = os.environ["JINA_API_KEY"]
    # Jina reader: prepend r.jina.ai/ to a URL
    target = "https://example.com"
    url = f"https://r.jina.ai/{target}"
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient(timeout=30) as c:
        r = await c.get(url, headers=headers)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        return 200, f"chars={len(r.text)} starts_with={_short(r.text[:120], 80)}"


# ------- 9. Firecrawl -------
async def test_firecrawl() -> tuple[int, str]:
    key = os.environ["FIRECRAWL_API_KEY"]
    url = "https://api.firecrawl.dev/v1/scrape"
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    body = {"url": "https://example.com", "formats": ["markdown"]}
    async with httpx.AsyncClient(timeout=45) as c:
        r = await c.post(url, headers=headers, json=body)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        try:
            data = r.json()
            md = data.get("data", {}).get("markdown", "")
            return 200, f"markdown_chars={len(md)} preview={_short(md, 80)}"
        except Exception:
            return r.status_code, _short(r.text)


# ------- 10. NewsAPI -------
async def test_newsapi() -> tuple[int, str]:
    key = os.environ["NEWSAPI_KEY"]
    url = "https://newsapi.org/v2/top-headlines"
    params = {"category": "technology", "language": "en", "pageSize": 1, "apiKey": key}
    async with httpx.AsyncClient(timeout=30) as c:
        r = await c.get(url, params=params)
        if r.status_code != 200:
            return r.status_code, _short(r.text)
        data = r.json()
        n = data.get("totalResults", 0)
        first = (data.get("articles") or [{}])[0].get("title", "")
        return 200, f"totalResults={n} first={_short(first, 90)}"


# ------- Main -------
TESTS: list[tuple[str, Callable]] = [
    ("1. Gemini (direct REST)", test_gemini),
    ("2. Claude Opus 4.7 (Cloudflare)", test_claude_opus),
    ("3. Claude Sonnet 4.6 (Cloudflare)", test_claude_sonnet),
    ("4. Grok Imagine Image (Cloudflare)", test_grok_image),
    ("5. OpenAI GPT-5.4-pro (Cloudflare)", test_cf_openai_gpt),
    ("6. OpenAI gpt-image-2 (Cloudflare)", test_cf_openai_image),
    ("7. Alibaba wan-2.6-image (Cloudflare)", test_cf_alibaba_image),
    ("8. Jina Reader", test_jina),
    ("9. Firecrawl", test_firecrawl),
    ("10. NewsAPI.org", test_newsapi),
]


async def main() -> int:
    results: list[Result] = []
    for name, fn in TESTS:
        print(f"  → testing {name} …", flush=True)
        results.append(await _run(name, fn))

    print()
    print("=" * 88)
    print(f"{'API':<46} {'STATUS':<10} {'HTTP':<6} {'MS':<6} DETAIL")
    print("-" * 88)
    for r in results:
        flag = "OK" if r.ok else "FAIL"
        http = str(r.status) if r.status is not None else "-"
        print(f"{r.name:<46} {flag:<10} {http:<6} {r.ms:<6} {r.detail}")
    print("=" * 88)
    fail = [r for r in results if not r.ok]
    print(f"{len(results) - len(fail)}/{len(results)} passing — {len(fail)} failing")
    return 0 if not fail else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
