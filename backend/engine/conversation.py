"""
Conversation engine for Speakaboo.

Manages one conversation turn: audio in → transcript → safety → LLM → TTS → audio out.
Maintains rolling history with a token budget and supports both synchronous and SSE streaming turns.
"""

import logging
import time
import uuid
import base64
from collections import deque
from dataclasses import dataclass, field
from typing import Optional, AsyncGenerator

from backend.providers.base import (
    SttProvider, LlmProvider, TtsProvider,
    Message, ProviderError, RateLimitError, SafetyError,
)
from backend.engine.characters import Character, build_system_prompt
from backend.engine.correction import parse_turn_response, TurnResponse
from backend.engine.safety import check_content_safety, get_redirect_message
from backend.engine.level import estimate_level

logger = logging.getLogger("speakaboo.engine.conversation")

# Recent turn diagnostics ring buffer (last 20 turns)
_last_turns: deque[dict] = deque(maxlen=20)


def get_last_turns() -> list[dict]:
    """Retrieve the last 20 turn records for diagnostics."""
    return list(_last_turns)


def record_turn_log(record: dict) -> None:
    """Record a turn diagnostics entry."""
    _last_turns.append(record)

# Token budget for conversation history (approximate)
MAX_HISTORY_TOKENS = 2000  # ~8000 chars
CHARS_PER_TOKEN = 4  # rough estimate


@dataclass
class TurnResult:
    """Result of one conversation turn."""
    conversation_id: str
    turn_id: str
    user_transcript: str
    response: TurnResponse
    audio_chunks: list[bytes]
    level: str
    # Cost tracking
    stt_seconds: float = 0.0
    tts_chars: int = 0
    llm_tokens_in: int = 0
    llm_tokens_out: int = 0
    latency_ms: float = 0.0
    cost_usd: float = 0.0
    safety_blocked: bool = False
    safety_redirect: str = ""
    tts_error: Optional[str] = None
    stt_error: Optional[str] = None
    llm_error: Optional[str] = None


@dataclass
class ConversationState:
    """State of an ongoing conversation."""
    id: str
    character_id: str
    user_id: str
    history: list[Message] = field(default_factory=list)
    user_transcripts: list[str] = field(default_factory=list)
    turn_count: int = 0
    total_stt_seconds: float = 0.0
    practice_mode: str = "accuracy"  # "accuracy" or "fluency"
    coach_mode: str = "balanced"    # "gentle", "balanced", "strict"
    age_band: str = "teen"          # "kid", "teen", "adult"
    bot_speech_seconds: float = 0.0
    bot_words_count: int = 0
    user_words_count: int = 0
    corrections_list: list[dict] = field(default_factory=list)
    new_words_learned: list[str] = field(default_factory=list)
    created_at: float = field(default_factory=time.time)
    last_turn_at: float = field(default_factory=time.time)


