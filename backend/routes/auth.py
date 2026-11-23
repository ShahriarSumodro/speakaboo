"""
Auth routes for Speakaboo.

Device-based anonymous auth (upgradeable to login later).
"""

import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from backend.models.user import User, Plan

router = APIRouter(prefix="/api/auth", tags=["auth"])

# In-memory store for now — will use repository in integration
_users: dict[str, User] = {}
_device_to_user: dict[str, str] = {}


class DeviceAuthRequest(BaseModel):
    device_id: str


class DeviceAuthResponse(BaseModel):
    user_id: str
    is_new: bool
    plan: str
    display_name: str


@router.post("/device", response_model=DeviceAuthResponse)
async def device_auth(request: DeviceAuthRequest):
    """Register or login with a device ID.
    
    If the device_id is already registered, returns the existing user.
    Otherwise, creates a new anonymous user.
    """
    if not request.device_id:
        raise HTTPException(status_code=400, detail="device_id is required")

    # Check for existing user
    if request.device_id in _device_to_user:
        user_id = _device_to_user[request.device_id]
        user = _users[user_id]
        return DeviceAuthResponse(
            user_id=user.id,
            is_new=False,
            plan=user.plan.value,
            display_name=user.display_name,
        )

    # Create new user
    user = User(
        device_id=request.device_id,
        plan=Plan.FREE,
    )
    _users[user.id] = user
    _device_to_user[request.device_id] = user.id

    return DeviceAuthResponse(
        user_id=user.id,
        is_new=True,
        plan=user.plan.value,
        display_name=user.display_name,
    )
