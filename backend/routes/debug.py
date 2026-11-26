"""
Speakaboo Debug & Diagnostics Routes

Provides observability endpoints for turn-by-turn tracing and diagnostic logging.
Only accessible when server is configured with DEBUG=true.
"""

import base64
import io
import logging
import math
import struct
import time
import wave
from fastapi import APIRouter, Depends, HTTPException
from backend.config import load_settings
from backend.engine.auth_token import get_current_user_id
from backend.engine.conversation import get_last_turns
from backend.engine.correction import parse_turn_response
from backend.providers.base import Message, ProviderError
from backend.routes.conversation import get_engine

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


def _build_probe_wav() -> bytes:
    """Create a 0.6s 16kHz PCM WAV for provider connectivity diagnostics."""
    rate = 16000
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        frames = bytearray()
        for i in range(int(rate * 0.6)):
            val = int(5000 * math.sin(2 * math.pi * 240 * (i / rate)))
            frames += struct.pack("<h", val)
        wf.writeframes(bytes(frames))
    return buf.getvalue()


@router.post("/diagnostics/stt")
async def diagnostics_stt(current_user_id: str = Depends(get_current_user_id)):
    """Run a live Speech-to-Text diagnostic probe against the configured provider."""
    settings = load_settings()
    engine = get_engine()
    t0 = time.time()
    try:
        res = await engine._stt.transcribe(_build_probe_wav(), language="en", format="wav")
        ms = round((time.time() - t0) * 1000, 1)
        return {
            "ok": True,
            "ms": ms,
            "provider": getattr(engine._stt, "name", settings.stt.provider),
            "model": settings.stt.model,
            "detail": f"transcript='{res.text}'",
            "error": None,
        }
    except Exception as e:
        ms = round((time.time() - t0) * 1000, 1)
        status_code = getattr(e, "status_code", 500)
        logger.error(f"Diagnostics STT failed ({status_code}, {ms}ms): {e}")
        return {
            "ok": False,
            "status_code": status_code,
            "ms": ms,
            "provider": getattr(engine._stt, "name", settings.stt.provider),
            "model": settings.stt.model,
            "detail": None,
            "error": str(e),
        }


@router.post("/diagnostics/llm")
async def diagnostics_llm(current_user_id: str = Depends(get_current_user_id)):
    """Run a live LLM diagnostic probe using Speakaboo's JSON turn format."""
    settings = load_settings()
    engine = get_engine()
    t0 = time.time()
    msgs = [
        Message(
            role="system",
            content='Reply in valid JSON only: {"version":1,"reply":"Hello! Let us practice English.","correction":null,"new_words":[]}',
        ),
        Message(role="user", content="Hi, I want to practice speaking English."),
    ]
    try:
        res = await engine._llm.chat(messages=msgs, max_tokens=settings.llm.max_tokens, json_mode=True)
        parsed = parse_turn_response(res.content)
        ms = round((time.time() - t0) * 1000, 1)
        return {
            "ok": True,
            "ms": ms,
            "provider": getattr(engine._llm, "name", settings.llm.provider),
            "model": res.model or settings.llm.model,
            "detail": f"reply='{parsed.reply[:60]}' ({res.tokens_in}+{res.tokens_out} tok)",
            "error": None,
        }
    except Exception as e:
        ms = round((time.time() - t0) * 1000, 1)
        status_code = getattr(e, "status_code", 500)
        logger.error(f"Diagnostics LLM failed ({status_code}, {ms}ms): {e}")
        return {
            "ok": False,
            "status_code": status_code,
            "ms": ms,
            "provider": getattr(engine._llm, "name", settings.llm.provider),
            "model": settings.llm.model,
            "detail": None,
            "error": str(e),
        }


@router.post("/diagnostics/tts")
async def diagnostics_tts(current_user_id: str = Depends(get_current_user_id)):
    """Run a live TTS diagnostic probe against the configured voice provider."""
    settings = load_settings()
    engine = get_engine()
    t0 = time.time()
    sample_text = "Hello! Your Speakaboo voice is ready."
    try:
        res = await engine._tts.synthesize(sample_text, settings.tts.voice)
        ms = round((time.time() - t0) * 1000, 1)
        return {
            "ok": True,
            "audio_unavailable": False,
            "ms": ms,
            "provider": getattr(engine._tts, "name", settings.tts.provider),
            "model": settings.tts.model,
            "voice": settings.tts.voice,
            "bytes": len(res.audio),
            "audio_base64": base64.b64encode(res.audio).decode(),
            "text": sample_text,
            "error": None,
        }
    except Exception as e:
        ms = round((time.time() - t0) * 1000, 1)
        status_code = getattr(e, "status_code", 500)
        logger.error(f"Diagnostics TTS failed ({status_code}, {ms}ms): {e}")
        return {
            "ok": False,
            "audio_unavailable": True,
            "status_code": status_code,
            "ms": ms,
            "provider": getattr(engine._tts, "name", settings.tts.provider),
            "model": settings.tts.model,
            "voice": settings.tts.voice,
            "bytes": 0,
            "audio_base64": None,
            "text": sample_text,
            "error": str(e),
        }
