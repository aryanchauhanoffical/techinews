"""Deterministic, stable IDs.

`hash()` is salted per-process (PYTHONHASHSEED), so it cannot be used for
persistent document IDs — the same URL would map to a different ID on every
restart, breaking `/articles/{id}` lookups against a stored feed. Use a stable
content hash instead.
"""
from __future__ import annotations

import hashlib


def make_article_id(url: str) -> str:
    digest = hashlib.md5(url.strip().lower().encode("utf-8")).hexdigest()[:16]
    return f"article_{digest}"
