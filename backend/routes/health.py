"""
API routes for system health, component diagnostics, and readiness probes.
"""

import time
from fastapi import APIRouter, Depends
from backend.config import load_settings
from backend.repositories import get_repository
from backend.repositories.sqlite_repo import BaseRepository

router = APIRouter(tags=["health"])

_START_TIME = time.time()


@router.get("/health")
@router.get("/api/health")
async def health_check(repo: BaseRepository = Depends(get_repository)):
    """Comprehensive health check probe for load balancers and orchestrators."""
    settings = load_settings()
    uptime_sec = round(time.time() - _START_TIME, 1)

    # Check database connectivity
    db_status = "healthy"
    db_metrics = {}
    try:
        if hasattr(repo, "_conn") and repo._conn:
            cursor = repo._conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM users")
            user_count = cursor.fetchone()[0]
            cursor.execute("SELECT COUNT(*) FROM turns")
            turn_count = cursor.fetchone()[0]
            db_metrics = {"users": user_count, "turns": turn_count}
    except Exception as e:
        db_status = f"unhealthy: {e}"

    return {
        "status": "ok" if db_status == "healthy" else "degraded",
        "service": "speakaboo",
        "version": "2.0.0",
        "environment": "test" if settings.server.test_mode else ("debug" if settings.server.debug else "production"),
        "uptime_seconds": uptime_sec,
        "database": {
            "status": db_status,
            **db_metrics,
        },
        "providers": {
            "stt": {"provider": settings.stt.provider, "model": settings.stt.model},
            "llm": {"provider": settings.llm.provider, "model": settings.llm.model},
            "tts": {"provider": settings.tts.provider, "model": settings.tts.model, "voice": settings.tts.voice},
        },
        "safety_enabled": settings.safety.enabled,
    }
