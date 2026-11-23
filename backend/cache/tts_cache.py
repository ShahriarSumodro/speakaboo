"""
TTS Cache for Speakaboo.

Caches TTS audio for identical short phrases to reduce API calls and cost.
In-memory for now, with optional disk persistence.
"""

import hashlib
import logging
from typing import Optional
from pathlib import Path

logger = logging.getLogger("speakaboo.cache.tts")


class TtsCache:
    """In-memory TTS audio cache with optional disk backing."""

    def __init__(self, max_entries: int = 1000, cache_dir: Optional[Path] = None):
        self._cache: dict[str, bytes] = {}
        self._max_entries = max_entries
        self._cache_dir = cache_dir
        self._hits = 0
        self._misses = 0

        if cache_dir:
            cache_dir.mkdir(parents=True, exist_ok=True)

    def _make_key(self, voice_id: str, text: str) -> str:
        """Create a cache key from voice and text."""
        raw = f"{voice_id}:{text}"
        return hashlib.sha256(raw.encode()).hexdigest()[:32]

    def get(self, voice_id: str, text: str) -> Optional[bytes]:
        """Get cached audio. Returns None on miss."""
        key = self._make_key(voice_id, text)

        # Check memory
        if key in self._cache:
            self._hits += 1
            return self._cache[key]

        # Check disk
        if self._cache_dir:
            disk_path = self._cache_dir / f"{key}.wav"
            if disk_path.exists():
                try:
                    audio = disk_path.read_bytes()
                    self._cache[key] = audio  # Promote to memory
                    self._hits += 1
                    return audio
                except OSError as e:
                    logger.warning(f"Failed to read cache file {disk_path}: {e}")

        self._misses += 1
        return None

    def put(self, voice_id: str, text: str, audio: bytes) -> None:
        """Store audio in cache."""
        key = self._make_key(voice_id, text)

        # Evict if full (simple FIFO)
        if len(self._cache) >= self._max_entries:
            oldest_key = next(iter(self._cache))
            del self._cache[oldest_key]

        self._cache[key] = audio

        # Write to disk
        if self._cache_dir:
            try:
                disk_path = self._cache_dir / f"{key}.wav"
                disk_path.write_bytes(audio)
            except OSError as e:
                logger.warning(f"Failed to write cache file: {e}")

    @property
    def stats(self) -> dict:
        """Return cache hit/miss statistics."""
        total = self._hits + self._misses
        return {
            "entries": len(self._cache),
            "max_entries": self._max_entries,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": self._hits / total if total > 0 else 0.0,
        }

    def clear(self) -> None:
        """Clear all cached entries."""
        self._cache.clear()
        self._hits = 0
        self._misses = 0
