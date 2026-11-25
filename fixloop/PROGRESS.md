# Speakaboo Fix Loop Progress

## Bug Table

| ID | Symptom | Root Cause | Status | Commit |
|---|---|---|---|---|
| B1 | After first spoken turn, character stops answering and speaking | `api_service.dart:streamTurn` ignored `event: ` SSE header and yielded data without `type`; `conversation_provider.dart` skipped all event handlers and silently finished turn | Fixed (Phase 0/2) | `25f050f` |
| B2 | Voice sounds fake or silent (100ms dummy wav); preview audio returns 200 in 2ms | Groq TTS 400 terms required on `canopylabs/orpheus-v1-english`; product code had silent fallback to `MockTtsProvider` generating 100-byte wav | Fixed (Phase 0/2) | `25f050f` |
| B3 | Red banner "Server not ready" stays visible after Test Connection succeeds | Banner state only updated on initial load; lacked 15s periodic health check, lifecycle resume trigger, refresh handler, and dialog sync | Fixed (Phase 3) | |
| B4 | 401 Unauthorized on `/api/auth/set-parent-pin`, `/api/learning/vocabulary/{id}`, etc. | Missing token before registration finishes or missing auto-reregister + retry interceptor on 401 | In Progress (Phase 4) | |
| B5 | 404 on `GET /api/learning/shadowing` | `api_service.dart` calls `/api/learning/shadowing` instead of backend `/api/learning/shadowing/scripts` and `/api/learning/shadowing/evaluate` | Pending (Phase 5) | |
| B6 | Dark theme contrast unreadable; empty "Vocabulary Focus:" row | Hardcoded light theme tokens across screens and missing `vocabulary_focus` in character JSON data and backend models | Pending (Phase 6) | |

## Current Phase
Phase 4: Fix B4 (401 Unauthorized)

## NEXT ACTION
Implement auto-retry with device re-registration interceptor in api_service.dart on 401 and write unit tests for unauthenticated/expired token handling.
