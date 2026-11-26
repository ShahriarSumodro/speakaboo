# Code Truth Loop — Findings

## Format
Each finding: `F-<number>: <severity P0/P1/P2/P3> <category> — <one-line summary>`
Evidence tag: `[RAN]` ran it, `[READ]` read the code, `[HYPOTHESIS]` unproven.

---

## Phase 0 — Code Reading Findings

F-001: P2 dead-code — `conversation.py` lines 414-427 is a duplicate unreachable `return TurnResult(...)` after the first return on line 396. [READ conversation.py:396-427]

F-002: P3 dead-import — `sqlite_repo.py` line 959 creates `type_to_mission` dict but never uses it in `update_mission_progress`. [READ sqlite_repo.py:959]

F-003: P2 smell — `sqlite_repo.py` is 1367 lines. Too large; should be split (Phase 3 target). [READ]

F-004: P2 smell — `api_service.dart` is 35192 bytes (~1096 lines). Too large for a single service file. [READ]

F-005: P3 smell — `categorize_error()` in `correction.py:59` matches prepositions with `\b(in|on|at|to|for|with|by|from)\b` against the *original* text. These are extremely common English words, so almost ANY correction containing "in" or "on" gets categorized as "prepositions" rather than the actual error type. [READ correction.py:59-62]

F-006: P2 security — `auth_token.py:20` uses a hardcoded fallback secret `AUTH_SECRET_KEY = "speakaboo-secure-device-token-secret-2026"`. In production, if `AUTH_SECRET_KEY` env var is not set, tokens are signed with this known string. [READ auth_token.py:20]

F-007: P3 smell — `level.py:118` does `import re` inside a function instead of at module top. [READ level.py:118]

F-008: P2 smell — `payment.py` has 4 near-identical payment gateway classes (MockBkash, MockNagad, GooglePlay, WebBilling) with heavy code duplication. [READ payment.py]

F-009: P3 info — `config.py:255` loads `.env` only if key NOT already in `os.environ`, which is correct behavior. [READ config.py:255]

F-010: P2 logic — `safety.py` line 300-303: AI output safety check raises `SafetyError` for unsafe categories, but `conversation.py:299-303` catches `SafetyError` from `check_content_safety()` even though the user_message=False path raises, while the return-value path (returning a category string) is for user messages. This is correct but the asymmetry is confusing and should be documented. [READ safety.py:76-117, conversation.py:298-303]

F-011: P3 smell — `get_referral_info()` in `sqlite_repo.py:900-901` uses MD5 for referral codes. Not a security issue (not for auth), but should be noted. [READ sqlite_repo.py:900]

F-012: P1 logic — `stream_turn()` in `conversation.py` lines 429-660 does NOT handle LLM errors (bare `await self._llm.chat()` without try/except). If an LLM provider raises, the whole streaming generator crashes. Compare with `process_turn()` which wraps LLM calls in try/except. [READ conversation.py:534-535 vs 266-285]

F-013: P1 logic — `stream_turn()` does NOT handle STT errors. The STT call on line 446 is unprotected. If STT raises, the whole streaming response crashes. Compare with `process_turn()` lines 162-177 which wrap STT in try/except. [READ conversation.py:446 vs 162-177]

F-014: P2 duplication — `process_turn()` and `stream_turn()` duplicate the entire turn pipeline (~230 lines each). Should share a common core. [READ conversation.py:139-427 vs 429-660]

F-015: P3 naming — `sqlite_repo.py:14` uses `from typing import ... List, Dict, Any, Optional` (old style) alongside Python 3.14 which supports `list`, `dict`, etc. natively. [READ]

F-016: P0 bug — `backend/routes/conversation.py:47` calls `os.environ.get("TEST_MODE", ...)` without `import os`, causing `NameError: name 'os' is not defined` on `POST /api/conversation/start` and breaking 6 backend tests. [FIXED in 3f5d0d4] [RAN pytest]

F-017: P2 swallowed-error — 18 instances of `} catch (_) {}` in `app/lib/` (`app_config.dart`, `auth_provider.dart`, `api_service.dart`, `cache_service.dart`, `dev_server_dialog.dart`, and 6 screens). [RAN static scan]

F-018: P2 size — 21 files exceed 300 lines (largest: `sqlite_repo.py` 1367, `api_service.dart` 1096, `conversation.py` 859, `profile_screen.dart` 768). [RAN static scan]

F-019: P3 size — 48 Python functions exceed 40 lines (largest: `process_turn` 289, `initialize` 237, `stream_turn` 232). [RAN static scan]

F-020: P2 duplication — `routes/conversation.py:134` defines `_categorize_error()` which duplicates `engine/correction.py:categorize_error()` with the old preposition bug. [READ routes/conversation.py:134-152]

F-021: P1 bug — `routes/usage.py` computes `daily_limit` only from `user.plan`, ignoring active `Entitlement(type="plan")` rows granted by `routes/payment.py:verify_payment`. A paid user sees 10-min limit in `/api/usage/{user_id}/daily` while `_check_entitlements_and_caps` allows 30 min. [FIXED in 214cdde] [READ routes/usage.py:41-46 vs routes/payment.py:224-230]

F-022: P0 bug — `app/lib/services/api_service.dart` had 9 route mismatches against `backend/routes/*.py`: `getStreak`, `freezeStreak`, `claimMission`, `addVocabulary`, `reviewVocabulary`, `getParentSummary`, `getSafetyFlags`, `getUsage`, and dead `recordConsent`. [RAN check_routes.py]
