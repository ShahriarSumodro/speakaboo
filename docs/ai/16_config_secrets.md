# Spec 16: Config & Secrets (`backend/config.py`, `.env.example`)

## Purpose
Centralizes environment configuration into frozen dataclasses (`Settings`) and enforces production safety checks.

## Rules & Invariants
1. `load_settings()` loads `.env` (root or `backend/.env`) without overwriting existing `os.environ` keys.
2. `validate_providers(settings)`:
   - Bypassed when `TEST_MODE=true`.
   - In normal mode, refuses startup (`RuntimeError`) if any provider is `"mock"`, if `GROQ_API_KEY` is missing when Groq is configured, or if `tts.voice` is not in `valid_voices`.
3. `.env.example` documents all config keys with placeholder values; no real secrets are committed.
