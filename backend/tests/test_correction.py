"""
Tests for the correction engine.
"""

import pytest
import json

from backend.engine.correction import parse_turn_response, TurnResponse, Correction


class TestParseResponse:

    def test_valid_json_response(self):
        raw = json.dumps({
            "version": 1,
            "reply": "Good job! Keep going.",
            "correction": {
                "original": "I goes to school",
                "better": "I go to school",
                "reason_short": "Subject-verb agreement"
            },
            "new_words": ["agreement"],
            "feedback_level": "gentle",
            "detailed_feedback": None,
        })
        result = parse_turn_response(raw)
        assert isinstance(result, TurnResponse)
        assert result.reply == "Good job! Keep going."
        assert result.correction is not None
        assert result.correction.original == "I goes to school"
        assert result.correction.better == "I go to school"
        assert result.new_words == ["agreement"]

    def test_no_correction(self):
        raw = json.dumps({
            "version": 1,
            "reply": "Perfect! You said that well.",
            "correction": None,
            "new_words": [],
            "feedback_level": "gentle",
            "detailed_feedback": None,
        })
        result = parse_turn_response(raw)
        assert result.correction is None
        assert result.new_words == []

    def test_markdown_wrapped_json(self):
        raw = '```json\n{"version":1,"reply":"Hello!","correction":null,"new_words":[]}\n```'
        result = parse_turn_response(raw)
        assert result.reply == "Hello!"

    def test_extra_text_around_json(self):
        raw = 'Here is my response:\n{"version":1,"reply":"Hello!","correction":null,"new_words":[]}\nDone!'
        result = parse_turn_response(raw)
        assert result.reply == "Hello!"

    def test_long_reply_truncated(self):
        raw = json.dumps({
            "version": 1,
            "reply": "A" * 300,
            "correction": None,
            "new_words": [],
        })
        result = parse_turn_response(raw)
        assert len(result.reply) <= 200

    def test_missing_reply_raises(self):
        raw = json.dumps({"version": 1, "correction": None})
        with pytest.raises(ValueError, match="Missing 'reply'"):
            parse_turn_response(raw)

    def test_invalid_json_raises(self):
        with pytest.raises(ValueError):
            parse_turn_response("not json at all")

    def test_trailing_comma_repaired(self):
        raw = '{"version":1,"reply":"Hello!","correction":null,"new_words":[],}'
        result = parse_turn_response(raw)
        assert result.reply == "Hello!"

    def test_to_dict(self):
        result = TurnResponse(
            reply="Test reply",
            correction=Correction(original="bad", better="good", reason_short="reason"),
            new_words=["word"],
        )
        d = result.to_dict()
        assert d["reply"] == "Test reply"
        assert d["correction"]["original"] == "bad"
        assert d["new_words"] == ["word"]

    def test_feedback_level_validation(self):
        raw = json.dumps({
            "version": 1,
            "reply": "Hello!",
            "correction": None,
            "new_words": [],
            "feedback_level": "invalid_level",
        })
        result = parse_turn_response(raw)
        assert result.feedback_level == "gentle"  # Falls back to gentle

    def test_single_focus_error_guard_prioritizes_tenses_over_articles(self):
        """When multiple corrections are present, highest pedagogical priority is kept."""
        raw = json.dumps({
            "version": 1,
            "reply": "I see what happened.",
            "corrections": [
                {
                    "original": "a orange",
                    "better": "an orange",
                    "reason_short": "use an before vowels",
                },
                {
                    "original": "Yesterday I go",
                    "better": "Yesterday I went",
                    "reason_short": "past tense requires went",
                },
            ],
            "new_words": [],
        })
        result = parse_turn_response(raw)
        assert result.correction is not None
        # tenses_and_verbs (priority 1) beats articles (priority 4)
        assert result.correction.original == "Yesterday I go"
        assert result.correction.better == "Yesterday I went"
        assert result.correction.category == "tenses_and_verbs"
