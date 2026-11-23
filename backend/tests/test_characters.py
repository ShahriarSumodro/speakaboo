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
