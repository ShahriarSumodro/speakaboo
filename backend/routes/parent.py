"""
Parent Dashboard API routes.

Provides weekly spoken minutes, streaks, words learned, and safety flags summary.
"""

from typing import List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from backend.repositories import get_repository
from backend.repositories.sqlite_repo import BaseRepository

router = APIRouter(prefix="/api/parent", tags=["parent"])


class SafetyFlagResponse(BaseModel):
    id: str
    user_id: str
    category: str
    snippet: str
    created_at: float


class ParentSummaryResponse(BaseModel):
    user_id: str
    weekly_minutes_spoken: float
    weekly_turns_count: int
    current_streak: int
    longest_streak: int
    xp: int
    level: int
    total_words_learned: int
    safety_flags_count: int
    safety_flags_by_category: Dict[str, int]


@router.get("/{user_id}/summary", response_model=ParentSummaryResponse)
async def get_parent_summary(
    user_id: str, repo: BaseRepository = Depends(get_repository)
):
    """Get aggregated weekly activity, learning metrics, and safety flags."""
    summary = await repo.get_parent_summary(user_id)
    return ParentSummaryResponse(**summary)


@router.get("/{user_id}/safety-flags", response_model=List[SafetyFlagResponse])
async def get_safety_flags(
    user_id: str, limit: int = 50, repo: BaseRepository = Depends(get_repository)
):
    """Get recent safety incidents for the child."""
    flags = await repo.get_safety_flags(user_id, limit=limit)
    return [
        SafetyFlagResponse(
            id=f.id,
            user_id=f.user_id,
            category=f.category,
            snippet=f.snippet,
            created_at=f.created_at,
        )
        for f in flags
    ]
