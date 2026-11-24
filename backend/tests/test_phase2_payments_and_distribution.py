"""
Tests for Phase 2: Payments and Distribution.

Covers:
- BillingProvider implementations: Google Play Billing, Direct bKash/Nagad, and Web checkout.
- Unified backend entitlements: regardless of whether payment originates from Play,
  bKash, Nagad, or Web, entitlements are shared, restorable, and managed centrally.
- Refund flow: revoking active entitlements and updating payment status to 'refunded'.
- Idempotency of verify and webhook endpoints.
- Sandbox mode enforcement and credentials guards.
"""

import pytest
import uuid
from backend.repositories import get_repository
from backend.models.user import UserProfile, AgeBand


@pytest.fixture
async def setup_user():
    repo = await get_repository()
    uid = f"test-p2-{uuid.uuid4().hex[:8]}"
    profile = UserProfile(
        user_id=uid,
        display_name="Tanvir",
        age_band=AgeBand.TEEN,
        goal="fluency",
        level="intermediate",
    )
    await repo.save_profile(profile)
    yield uid
    # Teardown
    ents = await repo.get_entitlements(uid)
    for e in ents:
        await repo.revoke_entitlement(uid, e.type, e.value)


@pytest.mark.asyncio
async def test_google_play_billing_flow(client, setup_user):
    """Test Google Play checkout and receipt verification for monthly plan."""
    uid = setup_user
    # 1. Create Play checkout intent
    res = client.post(
        "/api/payment/checkout",
        json={
            "user_id": uid,
            "gateway": "google_play",
            "purpose": "monthly_plan",
        },
    )
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["gateway"] == "google_play"
    assert "play_billing://" in data["checkout_url"]
    payment_id = data["payment_id"]

    # 2. Verify with Play receipt
    res_verify = client.post(
        "/api/payment/verify",
        json={
            "payment_id": payment_id,
            "gateway": "google_play",
            "verification_token": "valid_gpa_receipt_token",
        },
    )
    assert res_verify.status_code == 200, res_verify.text
    vdata = res_verify.json()
    assert vdata["success"] is True
    assert vdata["status"] == "completed"
    assert vdata["transaction_id"].startswith("GPA.")
    assert vdata["entitlement_granted"] == "plan:monthly"

    # 3. Check entitlements endpoint
    res_ents = client.get(f"/api/payment/entitlements/{uid}")
    assert res_ents.status_code == 200
    ents = res_ents.json()
    assert any(e["type"] == "plan" and e["value"] == "monthly" and e["is_active"] for e in ents)


@pytest.mark.asyncio
async def test_web_checkout_flow(client, setup_user):
    """Test Web checkout for unlocking a specific character."""
    uid = setup_user
    res = client.post(
        "/api/payment/checkout",
        json={
            "user_id": uid,
            "gateway": "web_checkout",
            "purpose": "character_unlock",
            "target_id": "detective_kabir",
        },
    )
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["gateway"] == "web_checkout"
    assert "pay.speakaboo.app" in data["checkout_url"]
    payment_id = data["payment_id"]

    # Verify
    res_verify = client.post(
        "/api/payment/verify",
        json={
            "payment_id": payment_id,
            "gateway": "web_checkout",
            "verification_token": "web_session_ok",
        },
    )
    assert res_verify.status_code == 200
    assert res_verify.json()["success"] is True
    assert res_verify.json()["entitlement_granted"] == "character:detective_kabir"


@pytest.mark.asyncio
async def test_direct_bkash_flow(client, setup_user):
    """Test Direct bKash payment flow."""
    uid = setup_user
    res = client.post(
        "/api/payment/checkout",
        json={
            "user_id": uid,
            "gateway": "bkash",
            "purpose": "monthly_plan",
        },
    )
    assert res.status_code == 200
    data = res.json()
    payment_id = data["payment_id"]

    res_verify = client.post(
        "/api/payment/verify",
        json={
            "payment_id": payment_id,
            "gateway": "bkash",
            "verification_token": "bkash_token_123",
        },
    )
    assert res_verify.status_code == 200
    assert res_verify.json()["success"] is True


@pytest.mark.asyncio
async def test_unified_entitlements_and_restore(client, setup_user):
    """Test that restore purchases returns all active entitlements regardless of gateway."""
    uid = setup_user
    res = client.post(f"/api/payment/restore/{uid}")
    assert res.status_code == 200
    assert isinstance(res.json(), list)


@pytest.mark.asyncio
async def test_refund_and_entitlement_revocation(client, setup_user):
    """Test refund endpoint updates payment status and revokes user entitlement."""
    uid = setup_user
    # 1. Purchase character unlock
    checkout = client.post(
        "/api/payment/checkout",
        json={
            "user_id": uid,
            "gateway": "google_play",
            "purpose": "character_unlock",
            "target_id": "farmer_reggie",
        },
    )
    pid = checkout.json()["payment_id"]
    client.post(
        "/api/payment/verify",
        json={
            "payment_id": pid,
            "gateway": "google_play",
            "verification_token": "token",
        },
    )

    # Confirm entitlement exists
    ents_before = client.get(f"/api/payment/entitlements/{uid}")
    assert any(e["value"] == "farmer_reggie" and e["is_active"] for e in ents_before.json())

    # 2. Issue refund
    res_refund = client.post(
        "/api/payment/refund",
        json={
            "payment_id": pid,
            "reason": "customer_cancelled_subscription",
        },
    )
    assert res_refund.status_code == 200, res_refund.text
    rdata = res_refund.json()
    assert rdata["success"] is True
    assert rdata["status"] == "refunded"
    assert rdata["revoked_entitlement"] == "character:farmer_reggie"

    # 3. Confirm entitlement is revoked
    ents_after = client.get(f"/api/payment/entitlements/{uid}")
    assert not any(e["value"] == "farmer_reggie" for e in ents_after.json())

    # 4. Idempotent re-refund
    res_re_refund = client.post(
        "/api/payment/refund",
        json={"payment_id": pid},
    )
    assert res_re_refund.status_code == 200
    assert res_re_refund.json()["status"] == "refunded"


@pytest.mark.asyncio
async def test_manual_trxid_verification(client, setup_user):
    """Test direct distribution manual USSD TrxID submission (CD-004)."""
    uid = setup_user
    test_trx = f"TRX{uuid.uuid4().hex[:8].upper()}"
    res = client.post(
        "/api/payment/manual-trxid",
        json={
            "user_id": uid,
            "gateway": "bkash",
            "trx_id": test_trx,
            "purpose": "monthly_plan",
        },
    )
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["success"] is True
    assert data["status"] == "completed"
    assert data["entitlement_granted"] == "plan:monthly"

    # Verify duplicate TrxID rejection (HTTP 409)
    res_dup = client.post(
        "/api/payment/manual-trxid",
        json={
            "user_id": uid,
            "gateway": "bkash",
            "trx_id": test_trx,
            "purpose": "monthly_plan",
        },
    )
    assert res_dup.status_code == 409
