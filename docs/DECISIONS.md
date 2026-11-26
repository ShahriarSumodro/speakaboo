# Speakaboo — Architecture Decisions (ADR Summary)

1. **ADR-001: SQLite with Repository Abstraction (`BaseRepository` / `SqliteRepository`)** — Keeps local dev & single-node deployment zero-config with WAL mode while allowing future Postgres swap.
2. **ADR-002: Stateless HS256 Device Auth + Parent PIN** — Frictionless onboarding via device ID (`POST /api/auth/device`), 1-year signed bearer tokens, and salted SHA-256 parent gate PIN.
3. **ADR-003: SSE Streaming Turns with Blocking Fallback** — `ConversationProvider` streams `transcript`, `reply_start`, `audio_chunk`, and `turn_complete` over SSE for low latency, falling back to `POST /api/conversation/turn` on transport errors.
4. **ADR-004: Strict 200-Char TTS Chunking** — Groq Orpheus enforces <=200 chars per request; `ConversationEngine._split_text` splits at sentence boundaries before synthesis and caches chunks by `voice_id:text`.
5. **ADR-005: Asia/Dhaka (`UTC+6`) Day Boundaries** — All daily caps, streaks, missions, and Leitner reviews use explicit `UTC+6` helpers (`dhaka_today`, `dhaka_date_add`, `dhaka_date_diff`) rather than server local time.
6. **ADR-006: Play vs Direct Flavor Separation** — `AppConfig.flavor` (`play` vs `direct`) separates Google Play Billing from bKash/Nagad UI flows.
