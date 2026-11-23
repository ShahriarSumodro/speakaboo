"""
Phase 6 Tests: Retention Engine & Daily Habit Loop.

Tests:
1. 7-day user activity / streak logic:
   - Consecutive daily practice increments streak
   - Streak freeze saves 1 missed day without losing streak
   - Streak repair restores broken streak without guilt
2. Character memory:
   - Stores learner name, goal, and last topic
   - Companion greets returning learner referencing past conversation
3. Retention API endpoints:
   - Word of the Day (bilingual English + Bengali)
   - Weekly recap / progress summary
   - Referral codes & viral reward loop
4. Retention analytics report script.
"""

import os
import uuid
import pytest
from httpx import AsyncClient, ASGITransport
from backend.main import app
from backend.models.user import User, UserProfile, AgeBand
from backend.repositories import get_repository
from backend.repositories.sqlite_repo import SqliteRepository
from backend.engine.auth_token import create_device_token
from backend.scripts.retention_report import generate_retention_report


@pytest.fixture
async def repo():
    return await get_repository()


@pytest.fixture
async def auth_headers(repo):
    user_id = f"user_ret_{uuid.uuid4()}"
    device_id = f"dev_ret_{uuid.uuid4()}"
    await repo.create_user(User(id=user_id, device_id=device_id))
    await repo.save_profile(UserProfile(
        user_id=user_id,
        display_name="Tanvir",
        age_band=AgeBand.TEEN,
        daily_goal_minutes=15,
        goal="ielts",
    ))
    token = create_device_token(user_id=user_id, device_id=device_id)
    return {"Authorization": f"Bearer {token}"}, user_id


@pytest.mark.asyncio
async def test_streak_consecutive_freeze_and_repair():
    """Verify streak increments on consecutive days, freeze saves 1 day, repair restores broken streak."""
    db_path = "test_phase6_streak_repo.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    isolated_repo = SqliteRepository(db_path=db_path)
    await isolated_repo.initialize()

    try:
        user_id = "user_streak_test"
        await isolated_repo.create_user(User(id=user_id, device_id="dev_streak"))

        # Day 1: Start streak
        p1 = await isolated_repo.record_activity(user_id, xp_earned=10, date="2026-11-01")
        assert p1.current_streak == 1

        # Day 2: Consecutive day
        p2 = await isolated_repo.record_activity(user_id, xp_earned=10, date="2026-11-02")
        assert p2.current_streak == 2
        assert p2.longest_streak == 2

        # Earn a streak freeze
        await isolated_repo.add_streak_freeze(user_id, count=1)

        # Miss Day 3, active on Day 4: Streak freeze should protect it (consumed 1 freeze)
        p3 = await isolated_repo.record_activity(user_id, xp_earned=10, date="2026-11-04")
        assert p3.current_streak == 3
        assert p3.streak_freeze_count == 0  # 1 freeze consumed

        # Miss Day 5 and Day 6, active on Day 7: Streak resets (no freezes left)
        p4 = await isolated_repo.record_activity(user_id, xp_earned=10, date="2026-11-07")
        assert p4.current_streak == 1
        assert p4.previous_streak == 3  # Previous streak preserved for recovery

        # Repair streak
        repaired, success = await isolated_repo.repair_streak(user_id)
        assert success is True
        assert repaired.current_streak == 4  # 3 (preserved) + 1 (today)
        assert repaired.streak_repaired is True

        # Attempting second repair without break should fail
        _, success_again = await isolated_repo.repair_streak(user_id)
        assert success_again is False
    finally:
        await isolated_repo.close()
        if os.path.exists(db_path):
            os.remove(db_path)


@pytest.mark.asyncio
async def test_character_memory_and_personalized_greeting(repo, auth_headers):
    """Verify character remembers name and last topic, and references them on return."""
    headers, user_id = auth_headers

    # Save character memory
    await repo.save_character_memory(
        user_id=user_id,
        character_id="rule_farmer",
        learner_name="Tanvir",
        last_topic="harvesting paddy in Comilla",
        goal="ielts_prep",
    )

    mem = await repo.get_character_memory(user_id, "rule_farmer")
    assert mem is not None
    assert mem["learner_name"] == "Tanvir"
    assert "harvesting paddy" in mem["last_topic"]

    # Start conversation with this character
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.post(
            "/api/conversation/start",
            headers=headers,
            json={"character_id": "rule_farmer", "user_id": user_id},
        )
        assert res.status_code == 200
        data = res.json()
        assert "conversation_id" in data
        assert "Tanvir" in data["greeting"]
        assert "harvesting paddy" in data["greeting"]


@pytest.mark.asyncio
async def test_word_of_the_day_endpoint(auth_headers):
    """Verify Word of the Day returns valid educational word with Bengali translation."""
    headers, _ = auth_headers
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/learning/word-of-the-day", headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert "word" in data
        assert "pronunciation" in data
        assert "bengali_meaning" in data
        assert "example" in data
        assert len(data["word"]) > 0
        assert len(data["bengali_meaning"]) > 0


@pytest.mark.asyncio
async def test_weekly_recap_and_referral_endpoints(auth_headers, repo):
    """Verify weekly recap calculations and referral code generation/claiming."""
    headers, user_id = auth_headers

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Weekly recap
        recap_res = await client.get(f"/api/learning/weekly-recap/{user_id}", headers=headers)
        assert recap_res.status_code == 200
        recap = recap_res.json()
        assert "streak_days" in recap
        assert "weekly_minutes" in recap
        assert "total_words_learned" in recap

        # Referral info
        ref_res = await client.get(f"/api/learning/referral/{user_id}", headers=headers)
        assert ref_res.status_code == 200
        ref_data = ref_res.json()
        assert "referral_code" in ref_data
        assert ref_data["referral_code"].startswith("SPK-")
        assert "referral_count" in ref_data

        # Claim referral reward
        claim_res = await client.post(
            "/api/learning/referral/claim",
            headers=headers,
            json={
                "referee_user_id": user_id,
                "referral_code": ref_data["referral_code"],
            },
        )
        assert claim_res.status_code == 200
        assert claim_res.json()["success"] is True


def test_retention_report_generation(tmp_path):
    """Verify the internal retention report script computes metrics correctly from SQLite."""
    db_file = str(tmp_path / "test_retention.db")
    isolated_repo = SqliteRepository(db_path=db_file)
    import asyncio
    asyncio.run(isolated_repo.initialize())
    asyncio.run(isolated_repo.close())

    report = generate_retention_report(db_path=db_file)
    assert "total_users" in report
    assert "total_turns" in report
    assert "day_1_retention_pct" in report
    assert "day_7_retention_pct" in report
    assert "active_streaks_count" in report
