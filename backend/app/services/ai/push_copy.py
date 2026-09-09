"""Push-notification copywriter.

Quick-commerce apps (Blinkit, Zepto, Swiggy, Zomato) get 2-4x the open rate of
news apps because their pushes read like a friend texting, not a headline:
short, one concrete benefit, a curiosity gap, and a reason to tap NOW. We
borrow the craft, not the manipulation: every line must be true to the story.

Rules baked into the prompt (from their playbooks):
  * title <= 38 chars, starts with one emoji, reads in the notification shade
    without truncation on a 390px phone.
  * body <= 90 chars, one sentence, ends before the shade cuts it off.
  * lead with the payoff ("Free ElevenLabs alternative just hit 10k stars"),
    never the source name.
  * concrete > vague: a number, a product name, a verb.
  * curiosity gap is fine ("The one setting…"), lying is not. The article must
    deliver what the push promises.
  * no ALL CAPS, at most one exclamation mark per push, no "click here".

Falls back to a deterministic template when Gemini is unavailable, so pushes
never silently degrade to raw headlines.
"""
from __future__ import annotations

import logging
from typing import Optional

import httpx
from pydantic import BaseModel, Field

from app.core.config import get_settings
from app.services.ai.summarizer import Summarizer, _safe_json_loads

logger = logging.getLogger(__name__)

PROMPT = """You write push notifications for TechiNews, a tech-news app for developers.
Write like Zepto / Blinkit / Swiggy do: a friend texting, not a newspaper.

Return JSON: {"title": ..., "body": ...}

title: <= 38 characters INCLUDING one leading emoji and a space. Hook first.
body:  <= 90 characters. One sentence. Concrete payoff or the one surprising fact.

Craft rules:
- Lead with the benefit or the surprise, never with the source or company PR voice.
- Use a number, a product name, or a strong verb. "Free ElevenLabs alternative hits 12k stars"
  beats "New open-source TTS project released".
- Curiosity gap is allowed only if the story answers it. Never promise what the story lacks.
- No ALL CAPS words, max one "!", no "click", "tap", "read more", no hashtags.
- Emoji choices: 🔥 breaking, 🚀 launch, 🧠 AI/research, 🛠 dev tool, 💸 funding/money,
  🔓 open source, ⚠️ security, 📱 mobile, ☕ digest.

Examples (story -> push):
- "Kokoro TTS reaches 82M param open-weight release" ->
  {"title": "🔓 Free ElevenLabs alternative", "body": "Kokoro TTS runs on a laptop and sounds close to paid voices. 82M params."}
- "OpenAI ships GPT-5 with 400k context" ->
  {"title": "🚀 GPT-5 is out, 400k context", "body": "Fits a whole codebase in one prompt. Here's what changed for devs."}
- "Critical RCE in Next.js middleware" ->
  {"title": "⚠️ Patch Next.js today", "body": "One header bypasses auth middleware on every version before 14.2.25."}

Respond ONLY with the JSON object."""


class PushCopy(BaseModel):
    title: str = Field(default="")
    body: str = Field(default="")


_EMOJI = {
    "Cybersecurity": "⚠️", "Open Source": "🔓", "Funding": "💸", "AI": "🧠", "Mobile": "📱",
    "Product Launches": "🚀", "Startups": "🚀", "Web Development": "🛠", "Research": "🧠",
}


def fallback(title: str, summary: str, topics: list[str], hook: Optional[str] = None, breaking: bool = False) -> PushCopy:
    emoji = "🔥" if breaking else next((_EMOJI[t] for t in topics if t in _EMOJI), "📰")
    head = hook or title
    head = head if len(head) <= 36 else head[:35].rsplit(" ", 1)[0] + "…"
    body = (summary or title).strip()
    body = body if len(body) <= 90 else body[:89].rsplit(" ", 1)[0] + "…"
    return PushCopy(title=f"{emoji} {head}", body=body)


async def write(title: str, summary: str, topics: list[str], hook: Optional[str] = None, breaking: bool = False) -> PushCopy:
    s = get_settings()
    if not s.GEMINI_API_KEY or Summarizer._quota_exhausted:
        return fallback(title, summary, topics, hook, breaking)
    user_msg = (
        f"KIND: {'breaking' if breaking else 'story'}\nTITLE: {title}\n"
        f"SUMMARY: {summary or '(none)'}\nHOOK: {hook or '(none)'}\nTOPICS: {', '.join(topics)}"
    )
    payload = {
        "system_instruction": {"parts": [{"text": PROMPT}]},
        "contents": [{"role": "user", "parts": [{"text": user_msg}]}],
        "generationConfig": {
            "responseMimeType": "application/json", "temperature": 0.7,
            "maxOutputTokens": 128, "thinkingConfig": {"thinkingBudget": 0},
        },
    }
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{s.GEMINI_MODEL}:generateContent?key={s.GEMINI_API_KEY}"
    try:
        async with httpx.AsyncClient(timeout=30) as c:
            r = await c.post(url, json=payload)
        if r.status_code == 429:
            Summarizer._quota_exhausted = True
            return fallback(title, summary, topics, hook, breaking)
        if r.status_code != 200:
            return fallback(title, summary, topics, hook, breaking)
        parsed = _safe_json_loads(r.json()["candidates"][0]["content"]["parts"][0]["text"]) or {}
        copy = PushCopy(**parsed)
        if not copy.title or not copy.body:
            return fallback(title, summary, topics, hook, breaking)
        copy.title = copy.title.strip()[:42]
        copy.body = copy.body.strip()[:100]
        return copy
    except Exception as e:  # noqa: BLE001
        logger.info("push copy failed: %s", e)
        return fallback(title, summary, topics, hook, breaking)
