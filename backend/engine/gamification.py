"""
Gamification Engine for Speakaboo.

Handles XP, levels, and daily streak logic with Asia/Dhaka timezone rollover.
"""

import logging
from typing import Optional, Tuple
from backend.repositories.sqlite_repo import (
    BaseRepository, dhaka_today, calculate_level,
)
from backend.models.learning import UserProgress

logger = logging.getLogger("speakaboo.engine.gamification")

# XP Rewards
XP_PER_TURN = 10
XP_PER_MINUTE_SPOKEN = 20
XP_SHADOWING_COMPLETED = 40
XP_SCENARIO_COMPLETED = 60


class GamificationEngine:
    """Manages XP awards, level progression, and streak calculations."""

    def __init__(self, repo: BaseRepository):
        self.repo = repo

    async def get_progress(self, user_id: str) -> UserProgress:
        """Get user's current progress."""
        return await self.repo.get_progress(user_id)

    async def on_turn_completed(
        self, user_id: str, minutes_spoken: float = 0.0, date: Optional[str] = None
    ) -> Tuple[UserProgress, int]:
        """Reward XP for a completed speaking turn and record daily streak activity."""
        xp_earned = XP_PER_TURN + int(minutes_spoken * XP_PER_MINUTE_SPOKEN)
        progress = await self.repo.record_activity(user_id, xp_earned=xp_earned, date=date)
        return progress, xp_earned

    async def on_shadowing_completed(
        self, user_id: str, accuracy_score: float, date: Optional[str] = None
    ) -> Tuple[UserProgress, int]:
        """Reward XP for shadowing based on accuracy."""
        # Scale bonus: up to 100% bonus for high accuracy
        bonus = int((accuracy_score / 100.0) * 20)
        total_xp = XP_SHADOWING_COMPLETED + bonus
        progress = await self.repo.record_activity(user_id, xp_earned=total_xp, date=date)
        return progress, total_xp

    async def on_scenario_completed(
        self, user_id: str, date: Optional[str] = None
    ) -> Tuple[UserProgress, int]:
        """Reward XP for completing a real-life scenario."""
        progress = await self.repo.record_activity(
            user_id, xp_earned=XP_SCENARIO_COMPLETED, date=date
        )
        return progress, XP_SCENARIO_COMPLETED

    async def use_streak_freeze(self, user_id: str) -> UserProgress:
        """Add a streak freeze to the user's inventory."""
        return await self.repo.add_streak_freeze(user_id, count=1)
