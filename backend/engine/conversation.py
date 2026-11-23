"""
Conversation engine for Speakaboo.

Manages one conversation turn: audio in → transcript → safety → LLM → TTS → audio out.
Maintains rolling history with a token budget and supports both synchronous and SSE streaming turns.
"""

import logging
import time
import uuid
import base64
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
        self, character_id: str, user_id: str, conversation_id: Optional[str] = None
    ) -> ConversationState:
        """Start a new conversation or return an existing one."""
        cid = conversation_id or str(uuid.uuid4())
        if cid in self._conversations:
            return self._conversations[cid]

        state = ConversationState(
            id=cid,
            character_id=character_id,
            user_id=user_id,
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

        # --- Step 1: STT ---
        stt_result = await self._stt.transcribe(audio, format=audio_format)
        user_text = stt_result.text.strip()

        if not user_text:
            return TurnResult(
                conversation_id=conversation_id,
                turn_id=turn_id,
                user_transcript="",
                response=TurnResponse(reply="I didn't catch that. Could you try again?"),
                audio_chunks=[],
                level="beginner",
                stt_seconds=stt_result.duration_seconds,
                latency_ms=(time.time() - start_time) * 1000,
            )

        logger.info(f"STT: {user_text[:80]}... ({stt_result.duration_seconds:.1f}s audio)")

        # --- Step 2: Safety check on user message ---
        blocked_category = check_content_safety(user_text, is_user_message=True)
        if blocked_category:
            redirect = get_redirect_message(blocked_category)
            redirect_audio = await self._synthesize_chunks(redirect, character.voice_id)
            return TurnResult(
                conversation_id=conversation_id,
                turn_id=turn_id,
                user_transcript=user_text,
                response=TurnResponse(reply=redirect),
                audio_chunks=redirect_audio,
                level=estimate_level(state.user_transcripts),
                stt_seconds=stt_result.duration_seconds,
                latency_ms=(time.time() - start_time) * 1000,
                safety_blocked=True,
                safety_redirect=redirect,
            )

        # --- Step 3: Estimate learner level ---
        state.user_transcripts.append(user_text)
        level = estimate_level(state.user_transcripts)

        # --- Step 4: Build messages for LLM ---
        system_prompt = build_system_prompt(character, level)
        messages = [Message(role="system", content=system_prompt)]
        messages.extend(self._trim_history(state.history))
        messages.append(Message(role="user", content=user_text))

        # --- Step 5: LLM call with JSON parsing and retry ---
        response: Optional[TurnResponse] = None
        llm_tokens_in = 0
        llm_tokens_out = 0

        for attempt in range(max_llm_retries):
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
                logger.warning(f"LLM JSON parse failed (attempt {attempt + 1}): {e}")
                if attempt < max_llm_retries - 1:
                    messages.append(Message(role="assistant", content=llm_result.content))
                    messages.append(Message(role="user", content="Please respond with VALID JSON only, following the exact format specified."))

        if response is None:
            logger.error("All LLM JSON parse attempts failed, using fallback")
            response = TurnResponse(reply="Good try! Let's keep practicing.")

        # --- Step 6: Safety check on AI reply ---
        try:
            check_content_safety(response.reply, is_user_message=False)
        except SafetyError:
            logger.error("AI reply blocked by safety filter, using fallback")
            response = TurnResponse(reply="Let's keep practicing! What else would you like to talk about?")

        # --- Step 7: TTS ---
        audio_chunks = await self._synthesize_chunks(response.reply, character.voice_id)
        tts_chars = len(response.reply)

        # --- Step 8: Update conversation state ---
        state.history.append(Message(role="user", content=user_text))
        state.history.append(Message(role="assistant", content=response.reply))
        state.turn_count += 1
        state.total_stt_seconds += stt_result.duration_seconds
        state.last_turn_at = time.time()

        latency_ms = (time.time() - start_time) * 1000

        # Cost tracking (USD)
        stt_cost = (stt_result.duration_seconds / 60.0) * 0.006
        llm_cost = (llm_tokens_in / 1_000_000) * 0.59 + (llm_tokens_out / 1_000_000) * 0.79
        tts_cost = (tts_chars / 1000.0) * 0.015
        cost_usd = round(stt_cost + llm_cost + tts_cost, 6)

        logger.info(
            f"Turn complete: {latency_ms:.0f}ms, "
            f"STT={stt_result.duration_seconds:.1f}s, "
            f"LLM={llm_tokens_in}+{llm_tokens_out} tokens, "
            f"TTS={tts_chars} chars, "
            f"Cost=${cost_usd:.5f}, "
            f"level={level}"
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
        blocked_category = check_content_safety(user_text, is_user_message=True)
        if blocked_category:
            redirect = get_redirect_message(blocked_category)
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

        system_prompt = build_system_prompt(character, level)
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

        for idx, chunk in enumerate(chunks):
            cache_key = f"{character.voice_id}:{chunk}"
            if cache_key in self._tts_cache:
                audio_bytes = self._tts_cache[cache_key]
            else:
                synth_res = await self._tts.synthesize(chunk, character.voice_id)
                audio_bytes = synth_res.audio
                self._tts_cache[cache_key] = audio_bytes

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

        # 6. Update State
        state.history.append(Message(role="user", content=user_text))
        state.history.append(Message(role="assistant", content=response.reply))
        state.turn_count += 1
        state.total_stt_seconds += stt_result.duration_seconds
        state.last_turn_at = time.time()

        latency_ms = (time.time() - start_time) * 1000
        tts_chars = len(response.reply)
        stt_cost = (stt_result.duration_seconds / 60.0) * 0.006
        llm_cost = (llm_tokens_in / 1_000_000) * 0.59 + (llm_tokens_out / 1_000_000) * 0.79
        tts_cost = (tts_chars / 1000.0) * 0.015
        cost_usd = round(stt_cost + llm_cost + tts_cost, 6)

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

            result = await self._tts.synthesize(chunk, voice_id)
            self._tts_cache[cache_key] = result.audio
            audio_chunks.append(result.audio)

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
