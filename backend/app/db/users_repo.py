"""User repository — persists app users in MongoDB (collection `users`),
keyed by Firebase `uid`. Falls back to an in-memory dict when Mongo is down.
"""
from __future__ import annotations

import threading
from datetime import datetime
from typing import Dict, List, Optional

from app.db import mongo
from app.schemas.user import NotificationMode, User

_mem: Dict[str, dict] = {}
_lock = threading.RLock()


def _to_user(doc: dict) -> User:
    return User(
        id=doc["uid"],
        email=doc.get("email") or "unknown@techinews.app",
        display_name=doc.get("display_name") or "TechiNews User",
        photo_url=doc.get("photo_url"),
        interests=doc.get("interests", []),
        notification_mode=doc.get("notification_mode", NotificationMode.daily_digest),
        is_premium=doc.get("is_premium", False),
        created_at=doc.get("created_at") or datetime.utcnow(),
    )


async def upsert_from_firebase(decoded: dict) -> User:
    """Create or update a user from Firebase token claims."""
    uid = decoded["uid"]
    now = datetime.utcnow()
    profile = {
        "email": decoded.get("email"),
        "display_name": decoded.get("name") or decoded.get("email", "").split("@")[0] or "TechiNews User",
        "photo_url": decoded.get("picture"),
    }
    defaults = {
        "uid": uid,
        "interests": [],
        "notification_mode": NotificationMode.daily_digest.value,
        "is_premium": False,
        "created_at": now,
    }
    db = mongo.get_db()
    if db is None:
        with _lock:
            doc = _mem.get(uid, {**defaults})
            doc.update(profile)
            _mem[uid] = doc
            return _to_user(doc)
    await db.users.update_one(
        {"uid": uid},
        {"$set": profile, "$setOnInsert": defaults},
        upsert=True,
    )
    doc = await db.users.find_one({"uid": uid})
    return _to_user(doc)


async def get(uid: str) -> Optional[User]:
    db = mongo.get_db()
    if db is None:
        with _lock:
            doc = _mem.get(uid)
            return _to_user(doc) if doc else None
    doc = await db.users.find_one({"uid": uid})
    return _to_user(doc) if doc else None


async def update_profile(
    uid: str,
    display_name: Optional[str] = None,
    interests: Optional[List[str]] = None,
    notification_mode: Optional[NotificationMode] = None,
) -> Optional[User]:
    changes: dict = {}
    if display_name is not None:
        changes["display_name"] = display_name
    if interests is not None:
        changes["interests"] = interests
    if notification_mode is not None:
        changes["notification_mode"] = (
            notification_mode.value
            if isinstance(notification_mode, NotificationMode)
            else notification_mode
        )
    if not changes:
        return await get(uid)

    db = mongo.get_db()
    if db is None:
        with _lock:
            doc = _mem.get(uid)
            if not doc:
                return None
            doc.update(changes)
            _mem[uid] = doc
            return _to_user(doc)
    await db.users.update_one({"uid": uid}, {"$set": changes})
    doc = await db.users.find_one({"uid": uid})
    return _to_user(doc) if doc else None


async def set_fcm_token(uid: str, token: str) -> None:
    """Store a device FCM token on the user (deduped)."""
    db = mongo.get_db()
    if db is None:
        with _lock:
            doc = _mem.setdefault(uid, {"uid": uid})
            tokens = set(doc.get("fcm_tokens", []))
            tokens.add(token)
            doc["fcm_tokens"] = list(tokens)
        return
    await db.users.update_one({"uid": uid}, {"$addToSet": {"fcm_tokens": token}})
