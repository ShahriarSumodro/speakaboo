# Speakaboo Decisions Log

Every assumption made instead of asking the user, with reasoning.

---

## Architecture Decisions

### D001: LLM Model Choice (Updated V2)
**Decision:** Default to `openai/gpt-oss-120b` on Groq, backed by automatic runtime fallbacks (`llama-3.3-70b-versatile`, `llama-3.1-8b-instant`).
**Reason:** `meta-llama/llama-4-scout-17b-16e-instruct` was retired by Groq. `openai/gpt-oss-120b` provides fast, structured JSON output and strong conversational instruction following. The fallback list ensures zero downtime if a model is decommissioned.

### D002: TTS Provider (Updated V2)
**Decision:** Default to `canopylabs/orpheus-v1-english` on Groq with valid character-assigned voices: `austin` (Farmer Reggie), `daniel` (Detective Kabir), `diana` (Professor Anika).
**Reason:** `playai-tts` and `Arista-PlayAI` were retired by Groq. Orpheus provides high-quality conversational English speech under the 200-character chunk limit with official, distinct voices.

### D003: Database
**Decision:** SQLite for development, behind a repository abstraction layer.
**Reason:** Per the spec, SQLite for dev with Postgres swap capability. Using SQLAlchemy or raw async SQL with an abstract repository.

### D004: Auth Strategy
**Decision:** Device-based anonymous auth first (UUID generated on first launch, stored locally). Upgradeable to email/password later.
**Reason:** Spec says "device-based anonymous user first, upgradeable to login." Simplest path to get conversations working.

### D005: Timezone for Streaks
**Decision:** All streak day boundaries use `Asia/Dhaka` (UTC+6) timezone.
**Reason:** Target users are in Bangladesh. Spec explicitly says timezone-safe for Asia/Dhaka.

### D006: Pricing
**Decision:** Monthly plan at 200 BDT, per-character unlock at 350 BDT.
**Reason:** Spec suggests "about 200 BDT/month and 350 BDT/character." Using these as defaults in config.

---

## NEEDS FROM USER

| Item | Why | Blocking? |
|------|-----|-----------|
| Groq API key | Required to test real STT/LLM/TTS | No (mock providers work) |
| bKash merchant credentials | Real payment integration | No (mock gateway works) |
| Nagad merchant credentials | Real payment integration | No (mock gateway works) |
| Character artwork/assets | Visual design for characters | No (placeholder used) |
| Privacy policy legal review | Legal text for app store | No (draft provided) |
| App signing keys | Release builds | No (debug builds work) |
