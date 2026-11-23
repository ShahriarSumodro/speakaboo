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

# Safe redirect messages
REDIRECT_MESSAGES: dict[str, str] = {
    "violence": "Let's keep our conversation friendly! How about we practice talking about something fun instead?",
    "sexual": "That topic isn't for our practice sessions. Let's talk about something else! What did you do today?",
    "self_harm": "I care about you. If you're feeling down, please talk to a trusted adult. For now, let's practice some English together!",
    "drugs": "Let's skip that topic. How about we practice talking about your favorite hobby instead?",
    "personal_info_request": "I don't need personal details! Let's keep practicing English. What's your favorite food?",
}


def check_content_safety(text: str, is_user_message: bool = True) -> Optional[str]:
    """Check text for unsafe content.
    
    Args:
        text: The text to check
        is_user_message: True if checking user input, False if checking AI output
        
    Returns:
        None if safe, or a safety category string if blocked
        
    Raises:
        SafetyError: If the content is blocked (for AI output — we don't want unsafe AI replies)
    """
    if not text:
        return None

    text_lower = text.lower()

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


def get_redirect_message(category: str) -> str:
    """Get a friendly redirect message for a blocked category."""
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
