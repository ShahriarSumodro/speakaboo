# Speakaboo Provider Probe Results

Executed `backend/scripts/probe_providers.py` directly against `https://api.groq.com/openai/v1` using `GROQ_API_KEY` from `.env` (HTTP 30s timeout, no app abstractions).

## 1. Key Validity & Model List (`GET /models`)
- **Status:** `200 OK` (344.0 ms) — Key is VALID.
- **Available Models (11 total):**
  `allam-2-7b`, `canopylabs/orpheus-arabic-saudi`, `canopylabs/orpheus-v1-english`, `meta-llama/llama-prompt-guard-2-22m`, `meta-llama/llama-prompt-guard-2-86m`, `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `openai/gpt-oss-safeguard-20b`, `qwen/qwen3.8-27b`, `whisper-large-v3`, `whisper-large-v3-turbo`.

## 2. Speech-to-Text (`POST /audio/transcriptions`)
- **Configured Model:** `whisper-large-v3-turbo`
- **Status:** `200 OK` (292.3 ms)
- **Rate Limits:** `x-ratelimit-limit-requests=2000`, `remaining=1999`, `reset=43.2s`
- **Verdict:** **WORKS**.

## 3. AI Reply (`POST /chat/completions`)
| Model | Prompt Mode | Status | Latency | Rate Limit Headers | Result / Exact Error |
|-------|-------------|--------|---------|--------------------|----------------------|
| `openai/gpt-oss-120b` (configured) | plain | `200` | 612.9 ms | `1000 req/day`, `8000 TPM` | OK (`85+64 tok`) |
| `openai/gpt-oss-120b` (configured) | json | `200` | 572.0 ms | `8000 TPM` | OK (`135+154 tok`) |
| `openai/gpt-oss-120b` (configured) | **speakaboo_prompt** | **`400`** | 963.2 ms | `8000 TPM` | `code="json_validate_failed"`, `failed_generation=""` (reasoning exhausts `max_tokens=256`) |
| `openai/gpt-oss-20b` | plain | `200` | 523.1 ms | `8000 TPM` | OK (`85+66 tok`) |
| `openai/gpt-oss-20b` | json / speakaboo_prompt | **`400`** | 703–823 ms | `8000 TPM` | `code="json_validate_failed"`, `"max completion tokens reached before generating a valid document"` |
| `llama-3.3-70b-versatile` (fallback 2) | all | **`404`** | 86–117 ms | none | `code="model_not_found"` (not in key's 11 models) |
| `llama-3.1-8b-instant` (fallback 3) | all | **`404`** | 102–103 ms | none | `code="model_not_found"` (not in key's 11 models) |
| **`qwen/qwen3.8-27b`** (in allowlist) | plain / json / **speakaboo_prompt** | **`200`** | **216–409 ms** | `1000 req/day`, `8000 TPM` | **WORKS cleanly (`543+128 tok`, valid Speakaboo JSON)** |

## 4. Text-to-Speech (`POST /audio/speech`, `canopylabs/orpheus-v1-english`)
Tested all 6 voices (`autumn`, `diana`, `hannah`, `austin`, `daniel`, `troy`):
- **Status:** **`400 BAD REQUEST`** on ALL 6 voices (92–204 ms)
- **Exact Error Body:**
  ```json
  {"error":{"message":"The model `canopylabs/orpheus-v1-english` requires terms acceptance. Please have the org admin accept the terms at https://console.groq.com/playground?model=canopylabs%2Forpheus-v1-english","type":"invalid_request_error","code":"model_terms_required"}}
  ```
- **Verdict:** **BLOCKED on account until model terms are accepted** -> Documented exact steps in `workfix/NEEDS_FROM_USER.md` + adding real on-device `flutter_tts` fallback when server returns `audio_unavailable: true`.
