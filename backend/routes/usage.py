"""
Usage routes for Speakaboo.

Track and report real usage statistics per user from the database repository.
Enforces user token verification.
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel

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

    usage = await repo.get_daily_usage(user_id, today)
    user = await repo.get_user(user_id)

    daily_limit = 10
    if user:
        if user.plan == Plan.BASIC:
            daily_limit = 30
        elif user.plan == Plan.PREMIUM:
            daily_limit = 120

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
