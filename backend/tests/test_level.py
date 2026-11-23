"""
Tests for the level adaptation engine.
"""

import pytest

from backend.engine.level import estimate_level


class TestLevelEstimation:

    def test_empty_returns_beginner(self):
        assert estimate_level([]) == "beginner"

    def test_simple_sentences_beginner(self):
        texts = [
            "I am happy.",
            "I like food.",
            "My name is good.",
            "I go to school.",
            "I have a friend.",
        ]
        assert estimate_level(texts) == "beginner"

    def test_complex_sentences_advanced(self):
        texts = [
            "The environmental implications of deforestation are multifaceted and profoundly significant.",
            "Contemporary discourse surrounding artificial intelligence necessitates careful philosophical examination.",
            "The juxtaposition of traditional values against modernization creates fascinating sociological tensions.",
        ]
        assert estimate_level(texts) == "advanced"

    def test_window_respects_limit(self):
        # 10 beginner sentences + 2 advanced ones
        texts = ["I am happy."] * 10 + [
            "The philosophical ramifications are extraordinarily complex.",
            "Juxtaposition of contemporary sociological frameworks is fascinating.",
        ]
        # With window=2, should see only the advanced ones
        result = estimate_level(texts, window=2)
        assert result in ("intermediate", "advanced")

    def test_single_sentence(self):
        result = estimate_level(["Hello"])
        assert result == "beginner"
