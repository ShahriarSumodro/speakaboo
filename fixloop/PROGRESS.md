# Speakaboo Fix Loop Progress

## Bug Table

| ID | Symptom | Root Cause | Status | Commit |
|---|---|---|---|---|
| B1 | After first spoken turn, character stops answering and speaking | `api_service.dart:streamTurn` ignored `event: ` SSE header and yielded data without `type`; `conversation_provider.dart` skipped all event handlers and silently finished turn | Fixed (Phase 0) | |
| B2 | Voice sounds fake or silent (100ms dummy wav); preview audio returns 200 in 2ms | Groq TTS 400 terms required on `canopylabs/orpheus-v1-english`; product code had silent fallback to `MockTtsProvider` generating 100-byte wav | Fixed (Phase 0) | |
| B3 | Red banner "Server not ready" stays visible after Test Connection succeeds | Banner state only updated on initial load; lacks lifecycle observer, 15s timer, refresh handler, and sync on health check | Pending | |
| B4 | 401 Unauthorized on `/api/auth/set-parent-pin`, `/api/learning/vocabulary/{id}`, etc. | Missing token before registration finishes or missing auto-reregister + retry interceptor on 401 | Pending | |
| B5 | 404 on `GET /api/learning/shadowing` | `api_service.dart` calls `/api/learning/shadowing` instead of backend `/api/learning/shadowing/scripts` and `/api/learning/shadowing/evaluate` | Pending | |
| B6 | Dark theme contrast unreadable; empty "Vocabulary Focus:" row | Hardcoded light theme tokens across screens and missing `vocabulary_focus` in character JSON data and backend models | In Progress | |

## Current Phase
Phase 1: Reproduce with the real providers

## NEXT ACTION
Write and run `backend/scripts/e2e_turns.py` with real Groq credentials to verify turn execution, TTS audio generation, and stage timings.
