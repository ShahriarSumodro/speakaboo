# Speakaboo Decisions Log

Every assumption made instead of asking the user, with reasoning.

---

## Architecture Decisions

### D001: LLM Model Choice
**Decision:** Default to `meta-llama/llama-4-scout-17b-16e-instruct` on Groq as the LLM provider.
**Reason:** Groq's free tier models change frequently. This model is available on Groq's free tier at time of development. The model ID is read from config (`.env`), so swapping is trivial.

### D002: TTS Provider
**Decision:** Use Groq's PlayAI TTS (`playai-tts` model with `Arista-PlayAI` voice) as default TTS.
**Reason:** Groq offers TTS on their API. Voice ID is configurable per character. If Groq TTS is unavailable or too expensive, the provider interface allows swapping.

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
