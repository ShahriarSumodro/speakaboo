"""
Tests for Phase 9: Payment Integration (bKash & Nagad), Ledger Idempotency,
Sandbox Mode Enforcement, Entitlement Expiry, and Revenue Analytics.
"""

import pytest
import tempfile
import os
import time
from fastapi.testclient import TestClient

from backend.main import app
from backend.repositories.sqlite_repo import SqliteRepository
from backend.repositories import set_repository
from backend.models.user import User, Entitlement
from backend.config import load_settings
from backend.scripts.revenue_report import generate_revenue_report


@pytest.fixture
async def repo():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    r = SqliteRepository(path)
    await r.initialize()
    set_repository(r)
    yield r
    await r.close()
    if os.path.exists(path):
        os.unlink(path)


@pytest.fixture
def client(repo):
    with TestClient(app) as c:
        yield c


def test_payment_ledger_persistence(repo, client):
    """Checkout correctly writes pending record to SQLite payments ledger."""
    res = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-ledger-1", "gateway": "bkash", "purpose": "monthly_plan"},
    )
    assert res.status_code == 200
    data = res.json()
    pid = data["payment_id"]

    # Verify directly via repository
    import asyncio
    saved = asyncio.run(repo.get_payment(pid))
    assert saved is not None
    assert saved["id"] == pid
    assert saved["user_id"] == "u-ledger-1"
    assert saved["gateway"] == "bkash"
    assert saved["amount_bdt"] == 200
    assert saved["purpose"] == "monthly_plan"
    assert saved["status"] == "pending"


def test_payment_idempotent_verification(repo, client):
    """Verifying payment multiple times does not create duplicate entitlements."""
    c_res = client.post(
        "/api/payment/checkout",
        json={
            "user_id": "u-idem-1",
            "gateway": "nagad",
            "purpose": "character_unlock",
            "target_id": "professor_anika",
        },
    )
    pid = c_res.json()["payment_id"]

    # First verification
    v1 = client.post(
        "/api/payment/verify",
        json={"payment_id": pid, "gateway": "nagad"},
    )
    assert v1.status_code == 200
    assert v1.json()["success"] is True
    assert v1.json()["status"] == "completed"
    first_txn = v1.json()["transaction_id"]

    # Second verification (idempotent)
    v2 = client.post(
        "/api/payment/verify",
        json={"payment_id": pid, "gateway": "nagad"},
    )
    assert v2.status_code == 200
    assert v2.json()["success"] is True
    assert v2.json()["status"] == "completed"
    assert v2.json()["transaction_id"] == first_txn
    assert "already verified" in v2.json()["message"].lower()

    # Check entitlements: exactly 1 entitlement must exist
    ents_res = client.get("/api/payment/entitlements/u-idem-1")
    ents = ents_res.json()
    assert len(ents) == 1
    assert ents[0]["type"] == "character"
    assert ents[0]["value"] == "professor_anika"
    assert ents[0]["expires_at"] is None  # Permanent unlock


def test_webhook_idempotency(repo, client):
    """Webhook notifications are idempotent and do not duplicate transactions."""
    c_res = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-hook-1", "gateway": "bkash", "purpose": "monthly_plan"},
    )
    pid = c_res.json()["payment_id"]

    # Verify first
    client.post("/api/payment/verify", json={"payment_id": pid, "gateway": "bkash"})

    # Send webhook for already completed payment
    w_res = client.post(
        "/api/payment/webhook?gateway_name=bkash",
        json={"payment_id": pid, "status": "completed"},
    )
    assert w_res.status_code == 200
    assert w_res.json()["status"] == "already_processed"


def test_sandbox_mode_enforcement(repo, client, monkeypatch):
    """When sandbox mode is false and merchant keys are absent, checkout raises 503."""
    # Monkeypatch settings
    import backend.routes.payment as pay_mod
    orig_load = pay_mod.load_settings

    class FakePaymentConfig:
        sandbox_mode = False
        bkash_app_key = ""
        nagad_merchant_id = ""
        monthly_plan_price_bdt = 200
        character_unlock_price_bdt = 350

    class FakeSettings:
        payment = FakePaymentConfig()

    pay_mod.load_settings = lambda: FakeSettings()

    try:
        res = client.post(
            "/api/payment/checkout",
            json={"user_id": "u-sandbox", "gateway": "bkash", "purpose": "monthly_plan"},
        )
        assert res.status_code == 503
        assert "Live bKash merchant gateway not configured" in res.json()["detail"]
    finally:
        pay_mod.load_settings = orig_load


def test_revenue_report_generation(repo, client):
    """Revenue report script calculates real BDT/USD revenues and AI unit costs."""
    # Complete one monthly subscription (200 BDT) and one character unlock (350 BDT)
    c1 = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-rev-1", "gateway": "bkash", "purpose": "monthly_plan"},
    )
    client.post("/api/payment/verify", json={"payment_id": c1.json()["payment_id"], "gateway": "bkash"})

    c2 = client.post(
        "/api/payment/checkout",
        json={"user_id": "u-rev-2", "gateway": "nagad", "purpose": "character_unlock", "target_id": "dhaka_detective"},
    )
    client.post("/api/payment/verify", json={"payment_id": c2.json()["payment_id"], "gateway": "nagad"})

    # Generate report against current repo db
    report = generate_revenue_report(repo.db_path)
    assert report["gross_revenue_bdt"] == 550  # 200 + 350
    assert report["gross_revenue_usd"] > 0
    assert report["total_completed_transactions"] == 2
    assert report["revenue_by_stream"]["monthly_pro_subscription_bdt"] == 200
    assert report["revenue_by_stream"]["character_unlocks_bdt"] == 350
    assert report["revenue_by_gateway"]["bkash_bdt"] == 200
    assert report["revenue_by_gateway"]["nagad_bdt"] == 350
