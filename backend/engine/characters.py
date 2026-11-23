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
    practice_mode: str = "accuracy",  # "accuracy" or "fluency"
    coach_mode: str = "balanced",    # "gentle", "balanced", "strict"
    age_band: str = "teen",          # "kid", "teen", "adult"
) -> str:
    """Build the pedagogical system prompt for a companion.
    
    Adheres to Master English speaking coach principles:
    - Maximize learner talk time (bot replies stay brief, prompt learner to speak)
    - Natural recasts (bot embeds correct forms inside conversational reply)
    - Single most important error correction in accuracy mode
    - Low anxiety, positive praise, zero shame
    - Common difficulty hypotheses for Bengali speakers: articles, tenses, prepositions, agreement
    - Age-appropriate tone and sentence complexity
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

    # Age band instructions
    if age_band == "kid":
        parts.append("""
AGE ADJUSTMENT - CHILD LEARNER (6-12 years):
- Keep language simple, cheerful, and highly encouraging.
- Limit replies to 1 short sentence (max 120 characters).
- Celebrate imagination and effort. Never use academic grammatical terms.
""")
    elif age_band == "adult":
        parts.append("""
AGE ADJUSTMENT - ADULT LEARNER (18+ years):
- Respectful, practical, and goal-oriented conversation.
- Focus on professional and daily communication confidence.
""")

    # Practice mode instructions (Fluency vs Accuracy)
    if practice_mode == "fluency":
        parts.append("""
PEDAGOGY - FLUENCY MODE:
- Do NOT interrupt the learner's conversational flow with explicit correction.
- Set "correction": null in your JSON.
- Recast any error naturally inside your reply (e.g., if user says 'I goes home', reply: 'You went home? What did you do there?').
- Maximize learner talk time: end with an open question.
""")
    else:
        # Accuracy mode
        parts.append(f"""
PEDAGOGY - ACCURACY MODE ({coach_mode.upper()}):
- If the learner makes grammatical errors, pick at most ONE high-priority error (e.g. tense, subject-verb agreement, prepositions, articles).
- Recast the other errors naturally in your dialogue.
- Provide friendly, constructive guidance in "correction".
- Tone: Encourage confidence, never shame.
""")

    # Feedback style
    feedback = feedback_style_override or character.feedback_style
    if feedback:
        parts.append(f"\nFeedback approach: {feedback}")

    # Core rules
    parts.append("""
RULES (always follow):
1. Reply in 1-2 SHORT sentences only. Max 200 characters total.
2. Maximize learner talk time: always end with a gentle question or prompt for the learner to reply.
3. If the user made a grammar or vocabulary mistake, correct AT MOST ONE mistake per reply in accuracy mode. In fluency mode, set correction to null.
4. Use your character personality in every reply.
5. Never break character.
6. Never discuss violence, sexual content, self-harm, drugs, or ask for personal information.
7. If the user says something inappropriate, redirect kindly to English practice.
8. Celebrate good attempts. Build speaking confidence.

OUTPUT FORMAT: You MUST respond with valid JSON only, no other text:
{
  "version": 1,
  "reply": "Your character's spoken reply (max 200 chars, 1-2 sentences)",
  "correction": {"original": "what they said wrong", "better": "improved version", "reason_short": "brief why"} or null,
  "new_words": ["any", "new", "vocabulary", "you", "used"] or [],
  "feedback_level": "gentle",
  "detailed_feedback": null
}
""")

    return "\n".join(parts)
