"""
Learner level adaptation for Speakaboo.

Infers beginner/intermediate/advanced from recent conversation turns
and adjusts vocabulary in replies accordingly.
"""

import logging
import re
from typing import Optional

logger = logging.getLogger("speakaboo.engine.level")

# Level thresholds based on average word complexity of recent user messages
LEVELS = ("beginner", "intermediate", "advanced")

# Simple word lists for complexity estimation
# Words appearing in basic English education (approximate A1-A2 level)
BASIC_WORDS_SAMPLE = {
    "i", "you", "he", "she", "it", "we", "they", "am", "is", "are", "was", "were",
    "have", "has", "had", "do", "does", "did", "will", "would", "can", "could",
    "the", "a", "an", "this", "that", "my", "your", "his", "her", "our", "their",
    "and", "but", "or", "not", "no", "yes", "hello", "hi", "bye", "good", "bad",
    "big", "small", "new", "old", "first", "last", "long", "short", "great",
    "little", "just", "like", "want", "need", "know", "think", "go", "come",
    "make", "take", "see", "look", "find", "give", "tell", "say", "get", "eat",
    "drink", "play", "work", "help", "name", "day", "time", "year", "way",
    "food", "water", "school", "home", "family", "friend", "book", "happy",
    "thank", "please", "sorry", "today", "tomorrow", "yesterday",
}


def estimate_level(recent_transcripts: list[str], window: int = 5) -> str:
    """Estimate learner level from recent user transcripts.
    
    Uses simple heuristics:
    - Average sentence length
    - Ratio of basic vs. complex words
    - Average word length
    
    Args:
        recent_transcripts: List of recent user message texts (newest last)
        window: Number of recent messages to consider
        
    Returns:
        "beginner", "intermediate", or "advanced"
    """
    if not recent_transcripts:
        return "beginner"

    # Use the last N transcripts
    texts = recent_transcripts[-window:]

    # Collect all words
    all_words = []
    sentence_count = 0
    for text in texts:
        words = _extract_words(text)
        all_words.extend(words)
        # Rough sentence count
        sentence_count += max(1, text.count(".") + text.count("!") + text.count("?"))

    if not all_words:
        return "beginner"

    # Metrics
    avg_word_length = sum(len(w) for w in all_words) / len(all_words)
    words_per_sentence = len(all_words) / max(1, sentence_count)
    basic_ratio = sum(1 for w in all_words if w in BASIC_WORDS_SAMPLE) / len(all_words)
    unique_ratio = len(set(all_words)) / len(all_words)

    # Scoring (simple weighted sum)
    score = 0.0

    # Long words suggest higher level
    if avg_word_length > 5.5:
        score += 2
    elif avg_word_length > 4.0:
        score += 1

    # More words per sentence suggests higher level
    if words_per_sentence > 12:
        score += 2
    elif words_per_sentence > 7:
        score += 1

    # Lower basic ratio = more advanced vocabulary
    if basic_ratio < 0.3:
        score += 2
    elif basic_ratio < 0.5:
        score += 1

    # Higher unique word ratio suggests richer vocabulary
    # But only meaningful with enough words (>10), otherwise short sentences
    # always look unique
    if len(all_words) > 10:
        if unique_ratio > 0.8:
            score += 1
        elif unique_ratio > 0.6:
            score += 0.5

    # Penalty for very short input (few words total = likely beginner)
    if len(all_words) < 5:
        score -= 1
    elif len(all_words) < 10:
        score -= 0.5

    # Map score to level
    if score >= 4:
        return "advanced"
    elif score >= 2:
        return "intermediate"
    else:
        return "beginner"


def _extract_words(text: str) -> list[str]:
    """Extract lowercase words from text."""
    return [w.lower() for w in re.findall(r"[a-zA-Z']+", text) if len(w) > 0]
