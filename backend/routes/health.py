"""
API routes for health and auth.
"""

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "speakaboo",
        "version": "0.1.0",
    }
