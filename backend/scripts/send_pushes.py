"""Push job. Runs right after the collector in the hourly cron.

  instant  — stories scoring >= 85 published in the last 3 h, not yet pushed,
             to users on `instant`. At most 2 per run so nobody gets spammed.
  daily    — once a day at the 08:00 IST run: top 5 of the last 24 h to users
             on `daily_digest`.
  weekly   — Sundays at the same hour: top 10 of the week to `weekly_digest`.

Every push carries the story image (FCM `image`), the article id for deep
linking, and is recorded in `pushes` so re-runs never double-send.

Usage: python scripts/send_pushes.py [--dry-run] [--force-digest daily|weekly]
"""
from __future__ import annotations

import argparse
import asyncio
import json
import logging
import sys
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import mongo  # noqa: E402
from app.services import firebase  # noqa: E402
from app.services.article_repo import _from_doc  # noqa: E402
from app.services.ai import push_copy  # noqa: E402
from app.services.notifications import send_to_tokens  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-7s %(name)s — %(message)s")
log = logging.getLogger("pushes")

DIGEST_HOUR_UTC = 2  # 08:00 IST edition; the :37 cron lands at 08:07 IST
INSTANT_MIN_SCORE = 85
# Pop-art bell shown as the notification's large icon when a story has no image.
BELL_IMAGE = "https://ajycieqvkssmbuctnqib.supabase.co/storage/v1/object/public/images/brand/notification-bell.jpg"


def _hook(a) -> str | None:
    return a.related_repos[0].hook if a.related_repos and a.related_repos[0].hook else None


async def _tokens_for(db, mode: str) -> list[str]:
    tokens: list[str] = []
    async for u in db.users.find({"notification_mode": mode, "fcm_tokens.0": {"$exists": True}}, {"fcm_tokens": 1}):
        tokens.extend(u.get("fcm_tokens", []))
    return sorted(set(tokens))


async def _send(db, key: str, kind: str, tokens: list[str], title: str, body: str, article_id: str, image: str | None, dry: bool) -> dict:
    if await db.pushes.find_one({"_id": key}):
        return {"skipped": "already sent"}
    if not tokens:
        await db.pushes.insert_one({"_id": key, "kind": kind, "at": datetime.utcnow(), "sent": 0, "note": "no recipients"})
        return {"skipped": "no recipients"}
    if dry:
        log.info("DRY %s -> %d tokens | %s", kind, len(tokens), title)
        return {"dry": len(tokens)}
    res = send_to_tokens(tokens, title, body, data={"article_id": article_id, "kind": kind}, image=image)
    await db.pushes.insert_one({"_id": key, "kind": kind, "at": datetime.utcnow(), "sent": res["success"], "failed": res["failure"], "article_id": article_id})
    return res


async def instant(db, dry: bool) -> list:
    since = datetime.utcnow() - timedelta(hours=3)
    tokens = await _tokens_for(db, "instant")
    out = []
    cur = db.articles.find({"trend_score": {"$gte": INSTANT_MIN_SCORE}, "published_at": {"$gte": since}}).sort("trend_score", -1).limit(2)
    async for d in cur:
        a = _from_doc(d)
        copy = await push_copy.write(a.title, a.summary or "", a.topics, hook=_hook(a), breaking=True)
        out.append(await _send(db, f"instant:{a.id}", "breaking", tokens, copy.title, copy.body, a.id, a.image_url or BELL_IMAGE, dry))
    return out


async def digest(db, kind: str, dry: bool) -> dict:
    now = datetime.utcnow()
    hours, mode, n = (24, "daily_digest", 5) if kind == "daily" else (168, "weekly_digest", 10)
    tokens = await _tokens_for(db, mode)
    top = [_from_doc(d) async for d in db.articles.find({"published_at": {"$gte": now - timedelta(hours=hours)}}).sort("trend_score", -1).limit(n)]
    if not top:
        return {"skipped": "no stories"}
    lead = top[0]
    # Digest = the lead story sold like a push, with the count as the kicker.
    # "☕ 5 stories before standup" outperforms "Your daily digest".
    lead_copy = await push_copy.write(lead.title, lead.summary or "", lead.topics, hook=_hook(lead))
    n = len(top)
    title = f"☕ {n} stories before standup" if kind == "daily" else f"☕ The week in {n} stories"
    body = lead_copy.title.split(" ", 1)[-1] if lead_copy.title else lead.title
    body = f"{body}. Plus {n - 1} more." if len(body) <= 74 else body[:90]
    key = f"{kind}:{now:%Y-%m-%d}"
    return await _send(db, key, "digest", tokens, title, body, lead.id, lead.image_url or BELL_IMAGE, dry)


async def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--force-digest", choices=["daily", "weekly"])
    args = p.parse_args()

    if not firebase.init() and not args.dry_run:
        log.error("Firebase not configured; nothing sent")
        return 1
    await mongo.connect()
    db = mongo.get_db()
    if db is None:
        log.error("Mongo not connected")
        return 1
    try:
        now = datetime.utcnow()
        report = {"instant": await instant(db, args.dry_run)}
        if args.force_digest == "daily" or now.hour == DIGEST_HOUR_UTC:
            report["daily"] = await digest(db, "daily", args.dry_run)
        if args.force_digest == "weekly" or (now.hour == DIGEST_HOUR_UTC and now.weekday() == 6):
            report["weekly"] = await digest(db, "weekly", args.dry_run)
        print(json.dumps(report, default=str, indent=2))
    finally:
        await mongo.close()
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
