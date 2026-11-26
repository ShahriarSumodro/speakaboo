# Code Truth Loop — Progress

## Status: COMPLETE — All Phases 0-7 Done

## Phase Checklist
- [x] Phase 0: Baseline (create state files, verify_all.ps1, run baseline, fix broken tests)
- [x] Phase 1: Map the codebase (inventory, dependency graph, dead code, big files, smells)
- [x] Phase 2: Core logic audit (16 units, specs, tests, verdicts)
- [x] Phase 3: Clean-code refactor (deduplicated gateways, _categorize_error, conversation helpers, fixed 18 swallowed catches)
- [x] Phase 4: Architecture handoff pack (AGENTS.md, GEMINI.md, docs/*, docs/ai/*)
- [x] Phase 5: Prove docs match code (check_docs.py, HANDOFF_TEST.md)
- [x] Phase 6: Guard rails (test_architecture_guardrails.py, pytest-asyncio loop scope)
- [x] Phase 7: Final re-check (all tests green, all docs current)

## Current Task
Complete. See `codeaudit/FINAL_REPORT.md`.

## NEXT ACTION
None (STOP CONDITION met).

## Module Table (Phase 2)
| # | Unit | Spec | Tests | Verdict | Evidence |
|---|------|------|-------|---------|----------|
| 1 | Conversation turn pipeline | [01](specs/01_conversation_pipeline.md) | `test_conversation.py` | CORRECT | `[RAN]` Fixed stream_turn error handling + removed dead return |
| 2 | Correction logic | [02](specs/02_correction_logic.md) | `test_correction.py` | CORRECT | `[RAN]` Fixed categorize_error unchanged preposition bug |
| 3 | Safety filter | [03](specs/03_safety_filter.md) | `test_safety.py`, `test_phase7_safety.py` | CORRECT | `[RAN]` 49/49 tests across units 1-3 pass |
| 4 | Providers STT/AI/TTS | [04](specs/04_providers.md) | `test_providers.py` | CORRECT | `[RAN]` Timeout, retry, backoff, voice & length guards verified |
| 5 | Auth + tokens | [05](specs/05_auth_tokens.md) | `test_phase1_security_and_streaming.py`, `test_hardening.py` | CORRECT | `[RAN]` HS256 JWT + PIN hash + access checks verified |
| 6 | Entitlements + caps | [06](specs/06_entitlements_caps.md) | `test_payment.py` | CORRECT | `[RAN]` 2-min locked trial + daily cap enforced (noted plan/entitlement alignment in FINDINGS) |
| 7 | Streaks/XP/levels/missions | [07](specs/07_streaks_xp_missions.md) | `test_gamification.py`, `test_level.py`, `test_missions.py` | CORRECT | `[RAN]` Asia/Dhaka rollover, freeze, repair, XP curve verified |
| 8 | Vocabulary + spaced repetition | [08](specs/08_vocabulary_leitner.md) | `test_vocabulary.py` | CORRECT | `[RAN]` Leitner box 1-5 intervals & dedup verified |
| 9 | Shadowing scoring | [09](specs/09_shadowing.md) | `test_learning_modes.py` | CORRECT | `[RAN]` F1 accuracy, WPM pace, overall weighted score verified |
| 10 | Payments + billing | [10](specs/10_payments_billing.md) | `test_payment.py`, `test_phase9_payment.py`, `test_phase2_payments_and_distribution.py` | CORRECT | `[RAN]` Fixed usage daily_limit ignoring paid plan entitlement (F-021) |
| 11 | Parent dashboard + privacy | [11](specs/11_parent_privacy.md) | `test_parent_dashboard.py` | CORRECT | `[RAN]` Auth + user isolation + export + full purge verified |
| 12 | Retention + experiments | [12](specs/12_retention_experiments.md) | `test_phase6_retention.py`, `test_phase1_measurements.py` | CORRECT | `[RAN]` Deterministic SHA-256 bucketing & event logging verified |
| 13 | Database layer | [13](specs/13_database_layer.md) | `test_repository.py` | CORRECT | `[RAN]` 16 tables, WAL mode, Dhaka rollover, full purge verified |
| 14 | App state machines | [14](specs/14_app_state_machines.md) | `data_layer_test.dart`, `auth_retry_test.dart`, `server_banner_test.dart` | CORRECT | `[RAN]` Auth + health polling + stream-to-blocking fallback verified |
| 15 | App API client route matching | [15](specs/15_api_route_matching.md) | `check_routes.py`, `widget_test.dart` | CORRECT | `[RAN]` Fixed 9 route mismatches in api_service.dart (0/43 mismatches now) |
| 16 | Config + secrets | [16](specs/16_config_secrets.md) | `test_config.py` | CORRECT | `[RAN]` .env loading, provider validation, .env.example verified |
