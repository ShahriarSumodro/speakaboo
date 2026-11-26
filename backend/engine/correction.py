"""
Correction engine for Speakaboo.

Validates and repairs the JSON correction output from the LLM.
Schema is versioned and extensible for Phase 8 (Constructive Criticism Mode).
"""

import json
import logging
import re
from dataclasses import dataclass, field
from typing import Optional, Any

logger = logging.getLogger("speakaboo.engine.correction")


@dataclass
class Correction:
    """A single correction from the AI."""
    original: str
    better: str
    reason_short: str
    category: str = ""

    def __post_init__(self):
        if not self.category and self.original and self.better:
            self.category = categorize_error(self.original, self.better, self.reason_short)


PEDAGOGICAL_ERROR_PRIORITY = {
    "tenses_and_verbs": 1,
    "subject_verb_agreement": 2,
    "prepositions": 3,
    "articles": 4,
    "word_choice": 5,
}


def categorize_error(original: str, better: str, reason: str = "") -> str:
    """Categorize grammar mistakes into core Bengali learner difficulty areas.
    
    Pedagogical priority order:
    1. Tenses and verbs (communicative breakdown)
    2. Subject-verb agreement (comprehensibility)
    3. Prepositions
    4. Articles
    5. General word choice
    """
    orig_l = original.lower()
    better_l = better.lower()
    reason_l = reason.lower()
    if any(s in reason_l for s in ["agreement", "subject-verb"]):
        return "subject_verb_agreement"
    if any(k in reason_l for k in ["tense", "past", "went", "did", "was", "were"]) or (
        "verb" in reason_l and "subject-verb" not in reason_l
    ):
        return "tenses_and_verbs"
    if any(s in reason_l for s in ["plural", "singular"]):
        return "subject_verb_agreement"
    if "preposition" in reason_l:
        return "prepositions"
    if "article" in reason_l:
        return "articles"

    orig_words = set(re.findall(r"\b\w+\b", orig_l))
    better_words = set(re.findall(r"\b\w+\b", better_l)) if better_l else set()
    changed_words = orig_words ^ better_words if better_words else orig_words

    if changed_words & {"in", "on", "at", "to", "for", "with", "by", "from"}:
        return "prepositions"
    if changed_words & {"a", "an", "the"}:
        return "articles"
    return "word_choice"


@dataclass
class TurnResponse:
    """Parsed and validated turn response from the LLM."""
    version: int = 1
    reply: str = ""
    correction: Optional[Correction] = None
    new_words: list[str] = field(default_factory=list)
    feedback_level: str = "gentle"
    detailed_feedback: Optional[dict] = None  # Phase 8 hook

    def to_dict(self) -> dict:
        return {
            "version": self.version,
            "reply": self.reply,
            "correction": {
                "original": self.correction.original,
                "better": self.correction.better,
                "reason_short": self.correction.reason_short,
                "category": self.correction.category,
            } if self.correction else None,
            "new_words": self.new_words,
            "feedback_level": self.feedback_level,
            "detailed_feedback": self.detailed_feedback,
        }


def parse_turn_response(raw: str) -> TurnResponse:
    """Parse and validate the LLM's JSON response.
    
    Attempts repair if the JSON is slightly malformed.
    
    Args:
        raw: Raw string from the LLM (should be JSON)
        
    Returns:
        Validated TurnResponse
        
    Raises:
        ValueError: If JSON cannot be parsed or repaired
    """
    # Try to extract JSON from the response (LLM might wrap it in markdown)
    json_str = _extract_json(raw)

    try:
        data = json.loads(json_str)
    except json.JSONDecodeError as e:
        # Attempt basic repairs
        repaired = _repair_json(json_str)
        try:
            data = json.loads(repaired)
            logger.info("Repaired malformed JSON from LLM")
        except json.JSONDecodeError:
            raise ValueError(f"Cannot parse LLM response as JSON: {e}. Raw: {raw[:200]}")

    return _validate_and_build(data)


