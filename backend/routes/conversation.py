"""
Conversation routes for Speakaboo.

Handles both synchronous turn-based conversation and low-latency SSE streaming turns.
Enforces character entitlement and daily practice limit checks.
"""

import base64
import json
import logging
import time
from typing import Optional, AsyncGenerator

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from backend.config import load_settings
from backend.engine.characters import load_character
from backend.engine.conversation import ConversationEngine, TurnResult
from backend.engine.correction import TurnResponse
from backend.providers.base import ProviderError, RateLimitError
from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider
from backend.providers.groq_stt import GroqSttProvider
from backend.providers.groq_llm import GroqLlmProvider
from backend.providers.groq_tts import GroqTtsProvider
from backend.repositories import get_repository
from backend.models.learning import SafetyFlag
from backend.engine.missions import MissionsEngine
from backend.engine.vocabulary import VocabularyEngine
from backend.engine.auth_token import get_current_user_id

logger = logging.getLogger("speakaboo.routes.conversation")

router = APIRouter(prefix="/api/conversation", tags=["conversation"])

_engine: Optional[ConversationEngine] = None


def get_engine() -> ConversationEngine:
    """Get or create the conversation engine with configured providers."""
    global _engine
    if _engine is None:
        settings = load_settings()
        if settings.server.test_mode or settings.stt.provider == "mock":
            _engine = ConversationEngine(
                stt=MockSttProvider(),
                llm=MockLlmProvider(),
                tts=MockTtsProvider(),
            )
        else:
            _engine = ConversationEngine(
                stt=GroqSttProvider(api_key=settings.stt.api_key, model=settings.stt.model),
                llm=GroqLlmProvider(
                    api_key=settings.llm.api_key,
                    model=settings.llm.model,
                    fallback_models=list(settings.llm.fallback_models),
                ),
                tts=GroqTtsProvider(
                    api_key=settings.tts.api_key,
                    model=settings.tts.model,
                    default_voice=settings.tts.voice,
                ),
            )
    return _engine


def set_engine(engine: ConversationEngine) -> None:
    """Set the conversation engine (e.g. for testing)."""
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
    cost_usd: float = 0.0
    safety_blocked: bool = False


async def _check_entitlements_and_caps(state, character):
    """Enforce character unlock entitlements and daily practice limits."""
    settings = load_settings()
    repo = await get_repository()

    # 1. Check Character Unlock Entitlement if character is locked (allow 2-minute free trial)
    if character.locked:
        ents = await repo.get_entitlements(state.user_id)
        now = time.time()
        has_character = any(
            e.type == "character" and e.value == character.id and (e.expires_at is None or e.expires_at > now)
            for e in ents
        )
        if not has_character:
            seconds_used = await repo.get_character_usage_seconds(state.user_id, character.id)
            if seconds_used >= 120.0:
                raise HTTPException(
                    status_code=403,
                    detail=f"Your 2-minute free trial with {character.name} has ended! Unlock {character.name} for {character.price_bdt} BDT to continue.",
                )

    # 2. Check Daily Practice Cap
    ents = await repo.get_entitlements(state.user_id)
    now = time.time()
    has_monthly = any(
        e.type == "plan" and (e.expires_at is None or e.expires_at > now)
        for e in ents
    )
    daily_cap = settings.usage.basic_daily_minutes if has_monthly else settings.usage.free_daily_minutes

    usage = await repo.get_daily_usage(state.user_id)
    if usage and usage.minutes_spoken >= daily_cap:
        raise HTTPException(
            status_code=403,
            detail=f"Daily limit of {daily_cap} minutes reached. Come back tomorrow or upgrade for more practice time!",
        )


