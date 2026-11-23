"""
Tests for Phase 7 Hardening and Launch Prep:
Privacy policy, parental consent, data deletion endpoint, telemetry/crash reporting,
cost estimator, and load test runner.
"""

import pytest
import tempfile
import os
from fastapi.testclient import TestClient

from backend.main import app
from backend.repositories.sqlite_repo import SqliteRepository
from backend.repositories import set_repository
from backend.models.user import User, Plan
from backend.engine.telemetry import TelemetryService, telemetry
from backend.scripts.cost_report import calculate_cost_per_minute
from backend.scripts.load_test import run_load_test


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


def test_privacy_policy_and_parental_consent_endpoints(client):
    # Policy
    res1 = client.get("/api/privacy/policy")
    assert res1.status_code == 200
    data1 = res1.json()
    assert "Privacy Policy" in data1["title"]
    assert "No Voice Audio Storage" in data1["content_markdown"]

    # Parental consent
    res2 = client.get("/api/privacy/parental-consent")
    assert res2.status_code == 200
    data2 = res2.json()
    assert "Parental Consent" in data2["title"]
    assert "Parent Dashboard" in data2["content_markdown"]


@pytest.mark.asyncio
async def test_data_deletion_endpoint(repo, client):
    # Create user
    user = User(id="user-to-delete", device_id="dev-delete-1", display_name="Test Deletion")
    await repo.create_user(user)

    # Verify user exists
    assert await repo.get_user("user-to-delete") is not None

    # Call DELETE endpoint
    res = client.delete("/api/privacy/user/user-to-delete")
    assert res.status_code == 200
    assert res.json()["status"] == "purged"

    # Verify user purged completely
    assert await repo.get_user("user-to-delete") is None

    # Deleting nonexistent user returns 404
    res_404 = client.delete("/api/privacy/user/nonexistent-user-123")
    assert res_404.status_code == 404


def test_telemetry_and_crash_reporting():
    t = TelemetryService(max_buffer_size=5)
    t.track("turn_completed", user_id="u1", properties={"latency_ms": 120})
    t.track("streak_milestone", user_id="u1", properties={"streak": 7})
    t.track("checkout_started", user_id="u2", properties={"gateway": "bkash"})

    events_u1 = t.get_events(user_id="u1")
    assert len(events_u1) == 2
    assert events_u1[0].event_name == "turn_completed"

    crash = t.record_crash(
        error_type="ValueError",
        message="Invalid test data",
        stack_trace="Traceback (most recent call last): ...",
        endpoint="POST /api/test",
    )
    assert crash.error_type == "ValueError"
    assert len(t.get_crashes()) == 1


def test_cost_estimator_economics():
    econ = calculate_cost_per_minute()
    assert econ["cost_per_turn"]["total_usd"] > 0
    assert econ["cost_per_user_minute"]["usd"] > 0
    assert econ["cost_per_user_minute"]["bdt"] > 0
    # Unit economics check: pro subscription margin should be positive
    assert econ["pro_subscription_monthly"]["margin_percentage"] > 40.0


@pytest.mark.asyncio
async def test_load_test_execution():
    # Run a fast mini load test with 6 turns and concurrency 2
    report = await run_load_test(total_turns=6, concurrency=2)
    assert report["total_turns"] == 6
    assert report["successful_turns"] == 6
    assert report["failed_turns"] == 0
    assert report["throughput_turns_per_sec"] > 0.0