def _extract_json(raw: str) -> str:
    """Extract JSON object from raw string, handling markdown code blocks."""
    raw = raw.strip()

    # Remove markdown code blocks
    if raw.startswith("```"):
        lines = raw.split("\n")
        # Remove first and last lines if they're code fences
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        raw = "\n".join(lines).strip()

    # Find first { and last }
    start = raw.find("{")
    end = raw.rfind("}")
    if start != -1 and end != -1 and end > start:
        return raw[start:end + 1]

    return raw


def _repair_json(json_str: str) -> str:
    """Attempt basic JSON repairs."""
    s = json_str

    # Fix trailing commas before } or ]
    s = re.sub(r",\s*([}\]])", r"\1", s)

    # Fix single quotes to double quotes (crude but handles simple cases)
    # Only if there are no double quotes at all
    if '"' not in s and "'" in s:
        s = s.replace("'", '"')

    # Fix missing quotes around keys
    s = re.sub(r'(\{|,)\s*(\w+)\s*:', r'\1"\2":', s)

    return s


def _validate_and_build(data: Any) -> TurnResponse:
    """Validate parsed JSON data and build a TurnResponse."""
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object, got {type(data).__name__}")

    # Required field: reply
    reply = data.get("reply", "")
    if not reply:
        raise ValueError("Missing 'reply' field in LLM response")

    # Enforce max length on reply
    if len(reply) > 200:
        logger.warning(f"Reply too long ({len(reply)} chars), truncating to 200")
        # Truncate at last sentence boundary within 200 chars
        truncated = reply[:200]
        last_period = truncated.rfind(".")
        last_excl = truncated.rfind("!")
        last_q = truncated.rfind("?")
        last_end = max(last_period, last_excl, last_q)
        if last_end > 50:
            reply = truncated[:last_end + 1]
        else:
            reply = truncated

    # Optional correction (Enforce CD-001 single focus error guard)
    correction = None
    corr_data = data.get("correction")
    if corr_data is None and "corrections" in data:
        corr_data = data.get("corrections")

    if isinstance(corr_data, list) and len(corr_data) > 0:
        candidates = []
        for item in corr_data:
            if isinstance(item, dict) and item.get("original") and item.get("better"):
                cat = item.get("category") or categorize_error(
                    item["original"], item["better"], item.get("reason_short", "")
                )
                prio = PEDAGOGICAL_ERROR_PRIORITY.get(cat, 99)
                candidates.append((prio, item, cat))
        if candidates:
            # Sort by pedagogical priority: tenses_and_verbs (1) > agreement (2) > prep (3) > articles (4)
            candidates.sort(key=lambda x: x[0])
            best_prio, best_item, best_cat = candidates[0]
            correction = Correction(
                original=best_item.get("original", ""),
                better=best_item.get("better", ""),
                reason_short=best_item.get("reason_short", ""),
                category=best_cat,
            )
    elif isinstance(corr_data, dict):
        original = corr_data.get("original", "")
        better = corr_data.get("better", "")
        reason = corr_data.get("reason_short", "")
        cat = corr_data.get("category", "")
        if original and better:
            correction = Correction(
                original=original,
                better=better,
                reason_short=reason,
                category=cat,
            )

    # New words
    new_words = data.get("new_words", [])
    if not isinstance(new_words, list):
        new_words = []
    new_words = [str(w) for w in new_words if w]

    # Feedback level (Phase 8 extensibility)
    feedback_level = data.get("feedback_level", "gentle")
    if feedback_level not in ("gentle", "balanced", "strict"):
        feedback_level = "gentle"

    # Detailed feedback (Phase 8 — currently always null)
    detailed_feedback = data.get("detailed_feedback")

    return TurnResponse(
        version=data.get("version", 1),
        reply=reply,
        correction=correction,
        new_words=new_words,
        feedback_level=feedback_level,
        detailed_feedback=detailed_feedback,
    )
