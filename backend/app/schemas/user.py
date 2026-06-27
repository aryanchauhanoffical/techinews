from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, EmailStr


class NotificationMode(str, Enum):
    instant = "instant"
    daily_digest = "daily_digest"
    weekly_digest = "weekly_digest"
    silent = "silent"


class User(BaseModel):
    id: str
    email: EmailStr
    display_name: str
    photo_url: Optional[str] = None
    interests: List[str] = []
    notification_mode: NotificationMode = NotificationMode.daily_digest
    is_premium: bool = False
    created_at: datetime


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    interests: Optional[List[str]] = None
    notification_mode: Optional[NotificationMode] = None
