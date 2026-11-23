"""
Tests for Phase 4: Character Experience, Preview-Before-Buy, and 2-Minute Free Trial.
"""

import uuid
import pytest
from fastapi.testclient import TestClient

from backend.main import app
from backend.repositories import get_repository
from backend.models.user import Entitlement

client = TestClient(app)


@pytest.mark.asyncio
async def test_locked_character_allows_2_minute_trial_and_caps():
    repo = await get_repository()
    user_id = f"trial-user-{uuid.uuid4()}"
    character_id = "dhaka_detective"  # Locked character (350 BDT)

    # 1. Before trial, user should be able to start conversation
    res = client.post("/api/conversation/start", json={"user_id": user_id, "character_id": character_id})
    assert res.status_code == 200, res.text
    conv_id = res.json()["conversation_id"]

    # 2. Check usage is currently 0
    used = await repo.get_character_usage_seconds(user_id, character_id)
    assert used == 0.0

    # 3. Increment trial to 60 seconds (still within 2 minutes)
    await repo.increment_character_usage_seconds(user_id, character_id, 60.0)
    res = client.post("/api/conversation/start", json={"user_id": user_id, "character_id": character_id})
    assert res.status_code == 200

    # 4. Increment trial to 120 seconds (exhausting the free trial)
    await repo.increment_character_usage_seconds(user_id, character_id, 60.0)
    res = client.post("/api/conversation/start", json={"user_id": user_id, "character_id": character_id})
    assert res.status_code == 403
    assert "2-minute free trial" in res.json()["detail"]
    assert "350 BDT" in res.json()["detail"]

    # 5. After unlocking the character with an entitlement, access is restored
    await repo.add_entitlement(Entitlement(
        id=f"ent-{uuid.uuid4()}",
        user_id=user_id,
        type="character",
        value=character_id,
    ))
    res = client.post("/api/conversation/start", json={"user_id": user_id, "character_id": character_id})
    assert res.status_code == 200


@pytest.mark.asyncio
async def test_character_voice_preview_endpoint():
    res = client.get("/api/characters/rule_farmer/preview-audio")
    assert res.status_code == 200
    assert len(res.content) > 0


@pytest.mark.asyncio
async def test_character_detail_metadata():
    res = client.get("/api/characters/dhaka_detective")
    assert res.status_code == 200
    data = res.json()
    assert data["name"] == "Detective Kabir"
    assert data["locked"] is True
    assert data["price_bdt"] == 350
    assert "Sharp-witted" in data["personality_traits"]
    assert len(data["sample_lines"]) > 0
