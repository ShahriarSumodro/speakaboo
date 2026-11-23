"""
Provider interfaces for Speakaboo AI services.

All AI providers implement these interfaces so they can be swapped via config.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional


# --- Data Types ---

@dataclass
class TranscriptResult:
    """Result from speech-to-text transcription."""
    text: str
    language: str = "en"
    duration_seconds: float = 0.0
    confidence: float = 0.0


@dataclass
class Message:
    """A chat message."""
    role: str  # "system", "user", "assistant"
    content: str


@dataclass
class LlmResult:
    """Result from LLM chat completion."""
    content: str
    tokens_in: int = 0
    tokens_out: int = 0
    model: str = ""


@dataclass
class TtsResult:
    """Result from text-to-speech synthesis."""
    audio: bytes
    format: str = "wav"  # audio format
    duration_seconds: float = 0.0
    characters_billed: int = 0


# --- Provider Interfaces ---

class SttProvider(ABC):
    """Speech-to-Text provider interface."""

    @abstractmethod
    async def transcribe(
        self, audio: bytes, language: str = "en", format: str = "wav"
    ) -> TranscriptResult:
        """Transcribe audio bytes to text.
        
        Args:
            audio: Raw audio bytes
            language: Expected language code
            format: Audio format (wav, mp3, ogg, etc.)
            
        Returns:
            TranscriptResult with transcription text and metadata
            
        Raises:
            ProviderError: On API failure
            RateLimitError: On 429 rate limiting
        """
        ...

    @property
    @abstractmethod
    def name(self) -> str:
        """Provider name for logging."""
        ...


class LlmProvider(ABC):
    """Large Language Model provider interface."""

    @abstractmethod
    async def chat(
        self,
        messages: list[Message],
        max_tokens: int = 256,
        temperature: float = 0.7,
        json_mode: bool = False,
    ) -> LlmResult:
        """Generate a chat completion.
        
        Args:
            messages: Chat history
            max_tokens: Maximum response tokens
            temperature: Sampling temperature
            json_mode: If True, force JSON output
            
        Returns:
            LlmResult with response content and usage stats
            
        Raises:
            ProviderError: On API failure
            RateLimitError: On 429 rate limiting
        """
        ...

    @property
    @abstractmethod
    def name(self) -> str:
        """Provider name for logging."""
        ...


class TtsProvider(ABC):
    """Text-to-Speech provider interface."""

    @abstractmethod
    async def synthesize(
        self, text: str, voice_id: str, speed: float = 1.0
    ) -> TtsResult:
        """Convert text to speech audio.
        
        Args:
            text: Text to synthesize (should be ≤200 characters)
            voice_id: Voice identifier
            speed: Playback speed multiplier
            
        Returns:
            TtsResult with audio bytes and metadata
            
        Raises:
            ProviderError: On API failure
            RateLimitError: On 429 rate limiting
        """
        ...

    @property
    @abstractmethod
    def name(self) -> str:
        """Provider name for logging."""
        ...


# --- Errors ---

class ProviderError(Exception):
    """Base error for provider failures."""
    def __init__(self, message: str, provider: str = "", status_code: int = 0):
        self.provider = provider
        self.status_code = status_code
        super().__init__(message)


class RateLimitError(ProviderError):
    """429 rate limit exceeded."""
    def __init__(self, message: str = "Rate limit exceeded", provider: str = "", retry_after: float = 0):
        self.retry_after = retry_after
        super().__init__(message, provider=provider, status_code=429)


class SafetyError(Exception):
    """Content failed safety check."""
    def __init__(self, message: str = "Content blocked by safety filter", category: str = ""):
        self.category = category
        super().__init__(message)
