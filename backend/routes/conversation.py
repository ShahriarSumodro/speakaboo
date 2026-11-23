"""
Conversation routes for Speakaboo.

Handles the core turn-based conversation flow.
"""

import base64
import json
import logging
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional

from backend.providers.base import ProviderError, RateLimitError
from backend.engine.characters import load_character
from backend.engine.conversation import ConversationEngine, TurnResult
from backend.engine.correction import TurnResponse
from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider

logger = logging.getLogger("speakaboo.routes.conversation")

router = APIRouter(prefix="/api/conversation", tags=["conversation"])

# Initialize with mock providers (will be replaced with real providers from config)
_engine: Optional[ConversationEngine] = None


def get_engine() -> ConversationEngine:
    """Get or create the conversation engine."""
    global _engine
    if _engine is None:
        _engine = ConversationEngine(
            stt=MockSttProvider(),
            llm=MockLlmProvider(),
            tts=MockTtsProvider(),
        )
    return _engine


def set_engine(engine: ConversationEngine) -> None:
    """Set the conversation engine (for testing or config-based initialization)."""
    global _engine
    _engine = engine


class StartConversationRequest(BaseModel):
    user_id: str
    character_id: str
    conversation_id: Optional[str] = None


class StartConversationResponse(BaseModel):
    conversation_id: str
    character_name: str
    greeting: str


class TurnResponseModel(BaseModel):
    conversation_id: str
    turn_id: str
    user_transcript: str
    reply: str
    correction: Optional[dict] = None
    new_words: list[str] = []
    audio_base64: list[str] = []
    level: str
    latency_ms: float
    safety_blocked: bool = False


@router.post("/start", response_model=StartConversationResponse)
async def start_conversation(request: StartConversationRequest):
    """Start a new conversation with a character."""
    try:
        character = load_character(request.character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Character not found: {request.character_id}")

    engine = get_engine()
    state = engine.start_conversation(
        character_id=request.character_id,
        user_id=request.user_id,
        conversation_id=request.conversation_id,
    )

    return StartConversationResponse(
        conversation_id=state.id,
        character_name=character.name,
        greeting=character.greeting,
    )


@router.post("/turn", response_model=TurnResponseModel)
async def process_turn(
    conversation_id: str = Form(...),
    audio: UploadFile = File(...),
    audio_format: str = Form("wav"),
):
    """Process one conversation turn.
    
    Upload audio, get back transcript + AI reply + correction + audio.
    """
    engine = get_engine()
    state = engine.get_conversation(conversation_id)
    if not state:
        raise HTTPException(status_code=404, detail=f"Conversation not found: {conversation_id}")

    try:
        character = load_character(state.character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Character data missing")

    # Read audio
    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

    try:
        result = await engine.process_turn(
            conversation_id=conversation_id,
            audio=audio_bytes,
            character=character,
            audio_format=audio_format,
        )
    except RateLimitError as e:
        raise HTTPException(
            status_code=429,
            detail="Our AI is busy right now. Please try again in a moment.",
            headers={"Retry-After": str(int(e.retry_after))} if e.retry_after else None,
        )
    except ProviderError as e:
        logger.error(f"Provider error: {e}")
        raise HTTPException(status_code=503, detail="Service temporarily unavailable. Please try again.")

    # Encode audio chunks as base64 for JSON response
    audio_b64 = [base64.b64encode(chunk).decode() for chunk in result.audio_chunks]

    return TurnResponseModel(
        conversation_id=result.conversation_id,
        turn_id=result.turn_id,
        user_transcript=result.user_transcript,
        reply=result.response.reply,
        correction=result.response.correction.__dict__ if result.response.correction else None,
        new_words=result.response.new_words,
        audio_base64=audio_b64,
        level=result.level,
        latency_ms=result.latency_ms,
        safety_blocked=result.safety_blocked,
    )
