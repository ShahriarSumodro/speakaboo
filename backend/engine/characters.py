"""
Character system for Speakaboo.

Characters are loaded from JSON data files. No code changes needed to add new characters.
"""

import json
import logging
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger("speakaboo.engine.characters")

CHARACTERS_DIR = Path(__file__).parent.parent / "characters"


@dataclass
class Character:
    """A Speakaboo character loaded from JSON."""
    id: str
    name: str
    description: str
    persona_prompt: str
    speaking_style: str
    voice_id: str
    difficulty_tones: dict[str, str]
    greeting: str
    tagline: str = ""
    personality_traits: list[str] = field(default_factory=list)
    sample_lines: list[str] = field(default_factory=list)
    best_for: str = ""
    locked: bool = False
    price_bdt: int = 0
    feedback_style: str = ""
    tags: list[str] = field(default_factory=list)


def load_character(character_id: str) -> Character:
    """Load a single character from its JSON file.
    
    Raises:
        FileNotFoundError: If the character file doesn't exist
        ValueError: If the JSON is invalid
    """
    path = CHARACTERS_DIR / f"{character_id}.json"
    if not path.exists():
        raise FileNotFoundError(f"Character not found: {character_id}")

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid character JSON for {character_id}: {e}")

    return Character(
        id=data["id"],
        name=data["name"],
        description=data.get("description", ""),
        persona_prompt=data["persona_prompt"],
        speaking_style=data.get("speaking_style", ""),
        voice_id=data.get("voice_id", ""),
        difficulty_tones=data.get("difficulty_tones", {}),
        greeting=data.get("greeting", "Hello! Let's practice English!"),
        tagline=data.get("tagline", data.get("description", "")),
        personality_traits=data.get("personality_traits", []),
        sample_lines=data.get("sample_lines", []),
        best_for=data.get("best_for", ""),
        locked=data.get("locked", False),
        price_bdt=data.get("price_bdt", 0),
        feedback_style=data.get("feedback_style", ""),
        tags=data.get("tags", []),
    )


def list_characters() -> list[Character]:
    """Load all characters from the characters directory."""
    characters = []
    if not CHARACTERS_DIR.exists():
        logger.warning(f"Characters directory not found: {CHARACTERS_DIR}")
        return characters

    for path in sorted(CHARACTERS_DIR.glob("*.json")):
        try:
            characters.append(load_character(path.stem))
        except (FileNotFoundError, ValueError, KeyError) as e:
            logger.error(f"Failed to load character {path.stem}: {e}")

    return characters


def build_system_prompt(
    character: Character,
    level: str = "beginner",
    feedback_style_override: Optional[str] = None,
) -> str:
    """Build the full system prompt for a character at a given learner level.
    
    This is extensible for future feedback modes (Phase 8).
    
    Args:
        character: The character to build a prompt for
        level: Learner level (beginner/intermediate/advanced)
        feedback_style_override: Optional override for feedback style (Phase 8 hook)
    
    Returns:
        Complete system prompt string
    """
    parts = [
        character.persona_prompt,
        "",
        f"Speaking style: {character.speaking_style}",
    ]

    # Add difficulty tone
    tone = character.difficulty_tones.get(level, character.difficulty_tones.get("beginner", ""))
    if tone:
        parts.append(f"\nLevel adjustment: {tone}")

    # Feedback style (extensible for Phase 8: Constructive Criticism Mode)
    feedback = feedback_style_override or character.feedback_style
    if feedback:
        parts.append(f"\nFeedback approach: {feedback}")

    # Core rules (always applied)
    parts.append("""
RULES (always follow):
1. Reply in 1-2 SHORT sentences only. Max 200 characters total.
2. If the user made a grammar or vocabulary mistake, correct AT MOST ONE mistake per reply, gently.
3. Use your character personality in every reply.
4. Never break character.
5. Never discuss violence, sexual content, self-harm, drugs, or ask for personal information.
6. If the user says something inappropriate, redirect kindly to English practice.
7. Celebrate good attempts. Build speaking confidence.

OUTPUT FORMAT: You MUST respond with valid JSON only, no other text:
{
  "version": 1,
  "reply": "Your character's spoken reply (max 200 chars, 1-2 sentences)",
  "correction": {"original": "what they said wrong", "better": "improved version", "reason_short": "brief why"} or null if no correction,
  "new_words": ["any", "new", "vocabulary", "you", "used"] or [],
  "feedback_level": "gentle",
  "detailed_feedback": null
}
""")

    return "\n".join(parts)
