"""
Daily Missions Engine for Speakaboo.

Data-driven missions: "speak 5 minutes", "use 3 new words", "finish one scene".
Tracks daily progress, checks completion, awards XP upon claim.
"""

import logging
from typing import List, Optional
from backend.repositories.sqlite_repo import (
    BaseRepository, DEFAULT_MISSIONS, dhaka_today,
)
from backend.models.learning import UserMissionProgress, Mission

logger = logging.getLogger("speakaboo.engine.missions")


class MissionsEngine:
    """Manages daily missions for learners."""

    def __init__(self, repo: BaseRepository):
        self.repo = repo

    def get_mission_definitions(self) -> List[Mission]:
        """Return available mission definitions."""
        return DEFAULT_MISSIONS

    async def get_user_missions(
        self, user_id: str, date: Optional[str] = None
    ) -> List[dict]:
        """Get user's daily missions with definitions and progress."""
        progress_list = await self.repo.get_daily_missions(user_id, date)
        result = []
        for p in progress_list:
            m_def = next((m for m in DEFAULT_MISSIONS if m.id == p.mission_id), None)
            if m_def:
                result.append({
                    "id": p.id,
                    "mission_id": m_def.id,
                    "title": m_def.title,
                    "description": m_def.description,
                    "type": m_def.type,
                    "target": m_def.target,
                    "current_value": round(p.current_value, 1),
                    "xp_reward": m_def.xp_reward,
                    "completed": p.completed,
                    "reward_claimed": p.reward_claimed,
                })
        return result

    async def track_speaking_time(
        self, user_id: str, minutes: float, date: Optional[str] = None
    ) -> List[UserMissionProgress]:
        """Track spoken minutes towards daily missions."""
        return await self.repo.update_mission_progress(
            user_id, mission_type="speak_time", increment=minutes, date=date
        )

    async def track_new_words(
        self, user_id: str, word_count: int, date: Optional[str] = None
    ) -> List[UserMissionProgress]:
        """Track new words learned towards daily missions."""
        return await self.repo.update_mission_progress(
            user_id, mission_type="new_words", increment=float(word_count), date=date
        )

    async def track_scenario_completed(
        self, user_id: str, date: Optional[str] = None
    ) -> List[UserMissionProgress]:
        """Track scenario completion towards daily missions."""
        return await self.repo.update_mission_progress(
            user_id, mission_type="complete_scene", increment=1.0, date=date
        )

    async def track_shadowing_completed(
        self, user_id: str, date: Optional[str] = None
    ) -> List[UserMissionProgress]:
        """Track shadowing completion towards daily missions."""
        return await self.repo.update_mission_progress(
            user_id, mission_type="shadowing", increment=1.0, date=date
        )

    async def claim_reward(
        self, user_id: str, mission_id: str, date: Optional[str] = None
    ) -> Optional[int]:
        """Claim XP reward for a completed mission."""
        return await self.repo.claim_mission_reward(user_id, mission_id, date)
