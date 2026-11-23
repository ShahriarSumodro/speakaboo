"""
Tests for Daily Missions Engine.
"""

import pytest
import tempfile
import os
from backend.repositories.sqlite_repo import SqliteRepository
from backend.engine.missions import MissionsEngine


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
    return MissionsEngine(repo)


class TestMissions:

    @pytest.mark.asyncio
    async def test_seeds_default_missions(self, engine):
        missions = await engine.get_user_missions("user-200")
        assert len(missions) == 4
        types = [m["type"] for m in missions]
        assert "speak_time" in types
        assert "new_words" in types
        assert "complete_scene" in types
        assert "shadowing" in types

    @pytest.mark.asyncio
    async def test_speaking_time_progresses_and_completes_mission(self, engine):
        # Target for m_speak_3m is 3.0 min
        await engine.track_speaking_time("user-200", 1.5)
        m = (await engine.get_user_missions("user-200"))[0]
        assert m["current_value"] == 1.5
        assert not m["completed"]

        await engine.track_speaking_time("user-200", 2.0)
        m = (await engine.get_user_missions("user-200"))[0]
        assert m["current_value"] >= 3.0
        assert m["completed"]

    @pytest.mark.asyncio
    async def test_claim_reward_awards_xp(self, engine, repo):
        # Complete mission
        await engine.track_speaking_time("user-201", 3.5)
        missions = await engine.get_user_missions("user-201")
        speak_mission = next(m for m in missions if m["type"] == "speak_time")
        assert speak_mission["completed"]

        # Claim reward
        xp = await engine.claim_reward("user-201", speak_mission["mission_id"])
        assert xp == speak_mission["xp_reward"]

        # User progress should reflect claimed XP
        prog = await repo.get_progress("user-201")
        assert prog.xp >= xp

        # Cannot claim twice
        xp_again = await engine.claim_reward("user-201", speak_mission["mission_id"])
        assert xp_again is None
