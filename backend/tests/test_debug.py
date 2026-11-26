"""
Tests for Debug observability routes (/api/debug/last_turns).
"""

import os
from fastapi.testclient import TestClient
from backend.main import app
from backend.engine.conversation import record_turn_log, get_last_turns


def test_debug_endpoint_disabled_by_default(monkeypatch):
    client = TestClient(app)
    # Explicitly disable DEBUG
    monkeypatch.setenv("DEBUG", "false")
    res = client.get("/api/debug/last_turns")
    assert res.status_code == 403


def test_debug_endpoint_enabled(monkeypatch):
    monkeypatch.setenv("DEBUG", "true")
    client = TestClient(app)

    record_turn_log({
        "turn_id": "test-debug-123",
        "conversation_id": "conv-1",
        "status": "ok",
    })

    res = client.get("/api/debug/last_turns")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert data["count"] >= 1
    assert any(t.get("turn_id") == "test-debug-123" for t in data["turns"])


def test_debug_last_requests_endpoint(monkeypatch):
    client = TestClient(app)
    monkeypatch.setenv("DEBUG", "false")
    assert client.get("/api/debug/last_requests").status_code == 403

    monkeypatch.setenv("DEBUG", "true")
    client.get("/health")
    res = client.get("/api/debug/last_requests")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert data["count"] >= 1
    assert any(r.get("path") == "/health" for r in data["requests"])


def test_diagnostics_probe_endpoints():
    client = TestClient(app)
    for stage in ("stt", "llm", "tts"):
        res = client.post(f"/api/debug/diagnostics/{stage}")
        assert res.status_code == 200
        data = res.json()
        assert data["ok"] is True
        assert "ms" in data
