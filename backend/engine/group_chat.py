"""
Multi-character group chat engine for Speakaboo.

Enables a cast of 2 or more characters to participate in a conversation with
the learner (e.g. Farmer Reggie and Detective Kabir interacting together).

Per Hard Rule 4 & 5:
- Max 2 sentences per character turn.
- Strictly safe and gentle correction.
- Kept behind the `multi_character_group_chat` feature flag.
"""

from dataclasses import dataclass, field
import time
from typing import List, Optional, Dict, Any

from backend.config import load_settings
from backend.engine.characters import Character, load_character
from backend.engine.safety import check_content_safety, get_redirect_message
from backend.providers.base import LlmProvider, TtsProvider, Message


class FeatureDisabledError(Exception):
    """Raised when group chat is requested but feature flag is off."""
    pass


@dataclass
class GroupTurnSpeakerOutput:
    """Spoken output from one character in a group turn."""
    character_id: str
    character_name: str
    reply: str
    audio_chunks: List[bytes] = field(default_factory=list)
    correction: Optional[Dict[str, str]] = None


@dataclass
class GroupChatTurnResult:
    """Result of one group conversation turn."""
    turn_id: str
    user_transcript: str
    speakers_output: List[GroupTurnSpeakerOutput]
    level: str
    timestamp: float = field(default_factory=time.time)


@dataclass
class GroupChatSession:
    """Active multi-character conversation session."""
    session_id: str
    user_id: str
    characters: List[Character]
    history: List[Dict[str, Any]] = field(default_factory=list)
    created_at: float = field(default_factory=time.time)


class GroupChatEngine:
    """
    Coordinates multi-character dialogue between the learner and multiple companion personas.
    """

    def __init__(
        self,
        llm: LlmProvider,
        tts: TtsProvider,
    ):
        self.llm = llm
        self.tts = tts

    def _ensure_feature_enabled(self) -> None:
        settings = load_settings()
        if not settings.features.multi_character_group_chat:
            raise FeatureDisabledError(
                "Multi-character group chat is currently disabled by feature flag. "
                "Set MULTI_CHARACTER_GROUP_CHAT=true to enable."
            )

    async def create_session(
        self,
        session_id: str,
        user_id: str,
        character_ids: List[str],
    ) -> GroupChatSession:
        """Create a new multi-character group conversation."""
        self._ensure_feature_enabled()

        if len(character_ids) < 2:
            raise ValueError("Group chat requires at least 2 characters.")

        loaded_chars = [load_character(cid) for cid in character_ids]
        return GroupChatSession(
            session_id=session_id,
            user_id=user_id,
            characters=loaded_chars,
        )

    async def process_turn(
        self,
        session: GroupChatSession,
        user_text: str,
        learner_level: str = "beginner",
    ) -> GroupChatTurnResult:
        """
        Process a user turn where characters take turns speaking.
        First character responds directly to the user;
        Second character chimes in or playfully agrees/disagrees.
        """
        self._ensure_feature_enabled()

        # Kid safety validation on user text
        blocked_category = check_content_safety(user_text, is_user_message=True)
        if blocked_category:
            redirect = get_redirect_message(blocked_category)
            # If unsafe, first character responds with gentle redirection
            first_char = session.characters[0]
            tts_res = await self.tts.synthesize(redirect, voice_id=first_char.voice_id)
            return GroupChatTurnResult(
                turn_id=f"gturn-{int(time.time() * 1000)}",
                user_transcript=user_text,
                speakers_output=[
                    GroupTurnSpeakerOutput(
                        character_id=first_char.id,
                        character_name=first_char.name,
                        reply=redirect,
                        audio_chunks=[tts_res.audio],
                    )
                ],
                level=learner_level,
            )

        speakers_output: List[GroupTurnSpeakerOutput] = []

        # 1. Primary character response
        primary_char = session.characters[0]
        prompt1 = (
            f"You are {primary_char.name}. Persona: {primary_char.persona_prompt}. "
            f"Speaking style: {primary_char.speaking_style}. "
            f"The learner ({learner_level}) said: '{user_text}'. "
            f"Reply in character. Keep it short: MAX 2 SENTENCES, UNDER 180 CHARACTERS."
        )
        llm1 = await self.llm.chat([Message(role="user", content=prompt1)])
        reply1 = llm1.content.strip()
        tts1 = await self.tts.synthesize(reply1, voice_id=primary_char.voice_id)

        speakers_output.append(
            GroupTurnSpeakerOutput(
                character_id=primary_char.id,
                character_name=primary_char.name,
                reply=reply1,
                audio_chunks=[tts1.audio],
            )
        )

        # 2. Secondary character commentary
        secondary_char = session.characters[1]
        prompt2 = (
            f"You are {secondary_char.name}. Persona: {secondary_char.persona_prompt}. "
            f"Speaking style: {secondary_char.speaking_style}. "
            f"{primary_char.name} just said: '{reply1}' to the learner. "
            f"Chime in briefly to the learner or {primary_char.name}. "
            f"MAX 2 SENTENCES, UNDER 180 CHARACTERS."
        )
        llm2 = await self.llm.chat([Message(role="user", content=prompt2)])
        reply2 = llm2.content.strip()
        tts2 = await self.tts.synthesize(reply2, voice_id=secondary_char.voice_id)

        speakers_output.append(
            GroupTurnSpeakerOutput(
                character_id=secondary_char.id,
                character_name=secondary_char.name,
                reply=reply2,
                audio_chunks=[tts2.audio],
            )
        )

        # Append to session history
        session.history.append({"role": "user", "text": user_text})
        for out in speakers_output:
            session.history.append(
                {"role": "assistant", "character": out.character_id, "text": out.reply}
            )

        return GroupChatTurnResult(
            turn_id=f"gturn-{int(time.time() * 1000)}",
            user_transcript=user_text,
            speakers_output=speakers_output,
            level=learner_level,
        )
