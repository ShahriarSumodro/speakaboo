"""
Tests for Phase 5: Coaching Engine (Hat 2).

Verifies:
1. Spoken diagnostic placement evaluation and persistence.
2. Fluency mode (no interruption, recast only) vs Accuracy mode (1 correction max).
3. Hint and rescue ("Help me say it" sentence starters and model responses).
4. Session coaching metrics: learner vs bot talk time ratio, WPM, approximate clarity score, error patterns.
5. Bengali learner error categorization (articles, tenses, prepositions, agreement) and mistake log persistence.
6. Age-appropriate coaching (child vs adult persona adaptations).
"""

import pytest
import uuid
from starlette.testclient import TestClient

from backend.main import app
from backend.models.user import User
from backend.repositories import get_repository
from backend.engine.characters import load_character, build_system_prompt
from backend.engine.placement import evaluate_placement
from backend.engine.auth_token import create_device_token


@pytest.fixture
def client():
    return TestClient(app)


def test_placement_evaluation_levels():
    """Test CEFR placement evaluation with different speech complexities."""
    # A1 sample: few words, basic
    res_a1 = evaluate_placement("Hello I am Rahim. I like food.", duration_seconds=10.0)
    assert res_a1.cefr_level in ("A1", "A2")
    assert res_a1.level == "beginner"
    assert res_a1.wpm > 0

    # B1/B2 sample: longer, complex connectors, high vocabulary variety
    sample_b2 = (
        "In my opinion, I consider environmental conservation especially important for the future development "
        "of our community. Frequently, people do not realize the opportunity to improve daily waste management "
        "and achieve sustainable technology."
    )
    res_b2 = evaluate_placement(sample_b2, duration_seconds=25.0)
    assert res_b2.cefr_level in ("B1", "B2")
    assert res_b2.cefr_score >= 2.5
    assert len(res_b2.strengths) > 0
    assert len(res_b2.recommendations) > 0


def test_build_system_prompt_fluency_vs_accuracy():
    """Test pedagogy prompt customization for fluency vs accuracy mode and age bands."""
    char = load_character("rule_farmer")

    # Fluency mode prompt
    prompt_fluency = build_system_prompt(char, level="beginner", practice_mode="fluency")
    assert "PEDAGOGY - FLUENCY MODE" in prompt_fluency
    assert "Do NOT interrupt the learner's conversational flow" in prompt_fluency
    assert 'Set "correction": null' in prompt_fluency

    # Accuracy mode prompt
    prompt_accuracy = build_system_prompt(char, level="intermediate", practice_mode="accuracy", coach_mode="strict")
    assert "PEDAGOGY - ACCURACY MODE (STRICT)" in prompt_accuracy
    assert "pick at most ONE high-priority error" in prompt_accuracy

    # Kid age band prompt
    prompt_kid = build_system_prompt(char, level="beginner", age_band="kid")
    assert "CHILD LEARNER" in prompt_kid
    assert "Never use academic grammatical terms" in prompt_kid

    # Adult age band prompt
    prompt_adult = build_system_prompt(char, level="advanced", age_band="adult")
    assert "ADULT LEARNER" in prompt_adult


