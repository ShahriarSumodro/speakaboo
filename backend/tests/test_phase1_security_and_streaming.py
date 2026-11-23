"""
Phase 1 Test Suite: Backend Truth, Security, Profiles, Token Isolation, and Streaming Turns.
"""

import os
os.environ["TEST_MODE"] = "true"

import pytest
import io
import wave
import struct
import math
from fastapi.testclient import TestClient

from backend.main import app
from backend.engine.auth_token import create_device_token, verify_device_token, hash_pin, verify_pin


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def generate_wav_bytes(duration_s: float = 0.5) -> bytes:
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(16000)
        for i in range(int(16000 * duration_s)):
            t = i / 16000
            val = int(4000 * math.sin(2 * math.pi * 440 * t))
            wav.writeframesraw(struct.pack("<h", val))
    return buffer.getvalue()


class TestPhase1SecurityAndProfiles:

    def test_token_creation_and_tampering(self):
        token = create_device_token("user-1", "device-1")
        payload = verify_device_token(token)
        assert payload["sub"] == "user-1"
        assert payload["device_id"] == "device-1"

        # Tampered token
        tampered = token[:-5] + "XXXXX"
        with pytest.raises(ValueError, match="Invalid token signature"):
            verify_device_token(tampered)

    def test_pin_hashing_and_verification(self):
        h = hash_pin("4321")
        assert verify_pin("4321", h) is True
        assert verify_pin("0000", h) is False

    def test_persistent_device_auth_flow(self, client):
        import uuid
        dev_id = f"test-device-{uuid.uuid4()}"
        # 1. Register new device
        res1 = client.post("/api/auth/device", json={"device_id": dev_id})
        assert res1.status_code == 200
        data1 = res1.json()
        assert data1["is_new"] is True
        assert data1["user_id"]
        assert data1["token"]
        assert data1["profile"]["display_name"] == "Learner"

        # 2. Login with same device returns existing user
        res2 = client.post("/api/auth/device", json={"device_id": dev_id})
        assert res2.status_code == 200
        data2 = res2.json()
        assert data2["is_new"] is False
        assert data2["user_id"] == data1["user_id"]

    def test_profile_lifecycle_and_parent_pin(self, client):
        import uuid
        auth_res = client.post("/api/auth/device", json={"device_id": f"prof-{uuid.uuid4()}"})
        token = auth_res.json()["token"]
        user_id = auth_res.json()["user_id"]
        headers = {"Authorization": f"Bearer {token}"}

        # Get profile
        prof_res = client.get("/api/auth/profile", headers=headers)
        assert prof_res.status_code == 200
        assert prof_res.json()["user_id"] == user_id

        # Update profile
        update_res = client.put(
            "/api/auth/profile",
            headers=headers,
            json={
                "display_name": "Ayesha",
                "age_band": "teen",
                "goal": "ielts",
                "daily_goal_minutes": 20,
                "theme": "dark",
            },
        )
        assert update_res.status_code == 200
        u_data = update_res.json()
        assert u_data["display_name"] == "Ayesha"
        assert u_data["age_band"] == "teen"
        assert u_data["goal"] == "ielts"
        assert u_data["daily_goal_minutes"] == 20
        assert u_data["theme"] == "dark"

        # Set parent PIN
        pin_res = client.post("/api/auth/set-parent-pin", headers=headers, json={"pin": "8899"})
        assert pin_res.status_code == 200

        # Verify parent PIN - correct
        verify_res = client.post("/api/auth/verify-parent-pin", headers=headers, json={"pin": "8899"})
        assert verify_res.status_code == 200
        assert verify_res.json()["verified"] is True

        # Verify parent PIN - incorrect
        wrong_res = client.post("/api/auth/verify-parent-pin", headers=headers, json={"pin": "0000"})
        assert wrong_res.status_code == 403

    def test_user_data_isolation_forbidden(self, client):
        # User A
        res_a = client.post("/api/auth/device", json={"device_id": "device-user-a"})
        token_a = res_a.json()["token"]
        user_a = res_a.json()["user_id"]

        # User B
        res_b = client.post("/api/auth/device", json={"device_id": "device-user-b"})
        user_b = res_b.json()["user_id"]

        # User A tries to view User B's usage with User A's token
        headers_a = {"Authorization": f"Bearer {token_a}"}
        snoop_res = client.get(f"/api/usage/{user_b}/daily", headers=headers_a)
        assert snoop_res.status_code == 403
        assert "Forbidden" in snoop_res.json()["detail"]

    def test_characters_api_rich_truth(self, client):
        res = client.get("/api/characters/")
        assert res.status_code == 200
        chars = res.json()
        assert len(chars) >= 3
        farmer = next(c for c in chars if c["id"] == "rule_farmer")
        assert farmer["voice_id"] == "austin"
        assert farmer["tagline"]
        assert len(farmer["personality_traits"]) > 0
        assert len(farmer["sample_lines"]) > 0
        assert farmer["preview_audio_url"] == "/api/characters/rule_farmer/preview-audio"

        # Preview audio endpoint
        audio_res = client.get("/api/characters/rule_farmer/preview-audio")
        assert audio_res.status_code == 200
        assert audio_res.headers["content-type"] == "audio/wav"
        assert len(audio_res.content) > 100

    def test_stream_turn_sse_endpoint(self, client):
        # Start conversation
        start_res = client.post(
            "/api/conversation/start",
            json={"user_id": "stream-tester", "character_id": "rule_farmer"},
        )
        assert start_res.status_code == 200
        conv_id = start_res.json()["conversation_id"]

        # Stream turn
        wav_data = generate_wav_bytes(0.5)
        stream_res = client.post(
            "/api/conversation/stream-turn",
            data={"conversation_id": conv_id, "audio_format": "wav"},
            files={"audio": ("audio.wav", wav_data, "audio/wav")},
        )
        assert stream_res.status_code == 200
        assert "text/event-stream" in stream_res.headers["content-type"]
        body = stream_res.text
        assert "event: transcript" in body
        assert "event: audio_chunk" in body
        assert "event: turn_complete" in body
