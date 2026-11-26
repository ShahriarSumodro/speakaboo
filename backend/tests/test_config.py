"""
Tests for config loading.
"""

import os
import dataclasses
from backend.config import load_settings, Settings


def test_load_settings_defaults():
    """Settings load with sensible defaults when no env vars are set."""
    settings = load_settings()
    assert isinstance(settings, Settings)
    assert settings.server.port == 8000
    assert settings.safety.enabled is True
    assert settings.features.constructive_criticism_mode is False


def test_settings_immutable():
    """Settings are frozen dataclasses."""
    settings = load_settings()
    try:
        settings.server = None  # type: ignore
        assert False, "Should have raised"
    except (AttributeError, TypeError, dataclasses.FrozenInstanceError):
        pass


def test_usage_config_defaults():
    """Usage limits have correct defaults."""
    settings = load_settings()
    assert settings.usage.free_daily_minutes == 10
    assert settings.usage.basic_daily_minutes == 30
    assert settings.usage.premium_daily_minutes == 120


def test_llm_defaults_use_available_non_404_models():
    """Default LLM model and fallbacks should use models available on the Groq key."""
    from backend.config import LlmConfig
    cfg = LlmConfig()
    assert cfg.model == "qwen/qwen3.8-27b"
    assert cfg.max_tokens >= 512
    assert "llama-3.3-70b-versatile" not in cfg.fallback_models
    assert "llama-3.1-8b-instant" not in cfg.fallback_models
