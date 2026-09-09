"""Firebase Admin SDK bootstrap + ID-token verification.

Init is best-effort: if no service-account path is configured (or the file is
missing), `available()` stays False and auth falls back to a dev user — so the
backend still boots in environments without Firebase credentials.
"""
from __future__ import annotations

import logging

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_app = None
_initialized = False


def init() -> bool:
    """Initialize the Admin SDK once. Returns True if available."""
    global _app, _initialized
    if _initialized:
        return _app is not None
    _initialized = True

    s = get_settings()
    raw_json = getattr(s, "FIREBASE_CREDENTIALS_JSON", "") or ""
    path = s.FIREBASE_CREDENTIALS_PATH
    if not raw_json and not path:
        logger.warning("FIREBASE_CREDENTIALS_JSON/PATH unset — auth runs in dev mode")
        return False
    try:
        import json

        import firebase_admin
        from firebase_admin import credentials

        # CI passes the service account as one JSON string; local dev uses a file.
        cred = credentials.Certificate(json.loads(raw_json) if raw_json else path)
        _app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized: project=%s", _app.project_id)
        return True
    except Exception as e:  # noqa: BLE001
        logger.warning("Firebase init failed (%s) — auth runs in dev mode", e)
        _app = None
        return False


def available() -> bool:
    return _app is not None


def verify_id_token(id_token: str) -> dict:
    """Verify a Firebase ID token and return the decoded claims. Raises on invalid."""
    from firebase_admin import auth

    return auth.verify_id_token(id_token)
