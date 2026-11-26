"""
Speakaboo Debug & Diagnostics Routes

Provides observability endpoints for turn-by-turn tracing and diagnostic logging.
Only accessible when server is configured with DEBUG=true.
"""

import logging
from fastapi import APIRouter, HTTPException
from backend.config import load_settings
from backend.engine.conversation import get_last_turns

logger = logging.getLogger("speakaboo.routes.debug")
router = APIRouter(prefix="/api/debug", tags=["debug"])


@router.get("/last_turns")
async def get_debug_last_turns():
    """Return the last 20 turn diagnostic records.
    
    Only available when DEBUG=true.
    """
    settings = load_settings()
    if not settings.server.debug:
        logger.warning("Attempted access to /api/debug/last_turns while DEBUG is disabled")
        raise HTTPException(
            status_code=403,
            detail="Debug endpoint disabled. Set DEBUG=true in .env to enable.",
        )

    turns = get_last_turns()
    return {
        "status": "ok",
        "count": len(turns),
        "turns": turns,
    }


@router.get("/last_requests")
async def get_debug_last_requests():
    """Return the last 30 HTTP request diagnostic records (only when DEBUG=true)."""
    settings = load_settings()
    if not settings.server.debug:
        logger.warning("Attempted access to /api/debug/last_requests while DEBUG is disabled")
        raise HTTPException(
            status_code=403,
            detail="Debug endpoint disabled. Set DEBUG=true in .env to enable.",
        )

    from backend.main import get_last_requests

    requests = get_last_requests()
    return {
        "status": "ok",
        "count": len(requests),
        "requests": requests,
    }