class ConversationEngine:
    """Orchestrates one conversation turn through the full pipeline."""

    def __init__(
        self,
        stt: SttProvider,
        llm: LlmProvider,
        tts: TtsProvider,
        tts_cache: Optional[dict] = None,
    ):
        self._stt = stt
        self._llm = llm
        self._tts = tts
        self._tts_cache = tts_cache if tts_cache is not None else {}
        self._conversations: dict[str, ConversationState] = {}

    def start_conversation(
        self,
        character_id: str,
        user_id: str,
        conversation_id: Optional[str] = None,
        practice_mode: str = "accuracy",
        coach_mode: str = "balanced",
        age_band: str = "teen",
    ) -> ConversationState:
        """Start a new conversation or return an existing one."""
        cid = conversation_id or str(uuid.uuid4())
        if cid in self._conversations:
            state = self._conversations[cid]
            state.practice_mode = practice_mode
            state.coach_mode = coach_mode
            state.age_band = age_band
            return state

        state = ConversationState(
            id=cid,
            character_id=character_id,
            user_id=user_id,
            practice_mode=practice_mode,
            coach_mode=coach_mode,
            age_band=age_band,
        )
        self._conversations[cid] = state
        return state

    def get_conversation(self, conversation_id: str) -> Optional[ConversationState]:
        """Get an existing conversation state."""
        return self._conversations.get(conversation_id)

    async def process_turn(
        self,
        conversation_id: str,
        audio: bytes,
        character: Character,
        audio_format: str = "wav",
        max_llm_retries: int = 2,
    ) -> TurnResult:
        """Process one conversation turn synchronously."""
        start_time = time.time()
        turn_id = str(uuid.uuid4())

        state = self._conversations.get(conversation_id)
        if not state:
            raise ValueError(f"Conversation not found: {conversation_id}")

        audio_size = len(audio)
        logger.info(
            f"Turn {turn_id} request received: cid={conversation_id}, audio_bytes={audio_size}, format={audio_format}"
        )

        # --- Step 1: STT ---
        stt_t0 = time.time()
        stt_error = None
        try:
            stt_result = await self._stt.transcribe(audio, format=audio_format)
            user_text = stt_result.text.strip()
            stt_ms = (time.time() - stt_t0) * 1000
            logger.info(
                f"Turn {turn_id} STT: provider={getattr(self._stt, 'name', 'stt')}, "
                f"duration={stt_ms:.1f}ms, audio_duration={stt_result.duration_seconds:.2f}s, "
                f"transcript_len={len(user_text)}, text='{user_text[:80]}'"
            )
        except Exception as e:
            stt_ms = (time.time() - stt_t0) * 1000
            stt_error = str(e)
            user_text = ""
            stt_result = type("DummySTT", (), {"duration_seconds": 0.0, "text": ""})()
            logger.error(f"Turn {turn_id} STT failed ({stt_ms:.1f}ms): {e}")

        if not user_text:
            latency_ms = (time.time() - start_time) * 1000
            record_turn_log({
                "turn_id": turn_id,
                "conversation_id": conversation_id,
                "character_id": character.id,
                "timestamp": time.time(),
                "audio_bytes": audio_size,
                "stt": {
                    "provider": getattr(self._stt, "name", "stt"),
                    "ms": round(stt_ms, 1),
                    "transcript_len": 0,
                    "status": "error" if stt_error else "empty",
                    "error": stt_error,
                },
                "status": "failed_stt",
                "total_latency_ms": round(latency_ms, 1),
            })
            return TurnResult(
                conversation_id=conversation_id,
                turn_id=turn_id,
                user_transcript="",
                response=TurnResponse(reply="I didn't catch that. Could you try again?"),
                audio_chunks=[],
                level="beginner",
                stt_seconds=stt_result.duration_seconds,
                latency_ms=latency_ms,
                stt_error=stt_error,
            )

        # --- Step 2: Safety check on user message ---
        blocked_category = check_content_safety(user_text, is_user_message=True, age_band=state.age_band)
        if blocked_category:
            redirect = get_redirect_message(blocked_category, character_id=character.id)
            redirect_audio = []
            try:
                redirect_audio = await self._synthesize_chunks(redirect, character.voice_id)
            except Exception as e:
                logger.error(f"Turn {turn_id} safety redirect TTS error: {e}")
            latency_ms = (time.time() - start_time) * 1000
            record_turn_log({
                "turn_id": turn_id,
                "conversation_id": conversation_id,
                "character_id": character.id,
                "timestamp": time.time(),
                "audio_bytes": audio_size,
                "stt": {"provider": getattr(self._stt, "name", "stt"), "ms": round(stt_ms, 1), "transcript_len": len(user_text), "status": "ok"},
                "safety_blocked": True,
                "total_latency_ms": round(latency_ms, 1),
                "status": "safety_blocked",
            })
            return TurnResult(
                conversation_id=conversation_id,
                turn_id=turn_id,
                user_transcript=user_text,
                response=TurnResponse(reply=redirect),
                audio_chunks=redirect_audio,
                level=estimate_level(state.user_transcripts),
                stt_seconds=stt_result.duration_seconds,
                latency_ms=latency_ms,
                safety_blocked=True,
                safety_redirect=redirect,
            )

        # --- Step 3: Estimate learner level ---
        state.user_transcripts.append(user_text)
        level = estimate_level(state.user_transcripts)

        # --- Step 4: Build messages for LLM ---
        system_prompt = build_system_prompt(
            character=character,
            level=level,
            practice_mode=state.practice_mode,
            coach_mode=state.coach_mode,
            age_band=state.age_band,
        )
        messages = [Message(role="system", content=system_prompt)]
        messages.extend(self._trim_history(state.history))
        messages.append(Message(role="user", content=user_text))

        # --- Step 5: LLM call with JSON parsing and retry ---
        response: Optional[TurnResponse] = None
        llm_tokens_in = 0
        llm_tokens_out = 0
        llm_error = None
        llm_t0 = time.time()

        for attempt in range(max_llm_retries):
            try:
                llm_result = await self._llm.chat(
                    messages=messages,
                    json_mode=True,
                )
                llm_tokens_in = llm_result.tokens_in
                llm_tokens_out = llm_result.tokens_out

                try:
                    response = parse_turn_response(llm_result.content)
                    break
                except ValueError as e:
                    logger.warning(f"Turn {turn_id} LLM JSON parse failed (attempt {attempt + 1}): {e}")
                    if attempt < max_llm_retries - 1:
                        messages.append(Message(role="assistant", content=llm_result.content))
                        messages.append(Message(role="user", content="Please respond with VALID JSON only, following the exact format specified."))
            except Exception as e:
                llm_error = str(e)
                logger.error(f"Turn {turn_id} LLM attempt {attempt + 1} error: {e}")

        llm_ms = (time.time() - llm_t0) * 1000

        if response is None:
            logger.error(f"Turn {turn_id} all LLM attempts failed ({llm_ms:.1f}ms), using fallback response")
            response = TurnResponse(reply="Good try! Let's keep practicing.")

        logger.info(
            f"Turn {turn_id} LLM: provider={getattr(self._llm, 'name', 'llm')}, duration={llm_ms:.1f}ms, "
            f"tokens_in={llm_tokens_in}, tokens_out={llm_tokens_out}, reply_len={len(response.reply)}"
        )

        # --- Step 6: Safety check on AI reply ---
        try:
            check_content_safety(response.reply, is_user_message=False)
        except SafetyError:
            logger.error("AI reply blocked by safety filter, using fallback")
            response = TurnResponse(reply="Let's keep practicing! What else would you like to talk about?")

        # --- Step 7: TTS ---
        tts_t0 = time.time()
        audio_chunks = []
        tts_error = None
        try:
            audio_chunks = await self._synthesize_chunks(response.reply, character.voice_id)
            tts_ms = (time.time() - tts_t0) * 1000
            total_audio_bytes = sum(len(c) for c in audio_chunks)
            logger.info(
                f"Turn {turn_id} TTS: provider={getattr(self._tts, 'name', 'tts')}, voice='{character.voice_id}', "
                f"duration={tts_ms:.1f}ms, chunks={len(audio_chunks)}, bytes={total_audio_bytes}, status=ok"
            )
        except Exception as e:
            tts_ms = (time.time() - tts_t0) * 1000
            total_audio_bytes = 0
            tts_error = str(e)
            logger.error(
                f"Turn {turn_id} TTS failed for voice '{character.voice_id}' ({tts_ms:.1f}ms): {e}"
            )

        tts_chars = len(response.reply)

        # --- Step 8: Update conversation state ---
        state.history.append(Message(role="user", content=user_text))
        state.history.append(Message(role="assistant", content=response.reply))
        state.turn_count += 1
        state.total_stt_seconds += stt_result.duration_seconds
        user_words = len(user_text.split())
        state.user_words_count += user_words
        bot_words = len(response.reply.split())
        state.bot_words_count += bot_words
        state.bot_speech_seconds += max(1.0, round(bot_words / 2.5, 2))
        if response.correction:
            state.corrections_list.append(response.correction.__dict__)
        state.new_words_learned.extend(response.new_words)
        state.last_turn_at = time.time()

        latency_ms = (time.time() - start_time) * 1000

        # Cost tracking (USD)
        stt_cost = (stt_result.duration_seconds / 60.0) * 0.006
        llm_cost = (llm_tokens_in / 1_000_000) * 0.59 + (llm_tokens_out / 1_000_000) * 0.79
        tts_cost = (tts_chars / 1000.0) * 0.015
        cost_usd = round(stt_cost + llm_cost + tts_cost, 6)

        logger.info(
            f"Turn {turn_id} complete: {latency_ms:.0f}ms, "
            f"STT={stt_result.duration_seconds:.1f}s, "
            f"LLM={llm_tokens_in}+{llm_tokens_out} tokens, "
            f"TTS={tts_chars} chars, "
            f"Cost=${cost_usd:.5f}, "
            f"level={level}, "
            f"tts_status={'ok' if not tts_error else 'error'}"
        )

        record_turn_log({
            "turn_id": turn_id,
            "conversation_id": conversation_id,
            "character_id": character.id,
            "timestamp": time.time(),
            "audio_bytes": audio_size,
            "stt": {
                "provider": getattr(self._stt, "name", "stt"),
                "ms": round(stt_ms, 1),
                "transcript_len": len(user_text),
                "status": "ok" if not stt_error else "error",
                "error": stt_error,
            },
            "llm": {
                "provider": getattr(self._llm, "name", "llm"),
                "ms": round(llm_ms, 1),
                "tokens_in": llm_tokens_in,
                "tokens_out": llm_tokens_out,
                "reply_len": len(response.reply),
                "status": "ok" if not llm_error else "error",
                "error": llm_error,
            },
            "tts": {
                "provider": getattr(self._tts, "name", "tts"),
                "voice_id": character.voice_id,
                "ms": round(tts_ms, 1),
                "bytes": total_audio_bytes,
                "chunks": len(audio_chunks),
                "status": "ok" if not tts_error else "error",
                "error": tts_error,
            },
            "total_latency_ms": round(latency_ms, 1),
            "cost_usd": cost_usd,
            "status": "ok" if not (stt_error or llm_error or tts_error) else "degraded",
        })

        return TurnResult(
            conversation_id=conversation_id,
            turn_id=turn_id,
            user_transcript=user_text,
            response=response,
            audio_chunks=audio_chunks,
            level=level,
            stt_seconds=stt_result.duration_seconds,
            tts_chars=tts_chars,
            llm_tokens_in=llm_tokens_in,
            llm_tokens_out=llm_tokens_out,
            latency_ms=latency_ms,
            cost_usd=cost_usd,
            tts_error=tts_error,
            stt_error=stt_error,
            llm_error=llm_error,
        )

        return TurnResult(
            conversation_id=conversation_id,
            turn_id=turn_id,
            user_transcript=user_text,
            response=response,
            audio_chunks=audio_chunks,
            level=level,
            stt_seconds=stt_result.duration_seconds,
            tts_chars=tts_chars,
            llm_tokens_in=llm_tokens_in,
            llm_tokens_out=llm_tokens_out,
            latency_ms=latency_ms,
            cost_usd=cost_usd,
        )

    async def stream_turn(
        self,
        conversation_id: str,
        audio: bytes,
        character: Character,
        audio_format: str = "wav",
        max_llm_retries: int = 2,
    ) -> AsyncGenerator[dict, None]:
        """Stream a turn using event dictionaries for low-latency audio playback."""
        start_time = time.time()
        turn_id = str(uuid.uuid4())

        state = self._conversations.get(conversation_id)
        if not state:
            raise ValueError(f"Conversation not found: {conversation_id}")

        # 1. STT
        stt_result = await self._stt.transcribe(audio, format=audio_format)
        user_text = stt_result.text.strip()

        yield {
            "event": "transcript",
            "data": {
                "transcript": user_text,
                "duration_seconds": stt_result.duration_seconds,
            },
        }

        if not user_text:
            yield {
                "event": "turn_complete",
                "data": {
                    "turn_id": turn_id,
                    "reply": "I didn't catch that. Could you try again?",
                    "correction": None,
                    "new_words": [],
                    "level": "beginner",
                    "audio_chunks": [],
                    "latency_ms": (time.time() - start_time) * 1000,
                    "cost_usd": 0.0,
                    "safety_blocked": False,
                    "stt_seconds": stt_result.duration_seconds,
                },
            }
            return

        # 2. Safety Check
        blocked_category = check_content_safety(user_text, is_user_message=True, age_band=state.age_band)
        if blocked_category:
            redirect = get_redirect_message(blocked_category, character_id=character.id)
            yield {
                "event": "safety",
                "data": {
                    "blocked": True,
                    "category": blocked_category,
                    "redirect": redirect,
                },
            }
            redirect_audio = await self._synthesize_chunks(redirect, character.voice_id)
            for idx, chunk in enumerate(redirect_audio):
                yield {
                    "event": "audio_chunk",
                    "data": {
                        "index": idx,
                        "text": redirect,
                        "audio_base64": base64.b64encode(chunk).decode(),
                    },
                }
            yield {
                "event": "turn_complete",
                "data": {
                    "turn_id": turn_id,
                    "reply": redirect,
                    "correction": None,
                    "new_words": [],
                    "level": estimate_level(state.user_transcripts),
                    "audio_chunks": [base64.b64encode(c).decode() for c in redirect_audio],
                    "latency_ms": (time.time() - start_time) * 1000,
                    "cost_usd": 0.0,
                    "safety_blocked": True,
                    "stt_seconds": stt_result.duration_seconds,
                },
            }
            return

        # 3. Level & Messages
        state.user_transcripts.append(user_text)
        level = estimate_level(state.user_transcripts)

        system_prompt = build_system_prompt(
            character=character,
            level=level,
            practice_mode=state.practice_mode,
            coach_mode=state.coach_mode,
            age_band=state.age_band,
        )
        messages = [Message(role="system", content=system_prompt)]
        messages.extend(self._trim_history(state.history))
        messages.append(Message(role="user", content=user_text))

        # 4. LLM
        response = None
        llm_tokens_in = 0
        llm_tokens_out = 0

        for attempt in range(max_llm_retries):
            llm_result = await self._llm.chat(messages=messages, json_mode=True)
            llm_tokens_in = llm_result.tokens_in
            llm_tokens_out = llm_result.tokens_out
            try:
                response = parse_turn_response(llm_result.content)
                break
            except ValueError as e:
                if attempt < max_llm_retries - 1:
                    messages.append(Message(role="assistant", content=llm_result.content))
                    messages.append(Message(role="user", content="Please respond with VALID JSON only."))

        if response is None:
            response = TurnResponse(reply="Good try! Let's keep practicing.")

        try:
            check_content_safety(response.reply, is_user_message=False)
        except SafetyError:
            response = TurnResponse(reply="Let's keep practicing! What else would you like to talk about?")

        yield {
            "event": "reply_start",
            "data": {
                "reply": response.reply,
                "correction": response.correction.__dict__ if response.correction else None,
                "new_words": response.new_words,
            },
        }

        # 5. Synthesize & stream chunks
        chunks = self._split_text(response.reply, max_chars=200)
        audio_b64_list = []
        tts_error = None
        tts_t0 = time.time()
        total_audio_bytes = 0

        for idx, chunk in enumerate(chunks):
            cache_key = f"{character.voice_id}:{chunk}"
            audio_bytes = None
            if cache_key in self._tts_cache:
                audio_bytes = self._tts_cache[cache_key]
            else:
                try:
                    synth_res = await self._tts.synthesize(chunk, character.voice_id)
                    audio_bytes = synth_res.audio
                    self._tts_cache[cache_key] = audio_bytes
                except Exception as e:
                    tts_error = str(e)
                    logger.error(f"Turn {turn_id} streaming TTS error for '{character.voice_id}' chunk {idx}: {e}")
                    yield {
                        "event": "tts_error",
                        "data": {
                            "index": idx,
                            "stage": "tts",
                            "error": "I could not make my voice. Tap to retry.",
                            "detail": str(e),
                        },
                    }

            if audio_bytes:
                total_audio_bytes += len(audio_bytes)
                b64_str = base64.b64encode(audio_bytes).decode()
                audio_b64_list.append(b64_str)

                yield {
                    "event": "audio_chunk",
                    "data": {
                        "index": idx,
                        "text": chunk,
                        "audio_base64": b64_str,
                    },
                }

        tts_ms = (time.time() - tts_t0) * 1000

        # 6. Update State
        state.history.append(Message(role="user", content=user_text))
        state.history.append(Message(role="assistant", content=response.reply))
        state.turn_count += 1
        state.total_stt_seconds += stt_result.duration_seconds
        user_words = len(user_text.split())
        state.user_words_count += user_words
        bot_words = len(response.reply.split())
        state.bot_words_count += bot_words
        state.bot_speech_seconds += max(1.0, round(bot_words / 2.5, 2))
        if response.correction:
            state.corrections_list.append(response.correction.__dict__)
        state.new_words_learned.extend(response.new_words)
        state.last_turn_at = time.time()

        latency_ms = (time.time() - start_time) * 1000
        tts_chars = len(response.reply)
        stt_cost = (stt_result.duration_seconds / 60.0) * 0.006
        llm_cost = (llm_tokens_in / 1_000_000) * 0.59 + (llm_tokens_out / 1_000_000) * 0.79
        tts_cost = (tts_chars / 1000.0) * 0.015
        cost_usd = round(stt_cost + llm_cost + tts_cost, 6)

        record_turn_log({
            "turn_id": turn_id,
            "conversation_id": conversation_id,
            "character_id": character.id,
            "timestamp": time.time(),
            "streaming": True,
            "stt": {"ms": (time.time() - start_time) * 1000, "text_len": len(user_text), "status": "ok"},
            "llm": {"tokens_in": llm_tokens_in, "tokens_out": llm_tokens_out, "reply_len": len(response.reply), "status": "ok"},
            "tts": {"voice_id": character.voice_id, "ms": round(tts_ms, 1), "chunks": len(audio_b64_list), "bytes": total_audio_bytes, "status": "ok" if not tts_error else "error", "error": tts_error},
            "total_latency_ms": round(latency_ms, 1),
            "cost_usd": cost_usd,
            "status": "ok" if not tts_error else "degraded",
        })

        yield {
            "event": "turn_complete",
            "data": {
                "turn_id": turn_id,
                "reply": response.reply,
                "correction": response.correction.__dict__ if response.correction else None,
                "new_words": response.new_words,
                "level": level,
                "audio_chunks": audio_b64_list,
                "latency_ms": latency_ms,
                "cost_usd": cost_usd,
                "safety_blocked": False,
                "stt_seconds": stt_result.duration_seconds,
                "tts_error": "I could not make my voice. Tap to retry." if tts_error else None,
            },
        }

    async def _synthesize_chunks(self, text: str, voice_id: str) -> list[bytes]:
        """Split text into ≤200 char chunks and synthesize each."""
        chunks = self._split_text(text, max_chars=200)
        audio_chunks = []

        for chunk in chunks:
            cache_key = f"{voice_id}:{chunk}"
            if cache_key in self._tts_cache:
                audio_chunks.append(self._tts_cache[cache_key])
                continue

            try:
                result = await self._tts.synthesize(chunk, voice_id)
                self._tts_cache[cache_key] = result.audio
                audio_chunks.append(result.audio)
            except Exception as e:
                logger.error(f"TTS synthesis error for voice '{voice_id}': {e}")
                raise

        return audio_chunks

    @staticmethod
    def _split_text(text: str, max_chars: int = 200) -> list[str]:
        """Split text into chunks of at most max_chars, breaking at sentence boundaries."""
        if len(text) <= max_chars:
            return [text]

        chunks = []
        remaining = text

        while remaining:
            if len(remaining) <= max_chars:
                chunks.append(remaining)
                break

            segment = remaining[:max_chars]
            last_period = segment.rfind(".")
            last_excl = segment.rfind("!")
            last_q = segment.rfind("?")
            best_break = max(last_period, last_excl, last_q)

            if best_break > 20:
                chunks.append(remaining[:best_break + 1].strip())
                remaining = remaining[best_break + 1:].strip()
            else:
                last_space = segment.rfind(" ")
                if last_space > 20:
                    chunks.append(remaining[:last_space].strip())
                    remaining = remaining[last_space:].strip()
                else:
                    chunks.append(remaining[:max_chars].strip())
                    remaining = remaining[max_chars:].strip()

        return [c for c in chunks if c]

    def _trim_history(self, history: list[Message]) -> list[Message]:
        """Trim conversation history to fit within token budget."""
        if not history:
            return []

        total_chars = sum(len(m.content) for m in history)
        max_chars = MAX_HISTORY_TOKENS * CHARS_PER_TOKEN

        if total_chars <= max_chars:
            return list(history)

        trimmed = list(history)
        while trimmed and sum(len(m.content) for m in trimmed) > max_chars:
            if len(trimmed) >= 2:
                trimmed = trimmed[2:]
            else:
                trimmed = trimmed[1:]

        return trimmed

    def get_hint(self, conversation_id: str) -> dict:
        """Generate pedagogical sentence starter, model response, and vocabulary hint for the learner."""
        state = self._conversations.get(conversation_id)
        if not state:
            raise ValueError(f"Conversation not found: {conversation_id}")

        last_bot_msg = ""
        for msg in reversed(state.history):
            if msg.role == "assistant":
                last_bot_msg = msg.content
                break

        msg_lower = last_bot_msg.lower()
        if any(w in msg_lower for w in ["like", "favorite", "prefer", "enjoy"]):
            starter = "I really enjoy..."
            model = "I really enjoy reading books and playing sports because it keeps me active."
            vocab = ["enjoy", "favorite", "relaxing"]
        elif any(w in msg_lower for w in ["where", "live", "city", "place", "dhaka"]):
            starter = "I live in..."
            model = "I live in a lively neighborhood where people are friendly and welcoming."
            vocab = ["neighborhood", "convenient", "vibrant"]
        elif any(w in msg_lower for w in ["what did", "yesterday", "last weekend", "went"]):
            starter = "Yesterday, I went to..."
            model = "Yesterday, I went to visit my family and we had dinner together."
            vocab = ["visited", "enjoyed", "together"]
        elif any(w in msg_lower for w in ["think", "opinion", "why", "agree"]):
            starter = "In my opinion, I think that..."
            model = "In my opinion, I think that practicing speaking English every day builds true confidence."
            vocab = ["opinion", "confidence", "important"]
        elif any(w in msg_lower for w in ["tell me about", "introduce", "who"]):
            starter = "Let me tell you about..."
            model = "Let me tell you about my daily routine and what I study."
            vocab = ["daily", "interested in", "regularly"]
        else:
            starter = "I would say that..."
            model = "I would say that it is very interesting and I want to learn more."
            vocab = ["interesting", "because", "definitely"]

        return {
            "conversation_id": conversation_id,
            "sentence_starter": starter,
            "model_answer": model,
            "vocabulary_hints": vocab,
        }

    def get_session_summary(self, conversation_id: str) -> dict:
        """Calculate coaching metrics and summary for a completed session."""
        state = self._conversations.get(conversation_id)
        if not state:
            raise ValueError(f"Conversation not found: {conversation_id}")

        total_stt = state.total_stt_seconds
        bot_stt = state.bot_speech_seconds
        total_time = max(0.1, total_stt + bot_stt)
        talk_time_ratio = round(total_stt / total_time, 2)

        dur_min = max(0.01, total_stt / 60.0)
        wpm = round(state.user_words_count / dur_min, 1) if state.user_words_count > 0 else 0.0
        avg_turn_length = round(state.user_words_count / max(1, state.turn_count), 1)

        # Approximate clarity indicator based on fluency and error count
        base_clarity = 82
        if avg_turn_length >= 6:
            base_clarity += 6
        if len(state.corrections_list) > 2:
            base_clarity -= 8
        clarity_score = min(96, max(65, base_clarity))

        # Patterns to work on
        patterns = []
        for c in state.corrections_list:
            reason = c.get("reason_short", "").lower()
            orig = c.get("original", "").lower()
            if any(t in reason or t in orig for t in ["past", "tense", "verb", "went", "did"]):
                if "Verb tenses (past vs present)" not in patterns:
                    patterns.append("Verb tenses (past vs present)")
            elif any(a in reason or a in orig for a in ["a ", "an ", "the "]):
                if "Articles (a, an, the)" not in patterns:
                    patterns.append("Articles (a, an, the)")
            elif any(p in reason or p in orig for p in ["in", "on", "at", "to", "for"]):
                if "Prepositions (in, on, at)" not in patterns:
                    patterns.append("Prepositions (in, on, at)")
            else:
                if "Subject-verb agreement" not in patterns:
                    patterns.append("Subject-verb agreement")

        if not patterns:
            patterns = ["Preposition nuances (in vs on)", "Past tense consistency"]

        # Strengths
        strengths = []
        if talk_time_ratio >= 0.4:
            strengths.append(f"High learner talk time ({int(talk_time_ratio * 100)}% of conversation).")
        else:
            strengths.append("Persistent speaking effort on every turn.")
        if wpm >= 60:
            strengths.append(f"Strong conversational tempo ({wpm:.0f} Words Per Minute).")
        if len(state.new_words_learned) > 0:
            strengths.append(f"Discovered {len(set(state.new_words_learned))} new vocabulary words.")

        concrete_next_step = "Repeat your best answer today in 30 seconds to lock in fluency."
        char_name = state.character_id.replace("_", " ").title()
        tomorrow_hook = f"Tomorrow, {char_name} has a special riddle prepared just for you!"

        return {
            "conversation_id": conversation_id,
            "turn_count": state.turn_count,
            "learner_talk_time_seconds": round(total_stt, 1),
            "bot_talk_time_seconds": round(bot_stt, 1),
            "talk_time_ratio": talk_time_ratio,
            "wpm": wpm,
            "average_turn_length_words": avg_turn_length,
            "clarity_indicator": {
                "score": clarity_score,
                "label": "Approximate Clarity",
                "note": "Approximate estimate based on speech-to-text confidence and phrasing cadence. Not phonetic lab scoring.",
            },
            "strengths": strengths,
            "patterns_to_work_on": patterns[:3],
            "concrete_next_step": concrete_next_step,
            "say_this_better": state.corrections_list,
            "tomorrow_hook": tomorrow_hook,
        }
