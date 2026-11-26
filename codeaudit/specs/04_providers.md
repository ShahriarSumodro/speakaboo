# Spec 04: AI Providers — STT / LLM / TTS (`backend/providers/`)

## Purpose
Adapters for Groq speech-to-text, chat completion, and text-to-speech behind abstract ABCs (`SttProvider`, `LlmProvider`, `TtsProvider`).

## Rules & Invariants
1. All three require non-empty `api_key` in `__init__` (raises `ValueError`).
2. Timeout is 30.0s on `httpx.AsyncClient`.
3. `GroqSttProvider.transcribe`: rejects empty `audio` (`ProviderError`), retries up to 3 times on 429 or timeout/connect errors with exponential backoff, returns `TranscriptResult`.
4. `GroqLlmProvider.chat`: rejects empty `messages`, tries `self._models_to_try` in order; falls back to next model on HTTP 400/404 or exhausted 429s; raises `ProviderError` if all fail.
5. `GroqTtsProvider.synthesize`: rejects empty `text`, truncates to 200 chars, validates `voice_id` against `VALID_VOICES` (falling back to `default_voice`), retries up to 3 times on 429/timeout/connect.
6. `Mock*Provider` classes exist only in `mock.py` and are gated behind `TEST_MODE` or `provider == "mock"`.
