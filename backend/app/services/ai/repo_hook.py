"""README → one-line hook for GitHub repo cards.

GitHub descriptions are written for maintainers ("Lean certificates
accompanying Navier-Stokes…"). A feed card needs the pitch a friend would give
you: "Free, open-source ElevenLabs replacement". This module reads the README
and asks Gemini for that line, plus a one-sentence "so what".

Budget: one Gemini call per repo, cached on the stored article, so the hourly
cron only pays for new repos (a handful) and a small backfill.
"""
from __future__ import annotations

import base64
import logging
import re
from typing import Optional

import httpx
from pydantic import BaseModel, Field

from app.core.config import get_settings
from app.services.ai.summarizer import Summarizer, _safe_json_loads

logger = logging.getLogger(__name__)

PROMPT = """You write the one-line hooks on TechiNews repo cards. Developers scroll a feed;
a card has one line to earn the tap.

Given a GitHub repo (name, description, README), return JSON:
- hook: <= 48 characters. The pitch a friend would text you. Lead with the benefit
  or the famous product it replaces. Patterns that work:
    "Free, open-source ElevenLabs alternative"
    "Make AI videos from a text prompt"
    "Self-hosted Notion you actually own"
    "Cursor-style AI coding, in your terminal"
    "Run Llama 3 on a MacBook, one command"
  No repo name, no emoji, no "A tool that", no marketing fluff, no exclamation marks.
  If it's a library/paper/dataset, say what it lets you DO, not what it IS.
- pitch: <= 110 characters. One plain sentence a developer would trust:
  who it's for and the one concrete thing it does. No hype adjectives.
- alt_to: the well-known product it replaces or competes with, or "" if none.

Respond ONLY with the JSON object."""


class RepoHook(BaseModel):
    hook: str = Field(default="")
    pitch: str = Field(default="")
    alt_to: str = Field(default="")


async def fetch_readme(full_name: str, max_chars: int = 5000) -> str:
    token = get_settings().GITHUB_TOKEN
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "TechiNews/0.2"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        async with httpx.AsyncClient(timeout=15, headers=headers) as c:
            r = await c.get(f"https://api.github.com/repos/{full_name}/readme")
        if r.status_code != 200:
            return ""
        raw = base64.b64decode(r.json().get("content", "")).decode("utf-8", "ignore")
    except Exception as e:  # noqa: BLE001
        logger.info("readme fetch failed for %s: %s", full_name, e)
        return ""
    # Strip the noise that eats tokens without adding meaning.
    raw = re.sub(r"<[^>]+>", " ", raw)                       # html (badges, centered logos)
    raw = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", raw)          # images
    raw = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", raw)       # links -> text
    raw = re.sub(r"```.*?```", " ", raw, flags=re.S)         # code blocks
    raw = re.sub(r"[ \t]+", " ", raw)
    raw = re.sub(r"\n{3,}", "\n\n", raw)
    return raw.strip()[:max_chars]


async def generate(full_name: str, description: str, readme: Optional[str] = None) -> Optional[RepoHook]:
    """Returns None when the LLM is unavailable so callers keep the GitHub text."""
    s = get_settings()
    if not s.GEMINI_API_KEY or Summarizer._quota_exhausted:
        return None
    if readme is None:
        readme = await fetch_readme(full_name)
    user_msg = f"REPO: {full_name}\nDESCRIPTION: {description or '(none)'}\n\nREADME:\n{readme or '(no readme)'}"
    payload = {
        "system_instruction": {"parts": [{"text": PROMPT}]},
        "contents": [{"role": "user", "parts": [{"text": user_msg}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.6,
            "maxOutputTokens": 256,
            "thinkingConfig": {"thinkingBudget": 0},
        },
    }
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{s.GEMINI_MODEL}:generateContent?key={s.GEMINI_API_KEY}"
    try:
        async with httpx.AsyncClient(timeout=40) as c:
            r = await c.post(url, json=payload)
        if r.status_code == 429:
            Summarizer._quota_exhausted = True
            logger.warning("gemini 429 during repo hook; halting LLM calls")
            return None
        if r.status_code != 200:
            logger.info("repo hook %s -> %s", full_name, r.status_code)
            return None
        parsed = _safe_json_loads(r.json()["candidates"][0]["content"]["parts"][0]["text"])
        if not parsed:
            return None
        hook = RepoHook(**parsed)
        hook.hook = _clean(hook.hook, 56)
        hook.pitch = _clean(hook.pitch, 130)
        hook.alt_to = _clean(hook.alt_to, 40)
        return hook if hook.hook else None
    except Exception as e:  # noqa: BLE001
        logger.info("repo hook failed for %s: %s", full_name, e)
        return None


def _clean(text: str, limit: int) -> str:
    t = " ".join((text or "").split()).strip(" .!")
    return t[:limit].rstrip() if len(t) > limit else t
