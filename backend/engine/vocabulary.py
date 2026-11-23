"""
Vocabulary Notebook Engine with Spaced Repetition (Leitner System).

Tracks words learned and corrected phrases, scheduling reviews over expanding intervals:
Box 1: 1 day
Box 2: 3 days
Box 3: 7 days
Box 4: 14 days
Box 5: 30 days
"""

import logging
from typing import List, Optional, Dict, Any
from backend.repositories.sqlite_repo import BaseRepository, dhaka_today
from backend.models.learning import VocabularyItem

logger = logging.getLogger("speakaboo.engine.vocabulary")


class VocabularyEngine:
    """Manages vocabulary items and spaced review schedules."""

    def __init__(self, repo: BaseRepository):
        self.repo = repo

    async def add_word(
        self,
        user_id: str,
        word_or_phrase: str,
        context_sentence: str = "",
        correction_notes: str = "",
    ) -> VocabularyItem:
        """Add a newly learned word or corrected phrase to the notebook."""
        clean_word = word_or_phrase.strip().lower()

        # Check if already in user's notebook
        existing = await self.repo.get_vocabulary(user_id, limit=200)
        for item in existing:
            if item.word_or_phrase.lower() == clean_word:
                # Word already tracked, return existing
                return item

        item = VocabularyItem(
            user_id=user_id,
            word_or_phrase=clean_word,
            context_sentence=context_sentence,
            correction_notes=correction_notes,
            box=1,
        )
        return await self.repo.add_vocabulary(item)

    async def add_from_turn(
        self,
        user_id: str,
        new_words: List[str],
        correction: Optional[Dict[str, str]] = None,
        context_sentence: str = "",
    ) -> List[VocabularyItem]:
        """Auto-capture new words and corrections from a conversation turn."""
        added = []
        # 1. Capture new words
        for w in new_words:
            if w and len(w.strip()) > 1:
                item = await self.add_word(
                    user_id=user_id,
                    word_or_phrase=w.strip(),
                    context_sentence=context_sentence,
                )
                added.append(item)

        # 2. Capture correction if present
        if correction and correction.get("better"):
            notes = correction.get("reason_short", "")
            phrase = f"{correction.get('original', '')} → {correction.get('better', '')}"
            item = await self.add_word(
                user_id=user_id,
                word_or_phrase=phrase,
                context_sentence=context_sentence,
                correction_notes=notes,
            )
            added.append(item)

        return added

    async def get_notebook(self, user_id: str) -> List[VocabularyItem]:
        """Get all words in user's vocabulary notebook."""
        return await self.repo.get_vocabulary(user_id)

    async def get_due_words(
        self, user_id: str, date: Optional[str] = None
    ) -> List[VocabularyItem]:
        """Get words due for review today (in Asia/Dhaka)."""
        return await self.repo.get_due_vocabulary(user_id, date)

    async def review_word(
        self, item_id: str, remembered: bool
    ) -> Optional[VocabularyItem]:
        """Record review outcome. Moves up a box if remembered, resets to Box 1 if forgotten."""
        return await self.repo.review_vocabulary(item_id, remembered)
