"""Gemini-backed article summarizer with structured JSON output."""
from __future__ import annotations

import json
import logging
from typing import List, Optional

import httpx
from pydantic import BaseModel, Field

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class SummaryResult(BaseModel):
    summary: str = Field(default="")
    key_points: List[str] = Field(default_factory=list)
    why_it_matters: str = Field(default="")
    topics: List[str] = Field(default_factory=list)
    companies: List[str] = Field(default_factory=list)
    stack: List[str] = Field(default_factory=list)
    trend_score: int = Field(default=50)


SYSTEM_PROMPT = """You are an editor for TechiNews, an AI-powered tech intelligence app for developers, founders, and investors.

Given an article (title + full content), produce a JSON object with:
- summary: 1-2 sentence TL;DR, max 50 words. Punchy, no filler.
- key_points: 3 to 5 short bullet takeaways (each <= 18 words).
- why_it_matters: 1 paragraph (max 80 words) on the strategic implication — what changes for the industry / builders. Avoid hype.
- topics: 1-4 tags from: AI, Open Source, Cybersecurity, Web Development, Mobile, Space Tech, Robotics, Finance Tech, Blockchain, Funding, Hiring, Product Launches, Startups, Apple, Google, NVIDIA, OpenAI, Meta, Microsoft, Anthropic.
- companies: company names explicitly named in the article (max 5).
- stack: tech stack / languages / frameworks mentioned (max 6).
- trend_score: integer 0-100 estimating how big this story is for a tech audience (90+ = top story of the week, 50 = typical, 20 = niche).

Match the tone of Stratechery / Hacker News top comments — direct, technical, no marketing language.

Respond ONLY with a valid JSON object, no markdown fences, no commentary."""


class Summarizer:
    # Process-wide flag — once we see a 429 from Gemini, stop hammering it.
    _quota_exhausted: bool = False

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        s = get_settings()
        self.api_key = api_key or s.GEMINI_API_KEY
        self.model = model or s.GEMINI_MODEL

    @classmethod
    def reset_quota_flag(cls) -> None:
        cls._quota_exhausted = False

    @property
    def endpoint(self) -> str:
        return f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"

    async def summarize(
        self,
        title: str,
        body: str,
        source_name: str,
        max_body_chars: int = 6_000,
    ) -> SummaryResult:
        if not self.api_key or Summarizer._quota_exhausted:
            return _fallback(title)
        clipped = body.strip()[:max_body_chars]
        user_msg = f"SOURCE: {source_name}\nTITLE: {title}\n\nCONTENT:\n{clipped}"

        body_payload = {
            "system_instruction": {"parts": [{"text": SYSTEM_PROMPT}]},
            "contents": [{"role": "user", "parts": [{"text": user_msg}]}],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.4,
                "maxOutputTokens": 2048,
                # 2.5 Flash thinking burns output budget. Turn it off for structured tasks.
                "thinkingConfig": {"thinkingBudget": 0},
            },
        }
        url = f"{self.endpoint}?key={self.api_key}"
        try:
            async with httpx.AsyncClient(timeout=60) as c:
                r = await c.post(url, json=body_payload)
            if r.status_code == 429:
                Summarizer._quota_exhausted = True
                logger.warning("gemini %s -> 429 quota exhausted; halting LLM calls for this process", self.model)
                return _fallback(title)
            if r.status_code != 200:
                logger.warning("gemini %s -> %s %s", self.model, r.status_code, r.text[:200])
                return _fallback(title)
            data = r.json()
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            parsed = _safe_json_loads(text)
            if parsed is None:
                logger.warning("gemini returned unparseable JSON for %r: %s", title[:60], text[:200])
                return _fallback(title)
            return SummaryResult(**parsed)
        except (httpx.ReadTimeout, httpx.ConnectTimeout) as e:
            logger.warning("gemini timeout for %r: %s", title[:60], e)
            return _fallback(title)
        except Exception as e:  # noqa: BLE001
            logger.exception("summarizer failed for %r: %s", title[:60], e)
            return _fallback(title)


def _safe_json_loads(text: str) -> Optional[dict]:
    """Tolerant JSON parser — strips code fences, isolates the outer JSON object."""
    if not text:
        return None
    t = text.strip()
    # Strip ```json … ``` fences if present.
    if t.startswith("```"):
        t = t.split("```", 2)
        t = t[1] if len(t) > 1 else ""
        if t.startswith("json"):
            t = t[4:]
        t = t.strip("` \n")
    try:
        return json.loads(t)
    except Exception:
        # Best-effort: find {...} braces and try again.
        start = t.find("{")
        end = t.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                return json.loads(t[start : end + 1])
            except Exception:
                return None
        return None


def _fallback(title: str) -> SummaryResult:
    return SummaryResult(
        summary=title,
        key_points=[],
        why_it_matters="",
        topics=[],
        companies=[],
        stack=[],
        trend_score=50,
    )
