"""
Speakaboo Backend Configuration

Loads settings from .env file. All config is centralized here.
"""

import os
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional


def _env(key: str, default: str = "") -> str:
    return os.environ.get(key, default)


def _env_bool(key: str, default: bool = False) -> bool:
    return os.environ.get(key, str(default)).lower() in ("true", "1", "yes")


def _env_int(key: str, default: int = 0) -> int:
    try:
        return int(os.environ.get(key, str(default)))
    except (ValueError, TypeError):
        return default


def _env_float(key: str, default: float = 0.0) -> float:
    try:
        return float(os.environ.get(key, str(default)))
    except (ValueError, TypeError):
        return default


@dataclass(frozen=True)
class ServerConfig:
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False
    log_level: str = "info"
    test_mode: bool = False


@dataclass(frozen=True)
class SttConfig:
    provider: str = "groq"
    model: str = "whisper-large-v3-turbo"
    api_key: str = ""


@dataclass(frozen=True)
class LlmConfig:
    provider: str = "groq"
    model: str = "openai/gpt-oss-120b"
    fallback_models: tuple[str, ...] = (
        "openai/gpt-oss-120b",
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant",
    )
    api_key: str = ""
    max_tokens: int = 256
    temperature: float = 0.7


@dataclass(frozen=True)
class TtsConfig:
    provider: str = "groq"
    model: str = "canopylabs/orpheus-v1-english"
    voice: str = "austin"
    valid_voices: tuple[str, ...] = ("autumn", "diana", "hannah", "austin", "daniel", "troy")
    api_key: str = ""


@dataclass(frozen=True)
class SafetyConfig:
    enabled: bool = True


@dataclass(frozen=True)
class UsageConfig:
    free_daily_minutes: int = 10
    basic_daily_minutes: int = 30
    premium_daily_minutes: int = 120


@dataclass(frozen=True)
class DatabaseConfig:
    url: str = "sqlite:///./speakaboo.db"


@dataclass(frozen=True)
class PaymentConfig:
    provider: str = "sandbox"
    sandbox_mode: bool = True
    bkash_app_key: str = ""
    nagad_merchant_id: str = ""
    monthly_plan_price_bdt: int = 200
    character_unlock_price_bdt: int = 350


@dataclass(frozen=True)
class FeatureFlags:
    constructive_criticism_mode: bool = False
    multi_character_group_chat: bool = False


@dataclass(frozen=True)
class Settings:
    server: ServerConfig = field(default_factory=ServerConfig)
    stt: SttConfig = field(default_factory=SttConfig)
    llm: LlmConfig = field(default_factory=LlmConfig)
    tts: TtsConfig = field(default_factory=TtsConfig)
    safety: SafetyConfig = field(default_factory=SafetyConfig)
    usage: UsageConfig = field(default_factory=UsageConfig)
    database: DatabaseConfig = field(default_factory=DatabaseConfig)
    payment: PaymentConfig = field(default_factory=PaymentConfig)
    features: FeatureFlags = field(default_factory=FeatureFlags)


def validate_providers(settings: Settings) -> None:
    """Validate provider configuration.
    
    In normal mode, mock providers and missing API keys are strictly forbidden.
    In test mode (TEST_MODE=true or --test), mock providers are permitted for unit tests.
    """
    if settings.server.test_mode:
        return

    # Check for mock providers
    mock_providers = []
    if settings.stt.provider == "mock":
        mock_providers.append("STT")
    if settings.llm.provider == "mock":
        mock_providers.append("LLM")
    if settings.tts.provider == "mock":
        mock_providers.append("TTS")

    if mock_providers:
        raise RuntimeError(
            f"Speakaboo refused to start: Mock providers ({', '.join(mock_providers)}) "
            f"are prohibited in normal mode. Configure real providers with GROQ_API_KEY in .env, "
            f"or set TEST_MODE=true for automated tests."
        )

    # Check for required Groq API key when groq provider is configured
    if any(p == "groq" for p in (settings.stt.provider, settings.llm.provider, settings.tts.provider)):
        if not settings.stt.api_key and not settings.llm.api_key and not settings.tts.api_key:
            raise RuntimeError(
                "Speakaboo refused to start: GROQ_API_KEY is missing. "
                "Provide a valid GROQ_API_KEY in .env, or set TEST_MODE=true for automated tests."
            )

    # Check TTS voice validity
    if settings.tts.provider == "groq":
        if settings.tts.voice not in settings.tts.valid_voices:
            raise RuntimeError(
                f"Invalid Groq TTS voice '{settings.tts.voice}'. "
                f"Valid voices for {settings.tts.model} are: {', '.join(settings.tts.valid_voices)}"
            )


