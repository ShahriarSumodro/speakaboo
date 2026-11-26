"""
Conversation routes for Speakaboo.

Handles both synchronous turn-based conversation and low-latency SSE streaming turns.
Enforces character entitlement and daily practice limit checks.
"""

import base64
import json
import logging
import os
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
from backend.models.user import MistakeLog
from backend.engine.missions import MissionsEngine
from backend.engine.vocabulary import VocabularyEngine
from backend.engine.auth_token import get_current_user_id
from backend.engine.placement import evaluate_placement

logger = logging.getLogger("speakaboo.routes.conversation")

router = APIRouter(prefix="/api/conversation", tags=["conversation"])

_engine: Optional[ConversationEngine] = None


def get_engine() -> ConversationEngine:
    """Get or create the conversation engine with configured providers."""
    global _engine
    if _engine is None:
        settings = load_settings()
        is_test = os.environ.get("TEST_MODE", "").lower() in ("true", "1", "yes") or settings.server.test_mode or settings.stt.provider == "mock"
        if is_test:
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
    practice_mode: Optional[str] = "accuracy"
    coach_mode: Optional[str] = "balanced"
    age_band: Optional[str] = None


class StartConversationResponse(BaseModel):
    conversation_id: str
    character_name: str
    greeting: str
    is_trial: bool = False
    trial_seconds_remaining: Optional[int] = None
    tts_error: Optional[str] = None


class HintRequest(BaseModel):
    conversation_id: str


class HintResponse(BaseModel):
    conversation_id: str
    sentence_starter: str
    model_answer: str
    vocabulary_hints: list[str]


class SummaryRequest(BaseModel):
    conversation_id: str


class PlacementRequest(BaseModel):
    user_id: str
    spoken_text: str
    duration_seconds: float = 30.0


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
    is_trial: bool = False
    trial_seconds_remaining: Optional[int] = None
    tts_error: Optional[str] = None


