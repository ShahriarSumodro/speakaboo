"""
Tests for Phase 5 Monetization: payment gateways, verification, webhooks, entitlements, and daily cap UX.
"""

import pytest
import tempfile
import os
import time
from fastapi.testclient import TestClient

from backend.main import app
from backend.repositories.sqlite_repo import SqliteRepository, dhaka_today
from backend.repositories import set_repository
from backend.models.user import User, Plan, Entitlement
from backend.providers.payment import get_payment_gateway, PaymentPurpose, PaymentStatus


@pytest.fixture
async def repo():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    r = SqliteRepository(path)
    await r.initialize()
    set_repository(r)
    yield r
    await r.close()
    os.unlink(path)


def test_plans_pricing_endpoint(repo, client):
    """Pricing endpoint returns configured BDT values."""
    res = client.get("/api/payment/plans")
    assert res.status_code == 200
    data = res.json()
    assert data["monthly_plan"]["price_bdt"] == 200
    assert data["monthly_plan"]["daily_minutes"] == 30
    assert data["character_unlock_price_bdt"] == 350


def test_bkash_and_nagad_checkout(repo, client):
    """Checkout sessions can be initiated for bKash and Nagad."""
    # 1. bKash Monthly Plan
    res1 = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-pay-1", "gateway": "bkash", "purpose": "monthly_plan"},
    )
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["gateway"] == "bkash"
    assert data1["amount_bdt"] == 200
    assert "payment_id" in data1

    # 2. Nagad Character Unlock
    res2 = client.post(
        "/api/payment/checkout",
        json={
            "user_id": "u-pay-1",
            "gateway": "nagad",
            "purpose": "character_unlock",
            "target_id": "dhaka_detective",
        },
    )
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["gateway"] == "nagad"
    assert data2["amount_bdt"] == 350


def test_verify_payment_grants_entitlement(repo, client):
    """Successful verification grants entitlement to the user."""
    # 1. Initiate checkout
    c_res = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-pay-2", "gateway": "bkash", "purpose": "monthly_plan"},
    )
    pid = c_res.json()["payment_id"]

    # 2. Verify payment
    v_res = client.post(
        "/api/payment/verify",
        json={"payment_id": pid, "gateway": "bkash"},
    )
    assert v_res.status_code == 200
    v_data = v_res.json()
    assert v_data["success"] is True
    assert v_data["status"] == "completed"
    assert "plan:monthly" in v_data["entitlement_granted"]

    # 3. Check entitlements list
    e_res = client.get("/api/payment/entitlements/u-pay-2")
    assert e_res.status_code == 200
    ents = e_res.json()
    assert len(ents) == 1
    assert ents[0]["type"] == "plan"
    assert ents[0]["value"] == "monthly"
    assert ents[0]["is_active"] is True


def test_failed_payment_verification(repo, client):
    """Failed transaction does not grant entitlement."""
    c_res = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-pay-3", "gateway": "nagad", "purpose": "monthly_plan"},
    )
    pid = c_res.json()["payment_id"]

    v_res = client.post(
        "/api/payment/verify",
        json={"payment_id": pid, "gateway": "nagad", "verification_token": "FAIL_TXN"},
    )
    assert v_res.status_code == 200
    v_data = v_res.json()
    assert v_data["success"] is False
    assert v_data["status"] == "failed"

    e_res = client.get("/api/payment/entitlements/u-pay-3")
    assert len(e_res.json()) == 0


@pytest.mark.asyncio
async def test_daily_cap_enforcement(repo, client):
    """Users exceeding daily cap get HTTP 403 with upgrade guidance."""
    user = User(id="u-capped", device_id="d-capped")
    await repo.create_user(user)

    # Exhaust free limit (10 minutes)
    await repo.increment_usage("u-capped", minutes=10.5, date=dhaka_today())

    # Start conversation
    s_res = client.post(
        "/api/conversation/start",
        json={"user_id": "u-capped", "character_id": "rule_farmer"},
    )
    conv_id = s_res.json()["conversation_id"]

    # Attempt turn
    turn_res = client.post(
        "/api/conversation/turn",
        data={"conversation_id": conv_id, "audio_format": "wav"},
        files={"audio": ("test.wav", b"\x00" * 1000, "audio/wav")},
    )
    assert turn_res.status_code == 403
    assert "Daily limit" in turn_res.json()["detail"]


@pytest.mark.asyncio
async def test_locked_character_requires_unlock(repo, client):
    """Practicing with a locked character requires entitlement."""
    user = User(id="u-locked-test", device_id="d-locked")
    await repo.create_user(user)

    # Create dummy locked character JSON in engine
    from backend.engine.characters import Character
    from backend.routes.conversation import get_engine
    engine = get_engine()
    state = engine.start_conversation(
        character_id="locked_companion", user_id="u-locked-test"
    )

    # Mock load_character to return locked character
    import backend.routes.conversation as conv_mod
    orig_load = conv_mod.load_character
    conv_mod.load_character = lambda cid: Character(
        id="locked_companion",
        name="Locked Companion",
        description="Premium",
        persona_prompt="Strict",
        speaking_style="Direct",
        voice_id="Voice",
        difficulty_tones={},
        greeting="Hi",
        locked=True,
        price_bdt=350,
    )

    try:
        res = client.post(
            "/api/conversation/turn",
            data={"conversation_id": state.id, "audio_format": "wav"},
            files={"audio": ("test.wav", b"\x00" * 1000, "audio/wav")},
        )
        assert res.status_code == 403
        assert "unlock" in res.json()["detail"].lower()
    finally:
        conv_mod.load_character = orig_load
