from datetime import datetime

from fastapi import APIRouter, HTTPException

from app.schemas.user import User, UserUpdate

router = APIRouter(prefix="/auth", tags=["auth"])

# In-memory dev stub. Replace with Firebase Admin SDK token verification + MongoDB.
_FAKE_USER = User(
    id="mock_user_1",
    email="demo@techinews.app",
    display_name="Demo User",
    interests=["Artificial Intelligence", "Open Source", "Startups"],
    created_at=datetime.utcnow(),
)


@router.post("/verify", response_model=User)
async def verify_token(id_token: str | None = None):
    """Dev stub. Real impl: verify Firebase ID token, lookup/create user."""
    return _FAKE_USER


@router.get("/me", response_model=User)
async def get_me():
    return _FAKE_USER


@router.patch("/me", response_model=User)
async def update_me(update: UserUpdate):
    global _FAKE_USER
    data = _FAKE_USER.model_dump()
    if update.display_name:
        data["display_name"] = update.display_name
    if update.interests is not None:
        data["interests"] = update.interests
    if update.notification_mode is not None:
        data["notification_mode"] = update.notification_mode
    _FAKE_USER = User(**data)
    return _FAKE_USER


@router.post("/logout")
async def logout():
    return {"ok": True}
