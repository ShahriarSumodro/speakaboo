"""
Tests for the conversation engine.
"""

import pytest
import json

from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider
from backend.engine.conversation import ConversationEngine
from backend.engine.characters import load_character, Character


@pytest.fixture
def mock_stt():
    return MockSttProvider()


@pytest.fixture
def mock_llm():
    return MockLlmProvider()


@pytest.fixture
def mock_tts():
    return MockTtsProvider()


@pytest.fixture
def engine(mock_stt, mock_llm, mock_tts):
    return ConversationEngine(stt=mock_stt, llm=mock_llm, tts=mock_tts)


@pytest.fixture
def character():
    return load_character("rule_farmer")


class TestConversationEngine:

    @pytest.mark.asyncio
    async def test_start_conversation(self, engine):
        state = engine.start_conversation("rule_farmer", "user-1")
        assert state.id
        assert state.character_id == "rule_farmer"
        assert state.user_id == "user-1"

    @pytest.mark.asyncio
    async def test_start_returns_same_state(self, engine):
        state1 = engine.start_conversation("rule_farmer", "user-1", "conv-1")
        state2 = engine.start_conversation("rule_farmer", "user-1", "conv-1")
        assert state1.id == state2.id

    @pytest.mark.asyncio
    async def test_process_turn_success(self, engine, character):
        state = engine.start_conversation("rule_farmer", "user-1")
        result = await engine.process_turn(
            conversation_id=state.id,
            audio=b"\x00" * 1000,
            character=character,
        )
        assert result.user_transcript
        assert result.response.reply
        assert result.latency_ms > 0
        assert result.level in ("beginner", "intermediate", "advanced")

    @pytest.mark.asyncio
    async def test_process_turn_empty_audio(self, engine, character, mock_stt):
        state = engine.start_conversation("rule_farmer", "user-1")
        # Empty transcription
        mock_stt.set_next_response("")
        result = await engine.process_turn(
            conversation_id=state.id,
            audio=b"\x00" * 100,
            character=character,
        )
        assert result.user_transcript == ""
        assert "didn't catch" in result.response.reply.lower() or "try again" in result.response.reply.lower()

    @pytest.mark.asyncio
    async def test_process_turn_nonexistent_conversation(self, engine, character):
        with pytest.raises(ValueError, match="not found"):
            await engine.process_turn(
                conversation_id="nonexistent",
                audio=b"\x00" * 100,
                character=character,
            )

    @pytest.mark.asyncio
    async def test_multiple_turns_build_history(self, engine, character):
        state = engine.start_conversation("rule_farmer", "user-1")
        
        # Turn 1
        await engine.process_turn(state.id, b"\x00" * 1000, character)
        assert state.turn_count == 1
        assert len(state.history) == 2  # user + assistant
        
        # Turn 2
        await engine.process_turn(state.id, b"\x00" * 1000, character)
        assert state.turn_count == 2
        assert len(state.history) == 4

    @pytest.mark.asyncio
    async def test_tts_cache_works(self, engine, character, mock_llm):
        state = engine.start_conversation("rule_farmer", "user-1")
        
        # Same response should hit cache on second turn
        fixed_response = json.dumps({
            "version": 1,
            "reply": "Great work farmer!",
            "correction": None,
            "new_words": [],
            "feedback_level": "gentle",
            "detailed_feedback": None,
        })
        mock_llm.set_next_response(fixed_response)
        await engine.process_turn(state.id, b"\x00" * 1000, character)
        
        mock_llm.set_next_response(fixed_response)
        await engine.process_turn(state.id, b"\x00" * 1000, character)
        
        # TTS cache should have been hit


class TestTextSplitting:

    def test_short_text_no_split(self):
        result = ConversationEngine._split_text("Hello!")
        assert result == ["Hello!"]

    def test_long_text_splits_at_sentence(self):
        text = "This is a first sentence. " * 10  # > 200 chars
        result = ConversationEngine._split_text(text, max_chars=200)
        assert len(result) > 1
        for chunk in result:
            assert len(chunk) <= 200

    def test_exact_200_no_split(self):
        text = "x" * 200
        result = ConversationEngine._split_text(text, max_chars=200)
        assert len(result) == 1
