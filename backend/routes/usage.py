"""
Usage routes for Speakaboo.

Track and report real usage statistics per user from the database repository.
Enforces user token verification.
"""

import time
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from backend.config import load_settings
from backend.repositories import get_repository
from backend.repositories.sqlite_repo import dhaka_today
from backend.models.user import Plan
from backend.engine.auth_token import get_current_user_id, verify_user_access

router = APIRouter(prefix="/api/usage", tags=["usage"])


class UsageResponse(BaseModel):
    user_id: str
    date: str
    minutes_spoken: float
    turns_count: int
    daily_limit_minutes: int
    remaining_minutes: float


@router.get("/{user_id}/daily", response_model=UsageResponse)
async def get_daily_usage(
    user_id: str,
    current_user_id: str = Depends(get_current_user_id),
):
    """Get usage stats for today (Asia/Dhaka timezone) from repository."""
    verify_user_access(current_user_id, user_id)
    repo = await get_repository()
    today = dhaka_today()

    settings = load_settings()
    usage = await repo.get_daily_usage(user_id, today)
    user = await repo.get_user(user_id)
    ents = await repo.get_entitlements(user_id)
    now = time.time()
    has_active_plan_entitlement = any(
        e.type == "plan" and (e.expires_at is None or e.expires_at > now)
        for e in ents
    )

    daily_limit = settings.usage.free_daily_minutes
    if user and user.plan == Plan.PREMIUM:
        daily_limit = settings.usage.premium_daily_minutes
    elif (user and user.plan == Plan.BASIC) or has_active_plan_entitlement:
        daily_limit = settings.usage.basic_daily_minutes

    minutes = usage.minutes_spoken if usage else 0.0
    turns = usage.turns_count if usage else 0
    remaining = max(0.0, float(daily_limit) - minutes)

    return UsageResponse(
        user_id=user_id,
        date=today,
        minutes_spoken=round(minutes, 2),
        turns_count=turns,
        daily_limit_minutes=daily_limit,
        remaining_minutes=round(remaining, 2),
    )
