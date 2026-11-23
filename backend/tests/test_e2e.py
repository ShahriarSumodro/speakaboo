"""
End-to-end test: one full conversation turn using mock providers.
"""

import pytest
import json

from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider
from backend.engine.conversation import ConversationEngine
from backend.engine.characters import load_character


@pytest.mark.asyncio
async def test_full_turn_e2e():
    """Full pipeline: audio → STT → safety → LLM → correction → TTS → result."""
    # Setup
    stt = MockSttProvider(default_text="I goes to school yesterday")
    llm = MockLlmProvider()
    tts = MockTtsProvider()
    
    # Set a realistic LLM response with correction
    llm.set_next_response(json.dumps({
        "version": 1,
        "reply": "Good try! Keep at it, farmer style!",
        "correction": {
            "original": "I goes to school",
            "better": "I went to school",
            "reason_short": "Past tense: 'went' not 'goes'"
        },
        "new_words": ["yesterday"],
        "feedback_level": "gentle",
        "detailed_feedback": None,
    }))
    
    engine = ConversationEngine(stt=stt, llm=llm, tts=tts)
    character = load_character("rule_farmer")
    
    # Start conversation
    state = engine.start_conversation("rule_farmer", "test-user-1")
    
    # Process turn
    result = await engine.process_turn(
        conversation_id=state.id,
        audio=b"\x00" * 2000,  # fake audio
        character=character,
    )
    
    # Assertions
    assert result.user_transcript == "I goes to school yesterday"
    assert result.response.reply == "Good try! Keep at it, farmer style!"
    assert result.response.correction is not None
    assert result.response.correction.original == "I goes to school"
    assert result.response.correction.better == "I went to school"
    assert result.response.new_words == ["yesterday"]
    assert len(result.audio_chunks) > 0  # TTS generated audio
    assert result.stt_seconds > 0
    assert result.latency_ms > 0
    assert result.level == "beginner"
    assert not result.safety_blocked


@pytest.mark.asyncio
async def test_safety_blocked_turn():
    """Unsafe user input is redirected."""
    stt = MockSttProvider(default_text="I want to kill someone")
    llm = MockLlmProvider()
    tts = MockTtsProvider()
    
    engine = ConversationEngine(stt=stt, llm=llm, tts=tts)
    character = load_character("rule_farmer")
    state = engine.start_conversation("rule_farmer", "test-user-2")
    
    result = await engine.process_turn(
        conversation_id=state.id,
        audio=b"\x00" * 1000,
        character=character,
    )
    
    assert result.safety_blocked
    assert result.safety_redirect
    # LLM should NOT have been called (redirect was immediate)


@pytest.mark.asyncio
async def test_malformed_json_fallback():
    """Malformed LLM JSON triggers fallback response."""
    stt = MockSttProvider(default_text="Hello there")
    llm = MockLlmProvider()
    tts = MockTtsProvider()
    
    # Set invalid JSON response
    llm.set_next_response("This is not JSON")
    
    engine = ConversationEngine(stt=stt, llm=llm, tts=tts)
    character = load_character("rule_farmer")
    state = engine.start_conversation("rule_farmer", "test-user-3")
    
    result = await engine.process_turn(
        conversation_id=state.id,
        audio=b"\x00" * 1000,
        character=character,
    )
    
    # Should use fallback instead of crashing
    assert result.response.reply
    assert result.latency_ms > 0
