"""
Comprehensive tests for Speakaboo providers.
"""

import pytest
import json

from backend.providers.base import (
    SttProvider, LlmProvider, TtsProvider,
    Message, ProviderError,
)
from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider


class TestMockSttProvider:
    """Tests for MockSttProvider."""

    @pytest.fixture
    def stt(self):
        return MockSttProvider()

    @pytest.mark.asyncio
    async def test_transcribe_returns_text(self, stt):
        result = await stt.transcribe(b"\x00" * 1000)
        assert result.text == "Hello, how are you today?"
        assert result.language == "en"
        assert result.duration_seconds > 0
        assert result.confidence > 0

    @pytest.mark.asyncio
    async def test_transcribe_custom_text(self, stt):
        stt.set_next_response("I went to school yesterday")
        result = await stt.transcribe(b"\x00" * 500)
        assert result.text == "I went to school yesterday"

    @pytest.mark.asyncio
    async def test_transcribe_empty_audio_raises(self, stt):
        with pytest.raises(ProviderError):
            await stt.transcribe(b"")

    @pytest.mark.asyncio
    async def test_provider_name(self, stt):
        assert stt.name == "mock_stt"


class TestMockLlmProvider:
    """Tests for MockLlmProvider."""

    @pytest.fixture
    def llm(self):
        return MockLlmProvider()

    @pytest.mark.asyncio
    async def test_chat_returns_response(self, llm):
        messages = [Message(role="user", content="Hello")]
        result = await llm.chat(messages)
        assert result.content
        assert result.tokens_in > 0
        assert result.tokens_out > 0

    @pytest.mark.asyncio
    async def test_chat_json_mode(self, llm):
        messages = [Message(role="user", content="Hello")]
        result = await llm.chat(messages, json_mode=True)
        # Should return valid JSON
        data = json.loads(result.content)
        assert "reply" in data
        assert "version" in data

    @pytest.mark.asyncio
    async def test_chat_custom_response(self, llm):
        llm.set_next_response("Custom reply here")
        messages = [Message(role="user", content="Test")]
        result = await llm.chat(messages)
        assert result.content == "Custom reply here"

    @pytest.mark.asyncio
    async def test_chat_no_messages_raises(self, llm):
        with pytest.raises(ProviderError):
            await llm.chat([])

    @pytest.mark.asyncio
    async def test_provider_name(self, llm):
        assert llm.name == "mock_llm"


class TestMockTtsProvider:
    """Tests for MockTtsProvider."""

    @pytest.fixture
    def tts(self):
        return MockTtsProvider()

    @pytest.mark.asyncio
    async def test_synthesize_returns_audio(self, tts):
        result = await tts.synthesize("Hello world", "test-voice")
        assert result.audio
        assert len(result.audio) > 0
        assert result.format == "wav"
        assert result.characters_billed == len("Hello world")

    @pytest.mark.asyncio
    async def test_synthesize_valid_wav(self, tts):
        result = await tts.synthesize("Test", "voice")
        # Check WAV header
        assert result.audio[:4] == b"RIFF"
        assert result.audio[8:12] == b"WAVE"

    @pytest.mark.asyncio
    async def test_synthesize_empty_text_raises(self, tts):
        with pytest.raises(ProviderError):
            await tts.synthesize("", "voice")

    @pytest.mark.asyncio
    async def test_provider_name(self, tts):
        assert tts.name == "mock_tts"
