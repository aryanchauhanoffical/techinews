"""Cheap, deterministic ranking + cross-source dedup.

Runs before any LLM call so we only pay to summarize what will actually
surface. Score 0–100 from: source weight, hot-term hits, engagement the
source already exposes (HN points, stars, upvotes), and recency."""
from __future__ import annotations

import re
from datetime import datetime
from typing import Dict, List

from app.schemas.article import Article, SourceType
from app.services.sources import DEFAULT_FEEDS, YOUTUBE_CHANNELS, BLUESKY_ACCOUNTS, HOT_TERMS

_WEIGHT: Dict[str, float] = {sid: w for sid, _, _, _, w in DEFAULT_FEEDS}
_WEIGHT.update({"anthropic_news": 1.3, "meta_ai_blog": 1.2})
_WEIGHT.update({f"yt_{cid}": 0.9 for _, cid in YOUTUBE_CHANNELS})
_WEIGHT.update({f"bsky_{h}": 0.9 for _, h in BLUESKY_ACCOUNTS})
_TYPE_BASE = {
    SourceType.hacker_news: 50, SourceType.github: 50, SourceType.blog: 45,
    SourceType.news: 40, SourceType.huggingface: 40, SourceType.reddit: 35,
    SourceType.product_hunt: 35, SourceType.arxiv: 25,
    SourceType.youtube: 40, SourceType.bluesky: 42,
}
_TOKEN = re.compile(r"[a-z0-9]+")
_STOP = {"the", "a", "an", "of", "to", "in", "for", "and", "on", "with", "is", "at", "by", "from", "how", "why", "what", "new", "its", "it"}


def _tokens(title: str) -> set:
    return {t for t in _TOKEN.findall(title.lower()) if t not in _STOP and len(t) > 2}


HALF_LIFE_H = 36.0
_TERM_CACHE: Dict[str, re.Pattern] = {}


def _term(t: str) -> re.Pattern:
    """Whole-word match so 'llama' does not fire inside 'ollama'."""
    if t not in _TERM_CACHE:
        _TERM_CACHE[t] = re.compile(r"(?<![a-z0-9])" + re.escape(t) + r"(?![a-z0-9])")
    return _TERM_CACHE[t]
_ENTITY = re.compile(r"\b([A-Z][A-Za-z0-9.\-]{2,}(?:\s[A-Z][A-Za-z0-9.\-]{1,})?)")
_GENERIC = {"The", "How", "Why", "What", "New", "Introducing", "Show", "Ask", "This", "Using", "With", "From", "Our", "Your", "And", "For"}


def score(a: Article, now: datetime | None = None) -> int:
    """Static source quality + (buzz × time decay) + freshness.

    Buzz (hot terms, engagement) halves every HALF_LIFE_H hours so a huge
    story from last week cannot sit above a decent story from this morning."""
    now = now or datetime.utcnow()
    base = _TYPE_BASE.get(a.source.type, 40) * _WEIGHT.get(a.source.id, 1.0)
    text = f"{a.title} {a.summary or ''}".lower()
    hits = min(sum(1 for t in HOT_TERMS if _term(t).search(text)), 5) * 3
    if hits == 0 and a.source.type in (SourceType.hacker_news, SourceType.reddit, SourceType.news):
        base *= 0.72  # aggregator item with no tech signal: courts, rockets, essays
    engagement = min(max(0, a.trend_score - 40) * 0.5, 20)
    age_h = max(0.0, (now - a.published_at).total_seconds() / 3600)
    decay = 0.5 ** (age_h / HALF_LIFE_H)
    fresh = 15 if age_h < 6 else 10 if age_h < 24 else 4 if age_h < 48 else 0
    return int(max(0, min(100, base + (hits + engagement) * decay + fresh)))


_CAP = re.compile(r"\b[A-Z][A-Za-z0-9.\-]{2,}\b")


