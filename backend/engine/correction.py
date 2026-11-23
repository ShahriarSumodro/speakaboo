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

    # Optional correction
    correction = None
    corr_data = data.get("correction")
    if corr_data and isinstance(corr_data, dict):
        original = corr_data.get("original", "")
        better = corr_data.get("better", "")
        reason = corr_data.get("reason_short", "")
        if original and better:
            correction = Correction(
                original=original,
                better=better,
                reason_short=reason,
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
