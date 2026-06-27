"""Firebase Cloud Messaging (FCM) push sender.

Thin wrapper over firebase_admin.messaging. Callers must ensure Firebase is
initialized (see app.services.firebase.init); these functions raise if it isn't.
"""
from __future__ import annotations

import logging
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)


def send_to_token(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> str:
    """Send a notification to one device. Returns the FCM message ID."""
    from firebase_admin import messaging

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        token=token,
    )
    message_id = messaging.send(message)
    logger.info("FCM sent to 1 device: %s", message_id)
    return message_id


def send_to_tokens(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> dict:
    """Multicast to many devices. Returns success/failure counts."""
    from firebase_admin import messaging

    if not tokens:
        return {"success": 0, "failure": 0}
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        tokens=tokens,
    )
    resp = messaging.send_each_for_multicast(message)
    logger.info(
        "FCM multicast: %d ok, %d failed", resp.success_count, resp.failure_count
    )
    return {"success": resp.success_count, "failure": resp.failure_count}
