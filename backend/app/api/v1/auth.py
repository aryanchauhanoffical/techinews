"""Auth routes — Firebase ID-token verification + user profile in MongoDB.

In dev mode (Firebase not configured) these still work against a demo user,
so the Flutter app can be exercised before Firebase client wiring lands.
"""
from fastapi import APIRouter, Body, Depends, HTTPException, status

from app.core.deps import get_current_user
from app.db import users_repo
from app.schemas.user import User, UserUpdate
from app.services import firebase

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/verify", response_model=User)
async def verify_token(id_token: str = Body(..., embed=True)):
    """Verify a Firebase ID token; create/fetch the user. Returns the profile."""
    if not firebase.available():
        # Dev mode — no token verification available.
        return await get_current_user(authorization=None)
    try:
        decoded = firebase.verify_id_token(id_token)
    except Exception:  # noqa: BLE001
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired ID token",
        )
    return await users_repo.upsert_from_firebase(decoded)


@router.get("/me", response_model=User)
async def get_me(user: User = Depends(get_current_user)):
    return user


@router.patch("/me", response_model=User)
async def update_me(
    update: UserUpdate,
    user: User = Depends(get_current_user),
):
    updated = await users_repo.update_profile(
        user.id,
        display_name=update.display_name,
        interests=update.interests,
        notification_mode=update.notification_mode,
    )
    return updated or user


@router.post("/fcm-token")
async def register_fcm_token(
    token: str = Body(..., embed=True),
    user: User = Depends(get_current_user),
):
    """Register the device's FCM token for push notifications."""
    await users_repo.set_fcm_token(user.id, token)
    return {"ok": True}


@router.post("/logout")
async def logout():
    # Stateless: the client discards its ID token. Endpoint kept for symmetry.
    return {"ok": True}
