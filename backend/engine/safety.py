"""
Safety layer for Speakaboo.

Checks both user messages and AI replies for unsafe content.
Implements Hard Rule 6: blocklist + content filtering.
"""

import logging
import re
from typing import Optional

from backend.providers.base import SafetyError

logger = logging.getLogger("speakaboo.engine.safety")

# Blocklist categories with patterns
# These are checked against both user input and AI output
BLOCKED_PATTERNS: dict[str, list[str]] = {
    "self_harm": [
        r"\b(suicide|self.?harm|cut myself|kill myself|end my life|want to die)\b",
    ],
    "violence": [
        r"\b(kill|murder|shoot|stab|attack|bomb|weapons?|guns?|knife|fight|hurt|beat up|punch)\b",
    ],
    "sexual": [
        r"\b(sex|porn|nude|naked|nsfw|xxx|erotic|orgasm|genital)\b",
    ],
    "drugs": [
        r"\b(cocaine|heroin|meth|marijuana|weed|drug dealer|get high|smoke weed)\b",
    ],
    "personal_info_request": [
        r"\b(what is your (address|phone|school|home)|where do you live|tell me your number)\b",
        r"\b(give me your (address|phone|email|school))\b",
    ],
}

# Safe redirect messages (General)
REDIRECT_MESSAGES: dict[str, str] = {
    "violence": "Let's keep our conversation friendly! How about we practice talking about something fun instead?",
    "sexual": "That topic isn't for our practice sessions. Let's talk about something else! What did you do today?",
    "self_harm": "I care about you. If you're feeling down, please talk to a trusted adult. For now, let's practice some English together!",
    "drugs": "Let's skip that topic. How about we practice talking about your favorite hobby instead?",
    "personal_info_request": "I don't need personal details! Let's keep practicing English. What's your favorite food?",
    "inappropriate_language": "Let's use kind words while we practice speaking English! What would you like to talk about?",
}

# Companion persona-voiced redirect replies
CHARACTER_REDIRECT_MESSAGES: dict[str, dict[str, str]] = {
    "rule_farmer": {
        "violence": "Whoa there, partner! Out here on the farm we keep things friendly and peaceful. How about we practice talking about the harvest instead?",
        "sexual": "That's not something we talk about around the barn! Let's practice talking about your favorite animals or outdoor games.",
        "self_harm": "I care about you, partner. If you're feeling down, please talk to a trusted adult. Reggie is right here to practice friendly English with you!",
        "drugs": "We don't need any of that talk on the farm! How about we practice talking about fresh crops and cooking?",
        "personal_info_request": "A good farmer never asks for personal secrets! Let's keep our practice safe. What's your favorite farm animal?",
        "inappropriate_language": "Easy now, friend! Out here in the fields we stick to kind and respectful words. What would you like to describe today?",
    },
    "kabir_chowdhury": {
        "violence": "Hold on, fellow detective! A real investigator relies on intellect and observation, not violence. Let's redirect our deductive minds to a real mystery!",
        "sexual": "That topic has no place in our investigation files. Let's refocus our inquiry! What mystery shall we solve in Dhaka today?",
        "self_harm": "Every detective faces tough cases, but you don't have to carry them alone. Please speak with a trusted adult or mentor. I'm right here when you're ready to explore.",
        "drugs": "That trail is strictly off-limits for our detective work. Let's investigate something fascinating instead, like archaeology or astronomy!",
        "personal_info_request": "Rule number one of detective work: protect your privacy! Never share your home address or private numbers. Now, back to our investigation!",
        "inappropriate_language": "A skilled detective chooses words with precision and respect. Let's maintain our professional inquiry. What clue shall we analyze next?",
    },
    "professor_anika": {
        "violence": "Let us maintain an academic, constructive environment. Shall we redirect our discussion toward an engaging topic in history or science?",
        "sexual": "That subject is not appropriate for our seminar. Let us explore an interesting scientific innovation or English idiom instead.",
        "self_harm": "Your well-being is of paramount importance. Please reach out to a trusted mentor or family member. Professor Anika is right here when you feel ready to resume our language study session.",
        "drugs": "That is not a constructive topic for our study session. Let's examine a vocabulary challenge or discuss geography instead.",
        "personal_info_request": "In academic research, participant privacy is essential! We never collect your personal details. What is an educational subject you love studying?",
        "inappropriate_language": "Scholarly discourse flourishes with courteous and constructive language. Let's express our thoughts thoughtfully. What idea shall we discuss?",
    },
}


def check_content_safety(
    text: str, is_user_message: bool = True, age_band: str = "kid"
) -> Optional[str]:
    """Check text for unsafe content.
    
    Args:
        text: The text to check
        is_user_message: True if checking user input, False if checking AI output
        age_band: 'kid', 'teen', or 'adult' — applies stricter language filtering for children.
        
    Returns:
        None if safe, or a safety category string if blocked
        
    Raises:
        SafetyError: If the content is blocked (for AI output — we don't want unsafe AI replies)
    """
    if not text:
        return None

    text_lower = text.lower()

    # Kid-specific extra guard: block bullying and inappropriate language
    if age_band == "kid" and is_user_message:
        kid_inappropriate_pattern = r"\b(damn|hell|crap|stupid|idiot|shut up|dumb|i hate you)\b"
        if re.search(kid_inappropriate_pattern, text_lower):
            logger.warning(f"Safety: Kid inappropriate language flagged: {text[:50]}...")
            return "inappropriate_language"

    for category, patterns in BLOCKED_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, text_lower):
                logger.warning(
                    f"Safety: {'User' if is_user_message else 'AI'} content blocked "
                    f"(category={category}): {text[:50]}..."
                )
                if not is_user_message:
                    # AI generated unsafe content — this is a hard error
                    raise SafetyError(
                        f"AI response blocked by safety filter",
                        category=category,
                    )
                return category

    return None


def get_redirect_message(category: str, character_id: Optional[str] = None) -> str:
    """Get a friendly redirect message, styled in the specific character's voice when provided."""
    if character_id and character_id in CHARACTER_REDIRECT_MESSAGES:
        char_redirects = CHARACTER_REDIRECT_MESSAGES[character_id]
        if category in char_redirects:
            return char_redirects[category]

    return REDIRECT_MESSAGES.get(
        category,
        "Let's talk about something else! What would you like to practice?",
    )


def sanitize_for_child(text: str) -> str:
    """Light sanitization of text for child-friendly display.
    
    Removes obvious profanity but doesn't block the whole message.
    """
    # Simple profanity filter (not comprehensive — the category check above is the main guard)
    mild_profanity = [
        r"\b(damn|hell|crap|stupid|idiot|shut up|dumb)\b",
    ]
    result = text
    for pattern in mild_profanity:
        result = re.sub(pattern, "***", result, flags=re.IGNORECASE)
    return result
