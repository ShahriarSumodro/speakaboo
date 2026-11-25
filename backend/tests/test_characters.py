"""
Tests for the character system.
"""

import pytest
from backend.engine.characters import load_character, list_characters, build_system_prompt


class TestCharacterLoading:

    def test_load_rule_farmer(self):
        char = load_character("rule_farmer")
        assert char.id == "rule_farmer"
        assert char.name == "Farmer Reggie"
        assert char.persona_prompt
        assert char.voice_id
        assert not char.locked
        assert char.price_bdt == 0
        assert char.vocabulary_focus
        assert "Everyday" in char.vocabulary_focus

    def test_characters_have_vocabulary_focus(self):
        chars = list_characters()
        for c in chars:
            assert c.vocabulary_focus, f"Character {c.id} missing vocabulary_focus"

    def test_load_nonexistent_raises(self):
        with pytest.raises(FileNotFoundError):
            load_character("nonexistent_character")

    def test_list_characters(self):
        chars = list_characters()
        assert len(chars) >= 1
        ids = [c.id for c in chars]
        assert "rule_farmer" in ids

    def test_difficulty_tones(self):
        char = load_character("rule_farmer")
        assert "beginner" in char.difficulty_tones
        assert "intermediate" in char.difficulty_tones
        assert "advanced" in char.difficulty_tones


class TestSystemPrompt:

    def test_build_system_prompt_beginner(self):
        char = load_character("rule_farmer")
        prompt = build_system_prompt(char, "beginner")
        assert "Farmer Reggie" in prompt
        assert "JSON" in prompt
        assert "200 characters" in prompt or "200 chars" in prompt

    def test_build_system_prompt_advanced(self):
        char = load_character("rule_farmer")
        prompt = build_system_prompt(char, "advanced")
        assert "advanced" in prompt.lower() or "richer" in prompt.lower() or "harder" in prompt.lower()

    def test_prompt_includes_safety_rules(self):
        char = load_character("rule_farmer")
        prompt = build_system_prompt(char)
        assert "violence" in prompt.lower()
        assert "personal information" in prompt.lower() or "personal info" in prompt.lower()

    def test_feedback_style_override(self):
        char = load_character("rule_farmer")
        prompt = build_system_prompt(char, feedback_style_override="Be very detailed and analytical")
        assert "very detailed" in prompt


class TestCharacterPreviewAudio:

    def test_get_preview_audio_success(self):
        from fastapi.testclient import TestClient
        from backend.main import app
        client = TestClient(app)

        res = client.get("/api/characters/rule_farmer/preview-audio")
        assert res.status_code == 200
        assert "audio/wav" in res.headers["content-type"]
        assert len(res.content) > 0

    def test_get_preview_audio_nonexistent(self):
        from fastapi.testclient import TestClient
        from backend.main import app
        client = TestClient(app)

        res = client.get("/api/characters/nonexistent_char/preview-audio")
        assert res.status_code == 404

    def test_get_preview_audio_cached(self):
        from fastapi.testclient import TestClient
        from backend.main import app
        client = TestClient(app)

        res1 = client.get("/api/characters/dhaka_detective/preview-audio")
        assert res1.status_code == 200
        res2 = client.get("/api/characters/dhaka_detective/preview-audio")
        assert res2.status_code == 200
        assert res1.content == res2.content
