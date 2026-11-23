"""
Mock providers for testing and offline development.

These return deterministic responses and never make network calls.
"""

import json
import struct
import math
from typing import Optional

from backend.providers.base import (
    SttProvider, LlmProvider, TtsProvider,
    TranscriptResult, Message, LlmResult, TtsResult,
    ProviderError,
)


class MockSttProvider(SttProvider):
    """Mock STT that returns a fixed transcript."""

    def __init__(self, default_text: str = "Hello, how are you today?"):
        self._default_text = default_text
        self._next_text: Optional[str] = None

    def set_next_response(self, text: str) -> None:
        """Set the text to return on the next transcribe call."""
        self._next_text = text

    async def transcribe(
        self, audio: bytes, language: str = "en", format: str = "wav"
    ) -> TranscriptResult:
        if not audio:
            raise ProviderError("Empty audio input", provider=self.name)

        text = self._next_text if self._next_text is not None else self._default_text
        self._next_text = None

        # Estimate duration from audio size (rough: 16kHz, 16-bit mono = 32KB/s)
        estimated_duration = max(0.1, len(audio) / 32000)

        return TranscriptResult(
            text=text,
            language=language,
            duration_seconds=estimated_duration,
            confidence=0.95,
        )

    @property
    def name(self) -> str:
        return "mock_stt"


class MockLlmProvider(LlmProvider):
    """Mock LLM that returns a canned character response in the correction JSON format."""

    def __init__(self):
        self._next_response: Optional[str] = None

    def set_next_response(self, response: str) -> None:
        """Set the raw response string for the next chat call."""
        self._next_response = response

    async def chat(
        self,
        messages: list[Message],
        max_tokens: int = 256,
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> LlmResult:
        if not messages:
            raise ProviderError("No messages provided", provider=self.name)

        if self._next_response is not None:
            content = self._next_response
            self._next_response = None
        elif json_mode:
            # Return a valid correction JSON response
            content = json.dumps({
                "version": 1,
                "reply": "That is very good! Keep practicing every day.",
                "correction": None,
                "new_words": [],
                "feedback_level": "gentle",
                "detailed_feedback": None,
            })
        else:
            content = "That is very good! Keep practicing every day."

        # Estimate tokens (rough: 1 token ≈ 4 chars)
        tokens_in = sum(len(m.content) // 4 + 1 for m in messages)
        tokens_out = len(content) // 4 + 1

        return LlmResult(
            content=content,
            tokens_in=tokens_in,
            tokens_out=tokens_out,
            model="mock-model",
        )

    @property
    def name(self) -> str:
        return "mock_llm"


class MockTtsProvider(TtsProvider):
    """Mock TTS that returns a short silent WAV file."""

    async def synthesize(
        self, text: str, voice_id: str, speed: float = 1.0
    ) -> TtsResult:
        if not text:
            raise ProviderError("Empty text input", provider=self.name)

        # Generate a minimal valid WAV file (0.1s of silence at 16kHz, 16-bit mono)
        sample_rate = 16000
        duration = 0.1
        num_samples = int(sample_rate * duration)
        
        # WAV header
        data_size = num_samples * 2  # 16-bit = 2 bytes per sample
        wav = bytearray()
        wav.extend(b'RIFF')
        wav.extend(struct.pack('<I', 36 + data_size))
        wav.extend(b'WAVE')
        wav.extend(b'fmt ')
        wav.extend(struct.pack('<I', 16))  # chunk size
        wav.extend(struct.pack('<H', 1))   # PCM format
        wav.extend(struct.pack('<H', 1))   # mono
        wav.extend(struct.pack('<I', sample_rate))
        wav.extend(struct.pack('<I', sample_rate * 2))  # byte rate
        wav.extend(struct.pack('<H', 2))   # block align
        wav.extend(struct.pack('<H', 16))  # bits per sample
        wav.extend(b'data')
        wav.extend(struct.pack('<I', data_size))
        wav.extend(b'\x00' * data_size)  # silence

        return TtsResult(
            audio=bytes(wav),
            format="wav",
            duration_seconds=duration,
            characters_billed=len(text),
        )

    @property
    def name(self) -> str:
        return "mock_tts"
