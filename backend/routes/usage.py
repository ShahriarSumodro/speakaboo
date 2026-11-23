"""
Usage routes for Speakaboo.

Track and report usage statistics per user.
"""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/usage", tags=["usage"])


class UsageResponse(BaseModel):
    user_id: str
    date: str
    minutes_spoken: float
    turns_count: int
    daily_limit_minutes: int
    remaining_minutes: float


@router.get("/{user_id}/daily", response_model=UsageResponse)
async def get_daily_usage(user_id: str):
    """Get usage stats for today (Asia/Dhaka timezone).
    
    Currently returns mock data. Will integrate with repository.
    """
    from backend.repositories.sqlite_repo import dhaka_today

    today = dhaka_today()
    daily_limit = 10  # Free tier default

    return UsageResponse(
        user_id=user_id,
        date=today,
        minutes_spoken=0.0,
        turns_count=0,
        daily_limit_minutes=daily_limit,
        remaining_minutes=float(daily_limit),
    )
