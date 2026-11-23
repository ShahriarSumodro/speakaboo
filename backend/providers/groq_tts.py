"""
Groq TTS Provider

Uses the Groq API for text-to-speech synthesis via canopylabs/orpheus-v1-english.
Valid voices: autumn, diana, hannah, austin, daniel, troy.
Enforces strict <= 200 characters per synthesized chunk.
"""

import logging
import asyncio
from typing import Optional

import httpx

from backend.providers.base import (
    TtsProvider, TtsResult, ProviderError, RateLimitError,
)

logger = logging.getLogger("speakaboo.providers.groq_tts")

GROQ_TTS_URL = "https://api.groq.com/openai/v1/audio/speech"
MAX_RETRIES = 3
INITIAL_BACKOFF = 1.0


class GroqTtsProvider(TtsProvider):
    """Groq TTS provider with retry and backoff."""

    VALID_VOICES = ("autumn", "diana", "hannah", "austin", "daniel", "troy")

    def __init__(
        self,
        api_key: str,
        model: str = "canopylabs/orpheus-v1-english",
        default_voice: str = "austin",
    ):
        if not api_key:
            raise ValueError("Groq API key is required for GroqTtsProvider")
        self._api_key = api_key
        self._model = model
        self._default_voice = default_voice

    async def synthesize(
        self, text: str, voice_id: str = "", speed: float = 1.0
    ) -> TtsResult:
        if not text:
            raise ProviderError("Empty text input", provider=self.name)

        # Enforce strict 200-char chunk limit for Orpheus
        if len(text) > 200:
            logger.warning(f"TTS text exceeds 200 chars ({len(text)}), truncating to 200 chars")
            text = text[:200]

        voice = (voice_id or self._default_voice).lower()
        if voice not in self.VALID_VOICES:
            logger.warning(f"Voice '{voice}' not in valid Orpheus voices {self.VALID_VOICES}; falling back to '{self._default_voice}'")
            voice = self._default_voice

        payload = {
            "model": self._model,
            "input": text,
            "voice": voice,
            "response_format": "wav",
            "speed": speed,
        }

        backoff = INITIAL_BACKOFF
        last_error: Optional[Exception] = None

        for attempt in range(MAX_RETRIES):
            try:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.post(
                        GROQ_TTS_URL,
                        headers={
                            "Authorization": f"Bearer {self._api_key}",
                            "Content-Type": "application/json",
                        },
                        json=payload,
                    )

                if response.status_code == 429:
                    retry_after = float(response.headers.get("retry-after", backoff))
                    logger.warning(
                        f"Groq TTS rate limited (attempt {attempt + 1}/{MAX_RETRIES}), "
                        f"retrying in {retry_after:.1f}s"
                    )
                    if attempt < MAX_RETRIES - 1:
                        await asyncio.sleep(retry_after)
                        backoff *= 2
                        continue
                    raise RateLimitError(
                        "Groq TTS rate limit exceeded after retries",
                        provider=self.name,
                        retry_after=retry_after,
                    )

                if response.status_code != 200:
                    raise ProviderError(
                        f"Groq TTS error: {response.status_code} {response.text[:200]}",
                        provider=self.name,
                        status_code=response.status_code,
                    )

                audio_bytes = response.content

                # Estimate duration from WAV data (rough: 32000 bytes/sec for 16kHz 16-bit mono)
                estimated_duration = max(0.1, len(audio_bytes) / 32000)

                return TtsResult(
                    audio=audio_bytes,
                    format="wav",
                    duration_seconds=estimated_duration,
                    characters_billed=len(text),
                )

            except (httpx.TimeoutException, httpx.ConnectError) as e:
                last_error = e
                logger.warning(
                    f"Groq TTS connection error (attempt {attempt + 1}/{MAX_RETRIES}): {e}"
                )
                if attempt < MAX_RETRIES - 1:
                    await asyncio.sleep(backoff)
                    backoff *= 2

        raise ProviderError(
            f"Groq TTS failed after {MAX_RETRIES} retries: {last_error}",
            provider=self.name,
        )

    @property
    def name(self) -> str:
        return "groq_tts"
