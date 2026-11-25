"""
Auth & Profile routes for Speakaboo.

Persistent device-based authentication using SQLite repository and cryptographically signed tokens.
Handles profile loading, updating, and secure parent PIN verification.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field

from backend.models.user import User, UserProfile, AgeBand, Plan
from backend.repositories import get_repository
from backend.engine.auth_token import (
    create_device_token, get_current_user_id, hash_pin, verify_pin,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])


class DeviceAuthRequest(BaseModel):
    device_id: str = Field(..., min_length=3, max_length=128)


class ProfileResponse(BaseModel):
    user_id: str
    display_name: str
    age_band: str
    goal: str
    level: str
    daily_goal_minutes: int
    reminder_time: str
    theme: str
    has_parent_pin: bool
    language: str


class DeviceAuthResponse(BaseModel):
    user_id: str
    token: str
    auth_token: Optional[str] = None
    is_new: bool
    plan: str
    display_name: str
    profile: ProfileResponse


class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = None
    age_band: Optional[str] = None
    goal: Optional[str] = None
    level: Optional[str] = None
    daily_goal_minutes: Optional[int] = None
    reminder_time: Optional[str] = None
    theme: Optional[str] = None
    language: Optional[str] = None


class SetParentPinRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=6)


class VerifyParentPinRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=6)


@router.post("/device", response_model=DeviceAuthResponse)
async def device_auth(request: DeviceAuthRequest):
    """Register or login with a device ID, backed by persistent repository.
    
    Returns a signed authentication token that must be passed as Bearer token.
    """
    if not request.device_id or not request.device_id.strip():
        raise HTTPException(status_code=400, detail="device_id is required")

    repo = await get_repository()
    device_id = request.device_id.strip()

    # Check for existing user by device ID
    user = await repo.get_user_by_device(device_id)
    is_new = False

    if not user:
        is_new = True
        user = User(
            device_id=device_id,
            display_name="Learner",
            plan=Plan.FREE,
        )
        user = await repo.create_user(user)

    # Load profile
    profile = await repo.get_profile(user.id)
    if not profile:
        profile = UserProfile(user_id=user.id, display_name=user.display_name or "Learner")
        profile = await repo.save_profile(profile)

    # Generate signed token
    token = create_device_token(user_id=user.id, device_id=device_id)

    profile_resp = ProfileResponse(
        user_id=user.id,
        display_name=profile.display_name,
        age_band=profile.age_band.value if isinstance(profile.age_band, AgeBand) else profile.age_band,
        goal=profile.goal,
        level=profile.level,
        daily_goal_minutes=profile.daily_goal_minutes,
        reminder_time=profile.reminder_time,
        theme=profile.theme,
        has_parent_pin=bool(profile.parent_pin_hash),
        language=profile.language,
    )

    return DeviceAuthResponse(
        user_id=user.id,
        token=token,
        auth_token=token,
        is_new=is_new,
        plan=user.plan.value,
        display_name=profile.display_name,
        profile=profile_resp,
    )


@router.get("/profile", response_model=ProfileResponse)
async def get_profile(current_user_id: str = Depends(get_current_user_id)):
    """Get the authenticated user's profile."""
    repo = await get_repository()
    profile = await repo.get_profile(current_user_id)
    if not profile:
        user = await repo.get_user(current_user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        profile = UserProfile(user_id=current_user_id, display_name=user.display_name or "Learner")
        profile = await repo.save_profile(profile)

    return ProfileResponse(
        user_id=profile.user_id,
        display_name=profile.display_name,
        age_band=profile.age_band.value if isinstance(profile.age_band, AgeBand) else profile.age_band,
        goal=profile.goal,
        level=profile.level,
        daily_goal_minutes=profile.daily_goal_minutes,
        reminder_time=profile.reminder_time,
        theme=profile.theme,
        has_parent_pin=bool(profile.parent_pin_hash),
        language=profile.language,
    )


@router.put("/profile", response_model=ProfileResponse)
async def update_profile(
    request: UpdateProfileRequest,
    current_user_id: str = Depends(get_current_user_id),
):
    """Update profile fields for the authenticated user."""
    repo = await get_repository()
    profile = await repo.get_profile(current_user_id)
    if not profile:
        profile = UserProfile(user_id=current_user_id)

    if request.display_name is not None:
        profile.display_name = request.display_name.strip()
        # Also update users table display name
        user = await repo.get_user(current_user_id)
        if user:
            user.display_name = profile.display_name
            await repo.update_user(user)

    if request.age_band is not None:
        try:
            profile.age_band = AgeBand(request.age_band.lower())
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid age_band: {request.age_band}. Must be kid, teen, or adult")

    if request.goal is not None:
        profile.goal = request.goal.strip()
    if request.level is not None:
        profile.level = request.level.strip()
    if request.daily_goal_minutes is not None:
        profile.daily_goal_minutes = max(1, min(180, request.daily_goal_minutes))
    if request.reminder_time is not None:
        profile.reminder_time = request.reminder_time.strip()
    if request.theme is not None:
        profile.theme = request.theme.strip()
    if request.language is not None:
        profile.language = request.language.strip()

    profile = await repo.save_profile(profile)

    return ProfileResponse(
        user_id=profile.user_id,
        display_name=profile.display_name,
        age_band=profile.age_band.value if isinstance(profile.age_band, AgeBand) else profile.age_band,
        goal=profile.goal,
        level=profile.level,
        daily_goal_minutes=profile.daily_goal_minutes,
        reminder_time=profile.reminder_time,
        theme=profile.theme,
        has_parent_pin=bool(profile.parent_pin_hash),
        language=profile.language,
    )


@router.post("/set-parent-pin")
async def set_parent_pin(
    request: SetParentPinRequest,
    current_user_id: str = Depends(get_current_user_id),
):
    """Set or update the 4-digit parent gate PIN."""
    if not request.pin.isdigit():
        raise HTTPException(status_code=400, detail="PIN must contain numbers only")

    repo = await get_repository()
    profile = await repo.get_profile(current_user_id)
    if not profile:
        profile = UserProfile(user_id=current_user_id)

    profile.parent_pin_hash = hash_pin(request.pin)
    await repo.save_profile(profile)

    return {"status": "ok", "message": "Parent PIN set successfully"}


@router.post("/verify-parent-pin")
async def verify_parent_pin_route(
    request: VerifyParentPinRequest,
    current_user_id: str = Depends(get_current_user_id),
):
    """Verify parent PIN against stored hash."""
    repo = await get_repository()
    profile = await repo.get_profile(current_user_id)
    if not profile or not profile.parent_pin_hash:
        raise HTTPException(status_code=400, detail="No parent PIN set for this account")

    if not verify_pin(request.pin, profile.parent_pin_hash):
        raise HTTPException(status_code=403, detail="Incorrect parent PIN")

    return {"status": "ok", "verified": True}
