"""
Tests for gamification, XP progression, and Asia/Dhaka daily streaks.
"""

import pytest
import tempfile
import os
from backend.repositories.sqlite_repo import (
    SqliteRepository, dhaka_today, dhaka_date_add, calculate_level,
)
from backend.engine.gamification import GamificationEngine


@pytest.fixture
async def repo():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    r = SqliteRepository(path)
    await r.initialize()
    yield r
    await r.close()
    os.unlink(path)


@pytest.fixture
def engine(repo):
    return GamificationEngine(repo)


class TestGamification:

    @pytest.mark.asyncio
    async def test_initial_progress(self, engine):
        prog = await engine.get_progress("user-100")
        assert prog.user_id == "user-100"
        assert prog.xp == 0
        assert prog.level == 1
        assert prog.current_streak == 0
        assert prog.longest_streak == 0

    @pytest.mark.asyncio
    async def test_turn_awards_xp_and_starts_streak(self, engine):
        prog, xp = await engine.on_turn_completed("user-100", minutes_spoken=0.5)
        assert xp >= 10
        assert prog.xp == xp
        assert prog.current_streak == 1
        assert prog.longest_streak == 1
        assert prog.last_active_date == dhaka_today()

    @pytest.mark.asyncio
    async def test_same_day_activity_maintains_streak(self, engine):
        today = dhaka_today()
        await engine.on_turn_completed("user-100", date=today)
        prog, _ = await engine.on_turn_completed("user-100", date=today)
        # Streak does not increment twice in same Dhaka day
        assert prog.current_streak == 1

    @pytest.mark.asyncio
    async def test_consecutive_day_increments_streak(self, repo, engine):
        day1 = "2026-11-20"
        day2 = "2026-11-21"
        day3 = "2026-11-22"

        await repo.record_activity("user-101", xp_earned=10, date=day1)
        p2 = await repo.record_activity("user-101", xp_earned=10, date=day2)
        assert p2.current_streak == 2
        assert p2.longest_streak == 2

        p3 = await repo.record_activity("user-101", xp_earned=10, date=day3)
        assert p3.current_streak == 3
        assert p3.longest_streak == 3

    @pytest.mark.asyncio
    async def test_missed_day_without_freeze_resets_streak(self, repo):
        day1 = "2026-11-20"
        day3 = "2026-11-22"  # Missed day 21

        await repo.record_activity("user-102", xp_earned=10, date=day1)
        p = await repo.record_activity("user-102", xp_earned=10, date=day3)
        assert p.current_streak == 1

    @pytest.mark.asyncio
    async def test_streak_freeze_protects_missed_day(self, repo):
        day1 = "2026-11-20"
        day3 = "2026-11-22"  # Missed day 21

        # Add a streak freeze
        await repo.add_streak_freeze("user-103", count=1)
        await repo.record_activity("user-103", xp_earned=10, date=day1)

        # Activity on day 3 should consume streak freeze and maintain streak
        p = await repo.record_activity("user-103", xp_earned=10, date=day3)
        assert p.current_streak == 2
        assert p.streak_freeze_count == 0  # Freeze consumed

    def test_level_progression(self):
        assert calculate_level(0) == 1
        assert calculate_level(50) == 1
        assert calculate_level(100) == 2
        assert calculate_level(500) > 2