def load_settings() -> Settings:
    """Load settings from environment variables (populated from .env)."""
    # Try to load .env file from root or backend directory
    for candidate in [
        Path(__file__).parent.parent / ".env",
        Path(__file__).parent / ".env",
    ]:
        if candidate.exists():
            _load_dotenv(candidate)
            break

    groq_key = _env("GROQ_API_KEY", "")

    # Parse fallback models
    fallback_str = _env("LLM_FALLBACK_MODELS", "")
    if fallback_str:
        fallback_models = tuple(m.strip() for m in fallback_str.split(",") if m.strip())
    else:
        fallback_models = (
            "openai/gpt-oss-120b",
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant",
        )

    return Settings(
        server=ServerConfig(
            host=_env("HOST", "0.0.0.0"),
            port=_env_int("PORT", 8000),
            debug=_env_bool("DEBUG", False),
            log_level=_env("LOG_LEVEL", "info"),
            test_mode=_env_bool("TEST_MODE", False),
        ),
        stt=SttConfig(
            provider=_env("STT_PROVIDER", "groq"),
            model=_env("STT_MODEL", "whisper-large-v3-turbo"),
            api_key=groq_key,
        ),
        llm=LlmConfig(
            provider=_env("LLM_PROVIDER", "groq"),
            model=_env("LLM_MODEL", "openai/gpt-oss-120b"),
            fallback_models=fallback_models,
            api_key=groq_key,
            max_tokens=_env_int("LLM_MAX_TOKENS", 256),
            temperature=_env_float("LLM_TEMPERATURE", 0.7),
        ),
        tts=TtsConfig(
            provider=_env("TTS_PROVIDER", "groq"),
            model=_env("TTS_MODEL", "canopylabs/orpheus-v1-english"),
            voice=_env("TTS_VOICE", "austin"),
            api_key=groq_key,
        ),
        safety=SafetyConfig(
            enabled=_env_bool("SAFETY_ENABLED", True),
        ),
        usage=UsageConfig(
            free_daily_minutes=_env_int("FREE_DAILY_MINUTES", 10),
            basic_daily_minutes=_env_int("BASIC_DAILY_MINUTES", 30),
            premium_daily_minutes=_env_int("PREMIUM_DAILY_MINUTES", 120),
        ),
        database=DatabaseConfig(
            url=_env("DATABASE_URL", "sqlite:///./speakaboo.db"),
        ),
        payment=PaymentConfig(
            provider=_env("PAYMENT_PROVIDER", "sandbox"),
            sandbox_mode=_env_bool("PAYMENT_SANDBOX_MODE", True),
            bkash_app_key=_env("BKASH_APP_KEY", ""),
            nagad_merchant_id=_env("NAGAD_MERCHANT_ID", ""),
            monthly_plan_price_bdt=_env_int("MONTHLY_PLAN_PRICE_BDT", 200),
            character_unlock_price_bdt=_env_int("CHARACTER_UNLOCK_PRICE_BDT", 350),
        ),
        features=FeatureFlags(
            constructive_criticism_mode=_env_bool("CONSTRUCTIVE_CRITICISM_MODE", False),
            multi_character_group_chat=_env_bool("MULTI_CHARACTER_GROUP_CHAT", False),
        ),
    )


def _load_dotenv(path: Path) -> None:
    """Minimal .env loader. No external dependency needed."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" not in line:
                    continue
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip()
                # Remove surrounding quotes if present
                if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
                    value = value[1:-1]
                if key and key not in os.environ:
                    os.environ[key] = value
    except OSError:
        pass
