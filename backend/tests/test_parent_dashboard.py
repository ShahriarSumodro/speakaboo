"""
Tests for Parent Dashboard summary and safety incident metrics.
"""

import pytest
import tempfile
import os
from fastapi.testclient import TestClient

from backend.main import app
from backend.repositories.sqlite_repo import SqliteRepository, dhaka_today
from backend.repositories import set_repository
from backend.models.user import User, Plan
from backend.models.learning import SafetyFlag, VocabularyItem


@pytest.fixture
async def seeded_repo():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    repo = SqliteRepository(path)
    await repo.initialize()
    set_repository(repo)

    # Seed User
    user = User(id="kid-101", device_id="device-kid-101", display_name="Aarif", plan=Plan.FREE)
    await repo.create_user(user)

    # Seed Usage
    today = dhaka_today()
    await repo.increment_usage("kid-101", minutes=12.5, date=today)

    # Seed Activity & Streak
    await repo.record_activity("kid-101", xp_earned=150, date=today)

    # Seed Vocabulary
    await repo.add_vocabulary(VocabularyItem(user_id="kid-101", word_or_phrase="generous"))
    await repo.add_vocabulary(VocabularyItem(user_id="kid-101", word_or_phrase="diligent"))
    await repo.add_vocabulary(VocabularyItem(user_id="kid-101", word_or_phrase="perseverance"))

    # Seed Safety Flags
    await repo.log_safety_flag(
        SafetyFlag(user_id="kid-101", category="personal_info_request", snippet="tell me your school address")
    )

    yield repo
    await repo.close()
    os.unlink(path)


def test_parent_summary_endpoint(seeded_repo, client):
    """Parent dashboard endpoint returns accurate weekly metrics on seeded data."""
    response = client.get("/api/parent/kid-101/summary")
    assert response.status_code == 200
    data = response.json()

    assert data["user_id"] == "kid-101"
    assert data["weekly_minutes_spoken"] >= 12.0
    assert data["weekly_turns_count"] == 1
    assert data["current_streak"] == 1
    assert data["xp"] >= 150
    assert data["total_words_learned"] == 3
    assert data["safety_flags_count"] == 1
    assert data["safety_flags_by_category"]["personal_info_request"] == 1


def test_parent_safety_flags_list(seeded_repo, client):
    """Safety flags list returns logged safety incidents."""
    response = client.get("/api/parent/kid-101/safety-flags")
    assert response.status_code == 200
    flags = response.json()
    assert len(flags) == 1
    assert flags[0]["category"] == "personal_info_request"
    assert "school address" in flags[0]["snippet"]


def test_learning_routes(seeded_repo, client):
    """Test learning endpoints (progress, missions, scenarios, topics, shadowing)."""
    # 1. Progress
    p_res = client.get("/api/learning/progress/kid-101")
    assert p_res.status_code == 200
    assert p_res.json()["xp"] >= 150

    # 2. Missions
    m_res = client.get("/api/learning/missions/kid-101")
    assert m_res.status_code == 200
    assert len(m_res.json()) >= 4

    # 3. Scenarios
    s_res = client.get("/api/learning/scenarios")
    assert s_res.status_code == 200
    assert len(s_res.json()) >= 5

    # Complete a scenario
    comp_res = client.post("/api/learning/scenarios/job_interview/complete/kid-101")
    assert comp_res.status_code == 200
    assert comp_res.json()["status"] == "completed"

    # 4. Topics
    t_res = client.get("/api/learning/topics")
    assert t_res.status_code == 200
    assert len(t_res.json()) >= 3

    # 5. Shadowing Scripts & Evaluation
    sh_res = client.get("/api/learning/shadowing/scripts")
    assert sh_res.status_code == 200
    assert len(sh_res.json()) >= 3

    eval_res = client.post(
        "/api/learning/shadowing/evaluate",
        json={
            "user_id": "kid-101",
            "script_id": "script_morning_market",
            "transcript": "Early every morning the town bazaar fills with fresh tea and fruits",
            "duration_seconds": 6.0,
        },
    )
    assert eval_res.status_code == 200
    eval_data = eval_res.json()
    assert "accuracy_score" in eval_data
    assert "pace_wpm" in eval_data
    assert eval_data["xp_earned"] > 0