def _entities(title: str) -> set:
    """Capitalised tokens that look like names: GPT-6, Astra, Opus, Gemini.
    Single words, so 'GPT-6 Astra' and 'Astra' still meet."""
    return {w.lower() for w in _CAP.findall(title) if w not in _GENERIC and not w.isupper() or len(w) > 3 and w not in _GENERIC}


def cluster(items: List[Article], window_h: int = 96) -> List[Article]:
    """Group the same story across sources. Two items belong together when
    they were published within `window_h` of each other and either share a
    named entity ("Astra", "Opus 5", "llama.cpp") or their title tokens
    overlap strongly. The best-scored item leads: it gets a coverage count,
    links to the rest, and a small boost; the rest are nudged down so one
    story does not occupy five slots."""
    # Primary sources (lab blogs, company posts) lead a cluster when they are
    # within striking distance of the top score; mirrors and discussion links follow.
    items = sorted(items, key=lambda a: a.trend_score + (8 if a.source.type == SourceType.blog else 0), reverse=True)
    meta = [( _entities(a.title), _tokens(a.title)) for a in items]
    lead_of: Dict[int, int] = {}
    for i, a in enumerate(items):
        if i in lead_of:
            continue
        lead_of[i] = i
        ents_i, toks_i = meta[i]
        for j in range(i + 1, len(items)):
            if j in lead_of:
                continue
            b = items[j]
            if abs((a.published_at - b.published_at).total_seconds()) > window_h * 3600:
                continue
            ents_j, toks_j = meta[j]
            shared_ent = bool(ents_i & ents_j)
            jac = len(toks_i & toks_j) / max(1, len(toks_i | toks_j))
            if shared_ent and jac >= 0.15 or jac >= 0.4:
                lead_of[j] = i
    members: Dict[int, List[int]] = {}
    for j, i in lead_of.items():
        members.setdefault(i, []).append(j)
    out: List[Article] = []
    for i, a in enumerate(items):
        lead = lead_of[i]
        if lead == i:
            group = [k for k in members.get(i, []) if k != i]
            if group:
                a = a.model_copy(update={
                    "coverage": 1 + len({items[k].source.id for k in group} - {a.source.id}) or 1,
                    "related_ids": [items[k].id for k in group][:12],
                    "trend_score": min(100, a.trend_score + min(16, 4 * len(group))),
                })
        else:
            a = a.model_copy(update={"trend_score": max(0, a.trend_score - 8), "related_ids": [items[lead].id]})
        out.append(a)
    return out


def dedup(items: List[Article]) -> List[Article]:
    """Drop exact-URL dups and near-identical titles (token Jaccard >= 0.75).
    Keeps the higher-scored copy."""
    items = sorted(items, key=lambda a: a.trend_score, reverse=True)
    kept: List[Article] = []
    seen_urls, seen_tokens = set(), []
    for a in items:
        key = a.url.split("?")[0].rstrip("/").lower()
        if key in seen_urls:
            continue
        toks = _tokens(a.title)
        if toks and any(len(toks & t) / len(toks | t) >= 0.75 for t in seen_tokens):
            continue
        seen_urls.add(key)
        seen_tokens.append(toks)
        kept.append(a)
    return kept


def diversify(items: List[Article], per_source: int = 4) -> List[Article]:
    """Stable re-order: no source gets more than `per_source` slots before
    every other source has had its turn. Keeps corporate feeds from flooding
    the top of the feed."""
    counts: Dict[str, int] = {}
    head, tail = [], []
    for a in items:
        n = counts.get(a.source.id, 0)
        (head if n < per_source else tail).append(a)
        counts[a.source.id] = n + 1
    return head + tail


def rank(items: List[Article]) -> List[Article]:
    now = datetime.utcnow()
    scored = [a.model_copy(update={"trend_score": score(a, now)}) for a in items]
    clustered = sorted(cluster(dedup(scored)), key=lambda a: a.trend_score, reverse=True)
    return diversify(clustered)
