"""
Speakaboo Backend - FastAPI Application Entry Point

Implements tight CORS, request size enforcement, rate limiting, and structured logging.
"""

import logging
import time
from collections import defaultdict
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.config import load_settings, validate_providers
from backend.routes import health, auth, characters, conversation, usage, learning, parent, payment, privacy, debug
from backend.engine.telemetry import telemetry

# Load settings
settings = load_settings()

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.server.log_level.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("speakaboo")

# In-memory sliding window rate limiter: {ip: [timestamps]}
_rate_limits: dict[str, list[float]] = defaultdict(list)
MAX_REQUESTS_PER_MINUTE = 120
MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10 MB maximum upload


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: startup and shutdown."""
    logger.info("Speakaboo backend starting up")
    # Strict startup validation: enforce real providers and valid keys/models in normal mode
    validate_providers(settings)
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
    version="0.2.0",
    lifespan=lifespan,
)

# Allowed CORS origins
allowed_origins = [
    "http://localhost:8000",
    "http://localhost:3000",
    "http://127.0.0.1:8000",
    "http://10.0.2.2:8000",
]
if settings.server.debug or settings.server.test_mode:
    allowed_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


@app.middleware("http")
async def security_and_rate_limit_middleware(request: Request, call_next):
    """Enforce request size limits and client rate limiting."""
    # 1. Request size limit
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > MAX_CONTENT_LENGTH:
        return JSONResponse(
            status_code=413,
            content={
                "error": "payload_too_large",
                "message": f"Upload exceeds maximum allowable limit of {MAX_CONTENT_LENGTH // (1024 * 1024)}MB.",
            },
        )

    # 2. Rate limiting (bypassed in test mode)
    if not settings.server.test_mode:
        client_ip = request.client.host if request.client else "unknown"
        now = time.time()
        window_start = now - 60.0

        # Clean timestamps older than 60s
        timestamps = [t for t in _rate_limits[client_ip] if t > window_start]
        if len(timestamps) >= MAX_REQUESTS_PER_MINUTE:
            return JSONResponse(
                status_code=429,
                content={
                    "error": "rate_limit_exceeded",
                    "message": "Too many requests. Please wait a moment before trying again.",
                },
                headers={"Retry-After": "10"},
            )
        timestamps.append(now)
        _rate_limits[client_ip] = timestamps

    # 3. Log request timing
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
    import traceback
    tb = traceback.format_exc()
    logger.error(f"Unhandled error on {request.method} {request.url.path}: {exc}\n{tb}")
    telemetry.record_crash(
        error_type=type(exc).__name__,
        message=str(exc),
        stack_trace=tb,
        endpoint=f"{request.method} {request.url.path}",
    )
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
app.include_router(learning.router)
app.include_router(parent.router)
app.include_router(payment.router)
app.include_router(privacy.router)
app.include_router(debug.router)
