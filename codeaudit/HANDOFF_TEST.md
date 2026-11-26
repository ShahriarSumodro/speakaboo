# Code Truth Loop — Handoff Test (Phase 5)

Simulated 5-task handoff test using ONLY `AGENTS.md` + `docs/` to locate targets and rules without scanning the codebase:

| # | Task | Docs Consulted | Exact Files & Rules Found | Result |
|---|------|---------------|--------------------------|--------|
| 1 | Add a new grammar error priority rule | `docs/MODULE_MAP.md`, `docs/DOMAIN_RULES.md`, `docs/ai/02_correction_logic.md` | `backend/engine/correction.py` (`PEDAGOGICAL_ERROR_PRIORITY`, `categorize_error`), single-error rule | PASS |
| 2 | Debug why a locked character blocks after 2 minutes | `docs/MODULE_MAP.md`, `docs/DOMAIN_RULES.md`, `docs/ai/06_entitlements_caps.md` | `backend/routes/conversation.py` (`_check_entitlements_and_caps`, `start_conversation`), `character_trials` 120s limit | PASS |
| 3 | Fix a Flutter screen API 404 | `AGENTS.md`, `docs/API_CONTRACT.md`, `docs/ai/15_api_route_matching.md` | `app/lib/services/api_service.dart` vs `backend/routes/*.py`, verify with `scripts/check_docs.py` | PASS |
| 4 | Change daily streak rollover or freeze behavior | `docs/MODULE_MAP.md`, `docs/DOMAIN_RULES.md`, `docs/ai/07_streaks_xp_missions.md` | `backend/repositories/sqlite_repo.py` (`record_activity`, `dhaka_today`), Asia/Dhaka UTC+6 rule | PASS |
| 5 | Add a new TTS voice or adjust 200-char chunking | `AGENTS.md`, `docs/DECISIONS.md`, `docs/ai/04_providers.md` | `backend/providers/groq_tts.py` (`VALID_VOICES`), `backend/engine/conversation.py` (`_split_text`), ADR-004 | PASS |

All 5 tasks resolved directly from `AGENTS.md` + `docs/` without full-repo scanning.
