"""FastAPI dependencies — request-scoped auth.

`get_current_user` verifies the `Authorization: Bearer <firebase_id_token>`
header. When Firebase isn't configured (local dev), it returns a stable dev
user so protected routes remain usable without real tokens.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from fastapi import Header, HTTPException, status

from app.db import users_repo
from app.schemas.user import User
from app.services import firebase

_DEV_USER = User(
    id="dev_user",
    email="demo@techinews.app",
    display_name="Demo User",
    interests=["Artificial Intelligence", "Open Source", "Startups"],
    created_at=datetime(2026, 1, 1),
)


async def get_current_user(
    authorization: Optional[str] = Header(default=None),
) -> User:
    # Dev mode: no Firebase → return the demo user (keeps the app usable locally).
    if not firebase.available():
        return _DEV_USER

    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header",
        )
    token = authorization.split(" ", 1)[1].strip()
    try:
        decoded = firebase.verify_id_token(token)
    except Exception:  # noqa: BLE001
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired ID token",
        )
    return await users_repo.upsert_from_firebase(decoded)