def _categorize_error(original: str, better: str, reason: str) -> str:
    """Categorize grammar mistakes to track learner error patterns (Bengali learner hypotheses)."""
    import re
    orig_l = original.lower()
    reason_l = reason.lower()
    if any(s in reason_l for s in ["agreement", "subject-verb"]):
        return "subject_verb_agreement"
    if "preposition" in reason_l or any(re.search(rf"\b{p}\b", orig_l) for p in ["in", "on", "at", "to", "for", "with", "by", "from"]):
        return "prepositions"
    if "article" in reason_l or re.search(r"\b(a|an|the)\b", orig_l):
        return "articles"
    if any(k in reason_l for k in ["tense", "past", "went", "did", "was", "were"]) or (
        "verb" in reason_l and "subject-verb" not in reason_l
    ):
        return "tenses_and_verbs"
    if any(s in reason_l for s in ["plural", "singular"]):
        return "subject_verb_agreement"
    return "word_choice"


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

            # Record mistake category in mistake_logs
            if corr_dict and corr_dict.get("original") and corr_dict.get("better"):
                cat = _categorize_error(
                    corr_dict.get("original", ""),
                    corr_dict.get("better", ""),
                    corr_dict.get("reason_short", ""),
                )
                await repo.log_mistake(
                    MistakeLog(
                        user_id=state.user_id,
                        category=cat,
                        original=corr_dict.get("original", ""),
                        better=corr_dict.get("better", ""),
                    )
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

    is_trial = False
    trial_seconds_remaining = None
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
            is_trial = True
            trial_seconds_remaining = max(0, int(120 - seconds_used))

    engine = get_engine()
    repo = await get_repository()
    age_band = request.age_band
    prof = await repo.get_profile(request.user_id)
    if not age_band and prof and prof.age_band:
        age_band = prof.age_band.value if hasattr(prof.age_band, "value") else str(prof.age_band)

    state = engine.start_conversation(
        character_id=request.character_id,
        user_id=request.user_id,
        conversation_id=request.conversation_id,
        practice_mode=request.practice_mode or "accuracy",
        coach_mode=request.coach_mode or "balanced",
        age_band=age_band or "teen",
    )

    # Check companion memory for personalized greeting
    greeting = character.greeting
    memory = await repo.get_character_memory(request.user_id, request.character_id)
    if memory and memory.get("learner_name") and memory["learner_name"] != "Learner":
        name = memory["learner_name"]
        last_topic = memory.get("last_topic")
        if last_topic:
            greeting = f"Welcome back, {name}! Are you ready to continue our conversation about {last_topic}?"
        else:
            greeting = f"Welcome back, {name}! Great to see you again for our daily talk."
    elif memory and memory.get("last_topic"):
        greeting = f"Welcome back! Are you ready to practice more speaking about {memory['last_topic']}?"

    return StartConversationResponse(
        conversation_id=state.id,
        character_name=character.name,
        greeting=greeting,
        is_trial=is_trial,
        trial_seconds_remaining=trial_seconds_remaining,
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

    is_trial = False
    trial_seconds_remaining = None
    if character.locked:
        ents = await repo.get_entitlements(state.user_id)
        now = time.time()
        has_character = any(
            e.type == "character" and e.value == character.id and (e.expires_at is None or e.expires_at > now)
            for e in ents
        )
        if not has_character:
            is_trial = True
            seconds_used = await repo.get_character_usage_seconds(state.user_id, character.id)
            trial_seconds_remaining = max(0, int(120 - seconds_used))

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
        is_trial=is_trial,
        trial_seconds_remaining=trial_seconds_remaining,
        tts_error=result.tts_error,
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
                payload = dict(ev.get("data", {}))
                payload.setdefault("type", event_name)
                event_data = json.dumps(payload)
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


@router.post("/hint", response_model=HintResponse)
async def get_conversation_hint(request: HintRequest):
    """Generate a pedagogical sentence starter, model answer, and vocabulary hint."""
    engine = get_engine()
    state = engine.get_conversation(request.conversation_id)
    if not state:
        raise HTTPException(status_code=404, detail=f"Conversation not found: {request.conversation_id}")

    hint = engine.get_hint(request.conversation_id)
    return HintResponse(**hint)


@router.post("/summary")
async def get_session_summary(request: SummaryRequest):
    """Retrieve pedagogical coaching summary and retention hook for the session."""
    engine = get_engine()
    state = engine.get_conversation(request.conversation_id)
    if not state:
        raise HTTPException(status_code=404, detail=f"Conversation not found: {request.conversation_id}")

    summary = engine.get_session_summary(request.conversation_id)

    # Persist character memory for next conversation greeting
    try:
        repo = await get_repository()
        profile = await repo.get_profile(state.user_id)
        learner_name = profile.display_name if profile else "Learner"
        learner_goal = profile.goal if profile else ""
        last_topic = state.user_transcripts[-1][:40] if state.user_transcripts else ""
        await repo.save_character_memory(
            user_id=state.user_id,
            character_id=state.character_id,
            learner_name=learner_name,
            goal=learner_goal,
            last_topic=last_topic,
            last_hook=summary.get("tomorrow_hook", ""),
            last_summary=summary.get("concrete_next_step", ""),
        )
    except Exception as e:
        logger.warning(f"Could not persist character memory: {e}")

    return summary


@router.post("/placement")
async def assess_placement(
    request: PlacementRequest,
    current_user_id: str = Depends(get_current_user_id),
):
    """Evaluate a spoken placement diagnostic and persist estimated level to profile."""
    if request.user_id != current_user_id:
        raise HTTPException(status_code=403, detail="Cannot update placement for another user")

    result = evaluate_placement(request.spoken_text, request.duration_seconds)
    repo = await get_repository()
    profile = await repo.get_profile(request.user_id)
    if not profile:
        from backend.models.user import UserProfile
        profile = UserProfile(user_id=request.user_id)
    profile.level = result.level
    await repo.save_profile(profile)

    return {
        "user_id": request.user_id,
        "level": result.level,
        "cefr_level": result.cefr_level,
        "cefr_score": result.cefr_score,
        "wpm": result.wpm,
        "vocabulary_variety": result.vocabulary_variety,
        "summary": result.summary,
        "strengths": result.strengths,
        "recommendations": result.recommendations,
    }


@router.get("/mistakes/{user_id}")
async def get_mistakes(
    user_id: str,
    current_user_id: str = Depends(get_current_user_id),
):
    """Retrieve recurring error categories and mistake logs for a learner."""
    if user_id != current_user_id:
        raise HTTPException(status_code=403, detail="Cannot access other user's mistakes")

    repo = await get_repository()
    mistakes = await repo.get_mistakes(user_id)
    return [
        {
            "id": m.id,
            "category": m.category,
            "original": m.original,
            "better": m.better,
            "count": m.count,
            "last_seen_at": m.last_seen_at,
        }
        for m in mistakes
    ]
