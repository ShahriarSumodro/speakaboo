"""
Tests for the safety layer.
"""

import pytest

from backend.engine.safety import (
    check_content_safety,
    get_redirect_message,
    sanitize_for_child,
)
from backend.providers.base import SafetyError


class TestContentSafety:

    def test_safe_message_passes(self):
        assert check_content_safety("How are you today?") is None
        assert check_content_safety("I like to play football") is None
        assert check_content_safety("Can you help me learn English?") is None

    def test_violence_blocked(self):
        result = check_content_safety("I want to kill someone")
        assert result == "violence"

    def test_sexual_content_blocked(self):
        result = check_content_safety("Show me porn")
        assert result == "sexual"

    def test_self_harm_blocked(self):
        result = check_content_safety("I want to kill myself")
        assert result == "self_harm"

    def test_drugs_blocked(self):
        result = check_content_safety("How to get cocaine")
        assert result == "drugs"

    def test_personal_info_blocked(self):
        result = check_content_safety("What is your address?")
        assert result == "personal_info_request"

    def test_ai_output_raises_safety_error(self):
        with pytest.raises(SafetyError):
            check_content_safety("Let me tell you about weapons and guns", is_user_message=False)

    def test_redirect_messages_exist(self):
        for category in ["violence", "sexual", "self_harm", "drugs", "personal_info_request"]:
            msg = get_redirect_message(category)
            assert msg
            assert len(msg) > 10

    def test_unknown_category_redirect(self):
        msg = get_redirect_message("unknown_category")
        assert msg  # Should have a default

    def test_case_insensitive(self):
        result = check_content_safety("KILL someone")
        assert result == "violence"


class TestSanitizeForChild:

    def test_clean_text_unchanged(self):
        assert sanitize_for_child("Hello friend!") == "Hello friend!"

    def test_mild_profanity_replaced(self):
        result = sanitize_for_child("That was stupid of me")
        assert "stupid" not in result
        assert "***" in result

    def test_empty_text(self):
        assert check_content_safety("") is None
        assert check_content_safety(None) is None  # type: ignore
