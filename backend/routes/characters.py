"""
Character routes for Speakaboo.

Single source of truth for character companions: list, detail, personality traits,
sample lines, pricing, and audio voice preview generation.
"""

from typing import Optional
from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel

from backend.engine.characters import list_characters, load_character
from backend.config import load_settings
from backend.providers.groq_tts import GroqTtsProvider
from backend.providers.mock import MockTtsProvider

router = APIRouter(prefix="/api/characters", tags=["characters"])

# In-memory cache for character voice previews
_preview_cache: dict[str, bytes] = {}


class CharacterResponse(BaseModel):
    id: str
    name: str
    tagline: str
    description: str
    speaking_style: str
    personality_traits: list[str]
    sample_lines: list[str]
    best_for: str
    voice_id: str
    greeting: str
    locked: bool
    price_bdt: int
    tags: list[str]
    preview_audio_url: str


def _to_response(c) -> CharacterResponse:
    return CharacterResponse(
        id=c.id,
        name=c.name,
        tagline=c.tagline or c.description,
        description=c.description,
        speaking_style=c.speaking_style,
        personality_traits=c.personality_traits,
        sample_lines=c.sample_lines,
        best_for=c.best_for,
        voice_id=c.voice_id,
        greeting=c.greeting,
        locked=c.locked,
        price_bdt=c.price_bdt,
        tags=c.tags,
        preview_audio_url=f"/api/characters/{c.id}/preview-audio",
    )


@router.get("/", response_model=list[CharacterResponse])
async def get_characters():
    """List all available characters as the single source of truth."""
    characters = list_characters()
    return [_to_response(c) for c in characters]


@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(character_id: str):
    """Get character details by ID."""
    try:
        c = load_character(character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Character not found: {character_id}")
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))

    return _to_response(c)


@router.get("/{character_id}/preview-audio")
async def get_character_preview_audio(character_id: str):
    """Generate or retrieve cached preview voice audio for this character."""
    try:
        c = load_character(character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Character not found: {character_id}")

    if character_id in _preview_cache:
        return Response(content=_preview_cache[character_id], media_type="audio/wav")

    settings = load_settings()
    if settings.tts.provider == "groq" and settings.tts.api_key:
        tts = GroqTtsProvider(
            api_key=settings.tts.api_key,
            model=settings.tts.model,
            default_voice=c.voice_id or settings.tts.voice,
        )
    else:
        tts = MockTtsProvider()

    try:
        # Synthesize character's initial greeting
        res = await tts.synthesize(text=c.greeting, voice_id=c.voice_id)
        _preview_cache[character_id] = res.audio
        return Response(content=res.audio, media_type="audio/wav")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate voice preview: {e}")
