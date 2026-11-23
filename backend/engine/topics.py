"""
Topic mode engine for Speakaboo.

Loads discussion topics with neutral, educational, kid-safe framing.
"""

import json
import logging
from pathlib import Path
from typing import List, Optional, Dict, Any

logger = logging.getLogger("speakaboo.engine.topics")

TOPICS_FILE = Path(__file__).parent.parent / "data" / "topics.json"


class TopicEngine:
    """Manages conversational topic packs."""

    def __init__(self, topics_path: Optional[Path] = None):
        self.path = topics_path or TOPICS_FILE
        self._topics: List[Dict[str, Any]] = []
        self._load()

    def _load(self) -> None:
        if not self.path.exists():
            logger.warning(f"Topics file not found: {self.path}")
            return
        with open(self.path, "r", encoding="utf-8") as f:
            self._topics = json.load(f)

    def list_topics(self) -> List[Dict[str, Any]]:
        """Return all topics."""
        return self._topics

    def get_topic(self, topic_id: str) -> Optional[Dict[str, Any]]:
        """Get topic by ID."""
        for t in self._topics:
            if t["id"] == topic_id:
                return t
        return None
