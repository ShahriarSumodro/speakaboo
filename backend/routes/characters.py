"""
Character routes for Speakaboo.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from backend.engine.characters import list_characters, load_character

router = APIRouter(prefix="/api/characters", tags=["characters"])


class CharacterResponse(BaseModel):
    id: str
    name: str
    description: str
    voice_id: str
    greeting: str
    locked: bool
    price_bdt: int
    tags: list[str]


@router.get("/", response_model=list[CharacterResponse])
async def get_characters():
    """List all available characters."""
    characters = list_characters()
    return [
        CharacterResponse(
            id=c.id,
            name=c.name,
            description=c.description,
            voice_id=c.voice_id,
            greeting=c.greeting,
            locked=c.locked,
            price_bdt=c.price_bdt,
            tags=c.tags,
        )
        for c in characters
    ]


@router.get("/{character_id}", response_model=CharacterResponse)
async def get_character(character_id: str):
    """Get a specific character by ID."""
    try:
        c = load_character(character_id)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Character not found: {character_id}")
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))

    return CharacterResponse(
        id=c.id,
        name=c.name,
        description=c.description,
        voice_id=c.voice_id,
        greeting=c.greeting,
        locked=c.locked,
        price_bdt=c.price_bdt,
        tags=c.tags,
    )
