"""Inbox derived from stored stories. Nothing is invented: a digest is the
top stories of the last 24h, breaking = score >= 85 in the last 12h, github =
repo-linked stories with the most stars. Read state lives on the device."""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter

from app.db import mongo
from app.services.article_repo import _from_doc

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _item(kind: str, nid: str, title: str, body: str, at: datetime, article_id: str | None = None, image: str | None = None) -> dict:
    return {"id": nid, "kind": kind, "title": title, "body": body, "article_id": article_id,
            "image_url": image, "received_at": at.isoformat()}


@router.get("")
async def inbox() -> List[dict]:
    db = mongo.get_db()
    if db is None:
        return []
    now = datetime.utcnow()
    out: List[dict] = []

    # Breaking: high-score stories from the last 12 hours.
    cur = db.articles.find({"trend_score": {"$gte": 85}, "published_at": {"$gte": now - timedelta(hours=12)}}).sort("trend_score", -1).limit(3)
    async for d in cur:
        a = _from_doc(d)
        out.append(_item("breaking", f"brk_{a.id}", a.title, a.summary or a.source.name, a.published_at, a.id, a.image_url))

    # Daily digest: the 8:00 edition, built from the top 5 of the prior 24h.
    edition = now.replace(hour=2, minute=30, second=0, microsecond=0)  # 08:00 IST
    if edition > now:
        edition -= timedelta(days=1)
    top = [_from_doc(d) async for d in db.articles.find({"published_at": {"$gte": edition - timedelta(hours=24), "$lt": edition}})
           .sort("trend_score", -1).limit(5)]
    if top:
        names = ", ".join(a.source.name for a in top[:3])
        out.append(_item("digest", f"dig_{edition:%Y%m%d}", f"Your daily digest: {len(top)} stories",
                         f"Leading with {top[0].title[:70]}. Sources include {names}.", edition, top[0].id, top[0].image_url))

    # GitHub: the most-starred repo-linked story of the last 3 days.
    cur = db.articles.find({"related_repos.0": {"$exists": True}, "published_at": {"$gte": now - timedelta(days=3)}}).sort("trend_score", -1).limit(2)
    async for d in cur:
        a = _from_doc(d)
        r = a.related_repos[0]
        out.append(_item("githubTrend", f"gh_{a.id}", f"{r.full_name} is climbing", f"{r.stars:,} stars, {r.language or 'mixed'}. {r.description[:90]}", a.published_at, a.id, a.image_url))

    # Funding mentions from the last week.
    cur = db.articles.find({"topics": "Funding", "published_at": {"$gte": now - timedelta(days=7)}}).sort("published_at", -1).limit(2)
    async for d in cur:
        a = _from_doc(d)
        out.append(_item("funding", f"fund_{a.id}", a.title, a.summary or "", a.published_at, a.id, a.image_url))

    out.sort(key=lambda n: n["received_at"], reverse=True)
    return out[:20]
