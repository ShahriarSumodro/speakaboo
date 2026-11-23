"""
Groq STT Provider - Whisper Large v3 Turbo

Uses the Groq API for speech-to-text transcription.
"""

import logging
import asyncio
from typing import Optional

import httpx

from backend.providers.base import (
    SttProvider, TranscriptResult, ProviderError, RateLimitError,
)

logger = logging.getLogger("speakaboo.providers.groq_stt")

GROQ_AUDIO_URL = "https://api.groq.com/openai/v1/audio/transcriptions"
MAX_RETRIES = 3
INITIAL_BACKOFF = 1.0  # seconds


class GroqSttProvider(SttProvider):
    """Groq Whisper STT provider with retry and backoff."""

    def __init__(self, api_key: str, model: str = "whisper-large-v3-turbo"):
        if not api_key:
            raise ValueError("Groq API key is required for GroqSttProvider")
        self._api_key = api_key
        self._model = model

    async def transcribe(
        self, audio: bytes, language: str = "en", format: str = "wav"
    ) -> TranscriptResult:
        if not audio:
            raise ProviderError("Empty audio input", provider=self.name)

        # Map format to file extension
        ext_map = {"wav": "wav", "mp3": "mp3", "ogg": "ogg", "webm": "webm", "m4a": "m4a"}
        ext = ext_map.get(format, "wav")

        backoff = INITIAL_BACKOFF
        last_error: Optional[Exception] = None

        for attempt in range(MAX_RETRIES):
            try:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.post(
                        GROQ_AUDIO_URL,
                        headers={"Authorization": f"Bearer {self._api_key}"},
                        files={"file": (f"audio.{ext}", audio, f"audio/{ext}")},
                        data={
                            "model": self._model,
                            "language": language,
                            "response_format": "verbose_json",
                        },
                    )

                if response.status_code == 429:
                    retry_after = float(response.headers.get("retry-after", backoff))
                    logger.warning(
                        f"Groq STT rate limited (attempt {attempt + 1}/{MAX_RETRIES}), "
                        f"retrying in {retry_after:.1f}s"
                    )
                    if attempt < MAX_RETRIES - 1:
                        await asyncio.sleep(retry_after)
                        backoff *= 2
                        continue
                    raise RateLimitError(
                        "Groq STT rate limit exceeded after retries",
                        provider=self.name,
                        retry_after=retry_after,
                    )

                if response.status_code != 200:
                    raise ProviderError(
                        f"Groq STT error: {response.status_code} {response.text[:200]}",
                        provider=self.name,
                        status_code=response.status_code,
                    )

                data = response.json()
                return TranscriptResult(
                    text=data.get("text", "").strip(),
                    language=data.get("language", language),
                    duration_seconds=data.get("duration", 0.0),
                    confidence=1.0,  # Whisper doesn't return per-utterance confidence
                )

            except (httpx.TimeoutException, httpx.ConnectError) as e:
                last_error = e
                logger.warning(
                    f"Groq STT connection error (attempt {attempt + 1}/{MAX_RETRIES}): {e}"
                )
                if attempt < MAX_RETRIES - 1:
                    await asyncio.sleep(backoff)
                    backoff *= 2

        raise ProviderError(
            f"Groq STT failed after {MAX_RETRIES} retries: {last_error}",
            provider=self.name,
        )

    @property
    def name(self) -> str:
        return "groq_stt"
