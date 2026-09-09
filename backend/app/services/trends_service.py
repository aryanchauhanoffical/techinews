"""Discover-tab data derived from what the pipeline already stored.
No extra network calls: topics = tag counts over the last 7 days vs the 7
before; repos = GitHub-sourced articles ranked by stars; funding = articles
tagged Funding."""
from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import List

from app.db import mongo
from app.schemas.article import GithubRepo
from app.services.article_repo import _from_doc

_MONEY = re.compile(r"\$\s?(\d+(?:\.\d+)?)\s*(billion|million|B|M)\b", re.I)


class TrendsService:
    async def trending_topics(self, limit: int = 8) -> List[dict]:
        db = mongo.get_db()
        if db is None:
            return []
        now = datetime.utcnow()
        pipe = lambda a, b: [  # noqa: E731
            {"$match": {"published_at": {"$gte": a, "$lt": b}, "topics": {"$exists": True, "$ne": []}}},
            {"$unwind": "$topics"},
            {"$group": {"_id": "$topics", "n": {"$sum": 1}, "top": {"$max": "$trend_score"},
                        "sample": {"$top": {"sortBy": {"trend_score": -1}, "output": "$title"}}}},
        ]
        cur = {d["_id"]: d async for d in db.articles.aggregate(pipe(now - timedelta(days=7), now))}
        prev = {d["_id"]: d["n"] async for d in db.articles.aggregate(pipe(now - timedelta(days=14), now - timedelta(days=7)))}
        out = []
        for name, d in cur.items():
            before = prev.get(name, 0)
            growth = ((d["n"] - before) / before * 100) if before else (100.0 if d["n"] > 1 else 0.0)
            out.append({"id": f"topic_{name.lower().replace(' ', '_')}", "name": name,
                        "description": d["sample"][:80], "article_count": d["n"],
                        "growth_percent": round(growth, 1)})
        out.sort(key=lambda t: (t["article_count"], t["growth_percent"]), reverse=True)
        return out[:limit]

    async def trending_repos(self, limit: int = 10) -> List[GithubRepo]:
        db = mongo.get_db()
        if db is None:
            return []
        since = datetime.utcnow() - timedelta(days=14)
        cur = db.articles.find({"related_repos.0": {"$exists": True}, "published_at": {"$gte": since}}).sort("trend_score", -1).limit(60)
        seen, out = set(), []
        async for d in cur:
            for r in d.get("related_repos", []):
                if r["id"] in seen:
                    continue
                seen.add(r["id"])
                out.append(GithubRepo(**r))
        out.sort(key=lambda r: r.stars, reverse=True)
        return out[:limit]

    async def funding_events(self, limit: int = 10) -> List[dict]:
        db = mongo.get_db()
        if db is None:
            return []
        since = datetime.utcnow() - timedelta(days=14)
        cur = db.articles.find({"topics": "Funding", "published_at": {"$gte": since}}).sort("published_at", -1).limit(40)
        out = []
        async for d in cur:
            a = _from_doc(d)
            m = _MONEY.search(f"{a.title} {a.summary or ''}")
            amount = 0.0
            if m:
                amount = float(m.group(1)) * (1e9 if m.group(2).lower().startswith("b") else 1e6)
            rm = re.search(r"\b(seed|pre-seed|series [a-f])\b", f"{a.title} {a.summary or ''}", re.I)
            out.append({"id": a.id, "company_name": (a.companies[0] if a.companies else a.source.name),
                        "round": (rm.group(1).title() if rm else "Round"), "amount_usd": amount,
                        "investors": a.companies[1:4], "description": a.title,
                        "announced_at": a.published_at.isoformat(), "article_id": a.id})
            if len(out) >= limit:
                break
        return out
