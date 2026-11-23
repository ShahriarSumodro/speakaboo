"""
Speakaboo Backend - FastAPI Application Entry Point
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.config import load_settings
from backend.routes import health, auth, characters, conversation, usage

# Load settings
settings = load_settings()

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.server.log_level.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("speakaboo")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: startup and shutdown."""
    logger.info("Speakaboo backend starting up")
    logger.info(f"STT provider: {settings.stt.provider} ({settings.stt.model})")
    logger.info(f"LLM provider: {settings.llm.provider} ({settings.llm.model})")
    logger.info(f"TTS provider: {settings.tts.provider} ({settings.tts.model})")
    logger.info(f"Database: {settings.database.url}")
    logger.info(f"Safety enabled: {settings.safety.enabled}")
    logger.info(f"Feature flags: constructive_criticism_mode={settings.features.constructive_criticism_mode}")
    yield
    logger.info("Speakaboo backend shutting down")


app = FastAPI(
    title="Speakaboo API",
    description="English Speaking Companion API for kids, students, and university learners in Bangladesh",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log every request with timing."""
    start = time.time()
    response = await call_next(request)
    duration_ms = (time.time() - start) * 1000
    logger.info(
        f"{request.method} {request.url.path} → {response.status_code} ({duration_ms:.0f}ms)"
    )
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all exception handler. Never leak internal errors to client."""
    logger.error(f"Unhandled error on {request.method} {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_error",
            "message": "Something went wrong. Please try again.",
        },
    )


# --- Register Routes ---
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(characters.router)
app.include_router(conversation.router)
app.include_router(usage.router)