@pytest.mark.asyncio
async def test_placement_api_endpoint(client):
    """Test POST /api/conversation/placement persists evaluated level to profile."""
    repo = await get_repository()
    user_id = f"test-placement-{uuid.uuid4()}"
    dev_id = f"dev-{uuid.uuid4()}"
    await repo.create_user(User(id=user_id, device_id=dev_id))
    token = create_device_token(user_id, dev_id)

    payload = {
        "user_id": user_id,
        "spoken_text": (
            "I usually prefer studying English online because it offers great opportunities to improve my career. "
            "However, finding time every day is challenging although I definitely try my best."
        ),
        "duration_seconds": 20.0,
    }

    resp = client.post(
        "/api/conversation/placement",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == user_id
    assert "cefr_level" in data
    assert "wpm" in data
    assert "recommendations" in data

    # Verify updated in database profile
    profile = await repo.get_profile(user_id)
    assert profile.level == data["level"]


@pytest.mark.asyncio
async def test_conversation_hint_and_summary_flow(client):
    """Test conversation start, turns, hint assistance, and session summary."""
    repo = await get_repository()
    user_id = f"test-coach-{uuid.uuid4()}"
    dev_id = f"dev-{uuid.uuid4()}"
    await repo.create_user(User(id=user_id, device_id=dev_id))

    # 1. Start conversation in fluency mode
    start_resp = client.post(
        "/api/conversation/start",
        json={
            "user_id": user_id,
            "character_id": "rule_farmer",
            "practice_mode": "fluency",
            "coach_mode": "gentle",
        },
    )
    assert start_resp.status_code == 200
    cid = start_resp.json()["conversation_id"]

    # 2. Request hint ("Help me say it")
    hint_resp = client.post("/api/conversation/hint", json={"conversation_id": cid})
    assert hint_resp.status_code == 200
    h_data = hint_resp.json()
    assert "sentence_starter" in h_data
    assert "model_answer" in h_data
    assert len(h_data["vocabulary_hints"]) > 0

    # 3. Simulate turn with audio file (mock audio)
    fake_wav = b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00"
    turn_resp = client.post(
        "/api/conversation/turn",
        data={"conversation_id": cid, "audio_format": "wav"},
        files={"audio": ("turn.wav", fake_wav, "audio/wav")},
    )
    assert turn_resp.status_code == 200

    # 4. Request session summary
    summary_resp = client.post("/api/conversation/summary", json={"conversation_id": cid})
    assert summary_resp.status_code == 200
    s_data = summary_resp.json()
    assert s_data["conversation_id"] == cid
    assert "learner_talk_time_seconds" in s_data
    assert "bot_talk_time_seconds" in s_data
    assert "talk_time_ratio" in s_data
    assert "wpm" in s_data
    assert "clarity_indicator" in s_data
    assert "Approximate Clarity" in s_data["clarity_indicator"]["label"]
    assert "Not phonetic lab scoring" in s_data["clarity_indicator"]["note"]
    assert "tomorrow_hook" in s_data
    assert len(s_data["strengths"]) > 0
    assert len(s_data["patterns_to_work_on"]) > 0


@pytest.mark.asyncio
async def test_error_categorization_and_mistakes_route(client):
    """Test that grammar corrections are categorized into mistake logs and accessible via route."""
    from backend.routes.conversation import _categorize_error
    from backend.models.user import MistakeLog

    assert _categorize_error("I saw a elephant", "I saw an elephant", "use an before vowels") == "articles"
    assert _categorize_error("Yesterday I go home", "Yesterday I went home", "past tense of go is went") == "tenses_and_verbs"
    assert _categorize_error("I am sitting in the table", "I am sitting at the table", "use at for tables") == "prepositions"
    assert _categorize_error("They is playing", "They are playing", "subject-verb agreement for plural") == "subject_verb_agreement"

    repo = await get_repository()
    user_id = f"test-mistakes-{uuid.uuid4()}"
    dev_id = f"dev-{uuid.uuid4()}"
    await repo.create_user(User(id=user_id, device_id=dev_id))
    token = create_device_token(user_id, dev_id)

    # Log two sample mistakes
    await repo.log_mistake(
        MistakeLog(
            user_id=user_id,
            category="articles",
            original="I saw a elephant",
            better="I saw an elephant",
        )
    )
    await repo.log_mistake(
        MistakeLog(
            user_id=user_id,
            category="tenses_and_verbs",
            original="He go there",
            better="He went there",
        )
    )

    resp = client.get(
        f"/api/conversation/mistakes/{user_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 2
    cats = {m["category"] for m in data}
    assert "articles" in cats
    assert "tenses_and_verbs" in cats