async def _record_turn_metrics(state, result):
    """Record metrics, gamification XP, and vocabulary into repository."""
    try:
        repo = await get_repository()
        if result.safety_blocked:
            await repo.log_safety_flag(
                SafetyFlag(
                    user_id=state.user_id,
                    category=result.response.reply,
                    snippet=result.user_transcript[:100],
                )
            )
        else:
            minutes = max(0.01, result.stt_seconds / 60.0)
            await repo.increment_usage(state.user_id, minutes)
            await repo.record_activity(state.user_id, xp_earned=10 + int(minutes * 20))

            missions = MissionsEngine(repo)
            await missions.track_speaking_time(state.user_id, minutes)
            if result.response.new_words:
                await missions.track_new_words(state.user_id, len(result.response.new_words))

            vocab = VocabularyEngine(repo)
            corr_dict = result.response.correction.__dict__ if result.response.correction else None
            await vocab.add_from_turn(
                user_id=state.user_id,
                new_words=result.response.new_words,
                correction=corr_dict,
                context_sentence=result.user_transcript,
            )

            # Track 2-minute trial seconds for locked character
            character = load_character(state.character_id)
            if character.locked:
                ents = await repo.get_entitlements(state.user_id)
                now = time.time()
                has_character = any(
                    e.type == "character" and e.value == character.id and (e.expires_at is None or e.expires_at > now)
                    for e in ents
                )
                if not has_character:
                    turn_sec = max(5.0, result.stt_seconds)
                    await repo.increment_character_usage_seconds(state.user_id, character.id, turn_sec)
    except Exception as e:
        logger.warning(f"Could not record turn metrics: {e}")


@router.post("/start", response_model=StartConversationResponse)
async def start_conversation(request: StartConversationRequest):
    """Start a new conversation with a character."""
    try:
        character = load_character(request.character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Character not found: {request.character_id}")

    if character.locked:
        repo = await get_repository()
        ents = await repo.get_entitlements(request.user_id)
        now = time.time()
        has_character = any(
            e.type == "character" and e.value == character.id and (e.expires_at is None or e.expires_at > now)
            for e in ents
        )
        if not has_character:
            seconds_used = await repo.get_character_usage_seconds(request.user_id, character.id)
            if seconds_used >= 120.0:
                raise HTTPException(
                    status_code=403,
                    detail=f"Your 2-minute free trial with {character.name} has ended! Unlock {character.name} for {character.price_bdt} BDT to continue.",
                )

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
    """Process one conversation turn synchronously."""
    engine = get_engine()
    state = engine.get_conversation(conversation_id)
    if not state:
        raise HTTPException(status_code=404, detail=f"Conversation not found: {conversation_id}")

    try:
        character = load_character(state.character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Character data missing")

    await _check_entitlements_and_caps(state, character)

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

    audio_b64 = [base64.b64encode(chunk).decode() for chunk in result.audio_chunks]

    await _record_turn_metrics(state, result)

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
        cost_usd=result.cost_usd,
        safety_blocked=result.safety_blocked,
    )


@router.post("/stream-turn")
async def process_stream_turn(
    conversation_id: str = Form(...),
    audio: UploadFile = File(...),
    audio_format: str = Form("wav"),
):
    """Process a turn with Server-Sent Events (SSE) streaming.
    
    Streams transcript early, then reply text and TTS audio chunks sentence-by-sentence.
    """
    engine = get_engine()
    state = engine.get_conversation(conversation_id)
    if not state:
        raise HTTPException(status_code=404, detail=f"Conversation not found: {conversation_id}")

    try:
        character = load_character(state.character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Character data missing")

    await _check_entitlements_and_caps(state, character)

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

    async def event_generator() -> AsyncGenerator[str, None]:
        try:
            async for ev in engine.stream_turn(
                conversation_id=conversation_id,
                audio=audio_bytes,
                character=character,
                audio_format=audio_format,
            ):
                event_name = ev.get("event", "message")
                event_data = json.dumps(ev.get("data", {}))
                yield f"event: {event_name}\ndata: {event_data}\n\n"

                # When turn complete is reached, record metrics in repository
                if event_name == "turn_complete":
                    d = ev.get("data", {})
                    # Lightweight TurnResult dummy for metric recorder
                    dummy_res = TurnResult(
                        conversation_id=conversation_id,
                        turn_id=d.get("turn_id", ""),
                        user_transcript=state.user_transcripts[-1] if state.user_transcripts else "",
                        response=TurnResponse(
                            reply=d.get("reply", ""),
                            new_words=d.get("new_words", []),
                        ),
                        audio_chunks=[],
                        level=d.get("level", "beginner"),
                        stt_seconds=d.get("stt_seconds", 1.0),
                        safety_blocked=d.get("safety_blocked", False),
                    )
                    await _record_turn_metrics(state, dummy_res)

        except Exception as e:
            logger.error(f"Error in stream_turn event generator: {e}")
            err_data = json.dumps({"error": str(e)})
            yield f"event: error\ndata: {err_data}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
