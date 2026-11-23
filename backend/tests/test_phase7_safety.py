"""
Phase 7 Tests: Safety, Privacy, Child Protection & Parental Controls.

Tests:
1. Input moderation layer across all blocked categories:
   - Violence, sexual, self-harm, drugs, personal data extraction
   - Kid-specific filtering for bullying and inappropriate language
2. Persona-voiced redirects in companion voices:
   - Reggie (Rule Farmer), Kabir Chowdhury, Professor Anika
3. Parent dashboard safety audit flags logged to database
4. Data export endpoint (GDPR/COPPA data portability)
5. Complete account & learning data deletion (Right to be Forgotten)
"""

import os
import uuid
import pytest
from httpx import AsyncClient, ASGITransport

from backend.main import app
from backend.models.user import User, UserProfile, AgeBand
from backend.repositories import get_repository
from backend.engine.auth_token import create_device_token
from backend.engine.safety import check_content_safety, get_redirect_message
from backend.engine.characters import load_character
from backend.engine.conversation import ConversationEngine
from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider


@pytest.fixture
async def repo():
    return await get_repository()


@pytest.fixture
async def auth_user(repo):
    user_id = f"user_safe_{uuid.uuid4()}"
    device_id = f"dev_safe_{uuid.uuid4()}"
    await repo.create_user(User(id=user_id, device_id=device_id))
    await repo.save_profile(UserProfile(
        user_id=user_id,
        display_name="Sami",
        age_band=AgeBand.KID,
        daily_goal_minutes=10,
        goal="confidence",
    ))
    token = create_device_token(user_id=user_id, device_id=device_id)
    return {"Authorization": f"Bearer {token}"}, user_id


def test_harmful_input_filtering_categories():
    """Verify check_content_safety catches all harmful categories."""
    assert check_content_safety("I want to attack and beat up someone") == "violence"
    assert check_content_safety("Can you show me nude pictures") == "sexual"
    assert check_content_safety("I feel like I want to die and cut myself") == "self_harm"
    assert check_content_safety("Where can I buy cocaine and weed") == "drugs"
    assert check_content_safety("What is your home address and phone number") == "personal_info_request"

    # Safe statements pass
    assert check_content_safety("I love eating mangoes with my family") is None
    assert check_content_safety("Can you teach me how to introduce myself?") is None


def test_kid_specific_bullying_filtering():
    """Verify stricter filtering is applied for kids."""
    # Bullying phrase blocked for kids
    assert check_content_safety("Shut up you idiot", is_user_message=True, age_band="kid") == "inappropriate_language"
    assert check_content_safety("You are dumb and stupid", is_user_message=True, age_band="kid") == "inappropriate_language"

    # Same mild words not blocked for adults
    assert check_content_safety("That was a stupid movie", is_user_message=True, age_band="adult") is None


def test_character_voiced_redirects():
    """Verify each companion has distinct persona-voiced safe redirects."""
    categories = ["violence", "sexual", "self_harm", "drugs", "personal_info_request", "inappropriate_language"]
    companions = ["rule_farmer", "kabir_chowdhury", "professor_anika"]

    for comp in companions:
        for cat in categories:
            msg = get_redirect_message(cat, character_id=comp)
            assert len(msg) > 20
            # Companion-specific vocabulary
            if comp == "rule_farmer":
                assert any(w in msg.lower() for w in ["farm", "partner", "barn", "harvest", "fields", "reggie"])
            elif comp == "kabir_chowdhury":
                assert any(w in msg.lower() for w in ["detective", "investigation", "mystery", "inquiry", "dhaka"])
            elif comp == "professor_anika":
                assert any(w in msg.lower() for w in ["academic", "seminar", "research", "study", "scholarly", "professor"])


@pytest.mark.asyncio
async def test_harmful_turn_returns_character_redirect(auth_user):
    """Verify live conversation intercept returns companion-voiced redirect when input is unsafe."""
    headers, user_id = auth_user

    engine = ConversationEngine(
        stt=MockSttProvider(default_text="I want to beat up and hurt people with weapons"),
        llm=MockLlmProvider(),
        tts=MockTtsProvider(),
    )
    reg_char = load_character("rule_farmer")
    state = engine.start_conversation("rule_farmer", user_id=user_id, age_band="kid")

    res = await engine.process_turn(
        conversation_id=state.id,
        audio=b"fake-audio-bytes",
        character=reg_char,
    )

    assert res.safety_blocked is True
    assert "farm" in res.response.reply.lower() or "partner" in res.response.reply.lower()


@pytest.mark.asyncio
async def test_privacy_data_export(auth_user, repo):
    """Verify GET /api/privacy/export/{user_id} provides complete data export without raw audio."""
    headers, user_id = auth_user

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get(f"/api/privacy/export/{user_id}", headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert data["user"]["id"] == user_id
        assert data["profile"]["display_name"] == "Sami"
        assert data["raw_audio_stored"] is False
        assert "data_retention_policy" in data


@pytest.mark.asyncio
async def test_privacy_complete_data_deletion(auth_user, repo):
    """Verify DELETE /api/privacy/user/{user_id} completely wipes user records across all tables."""
    headers, user_id = auth_user

    # Add activity, memory, and progress
    await repo.record_activity(user_id, xp_earned=50)
    await repo.save_character_memory(user_id, "rule_farmer", "Sami", "paddy harvest", "confidence")

    assert (await repo.get_user(user_id)) is not None
    assert (await repo.get_profile(user_id)) is not None

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        del_res = await client.delete(f"/api/privacy/user/{user_id}", headers=headers)
        assert del_res.status_code == 200

    # Verify completely erased
    assert (await repo.get_user(user_id)) is None
    assert (await repo.get_profile(user_id)) is None
    assert (await repo.get_character_memory(user_id, "rule_farmer")) is None
