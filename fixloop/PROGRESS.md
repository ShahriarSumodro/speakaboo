# Speakaboo Fix Loop Progress

## Bug Table

| ID | Symptom | Root Cause | Status | Commit |
|---|---|---|---|---|
| B1 | After first spoken turn, character stops answering and speaking | `api_service.dart:streamTurn` ignored `event: ` SSE header and yielded data without `type`; `conversation_provider.dart` skipped all event handlers and silently finished turn | Fixed | `25f050f` |
| B2 | Voice sounds fake or silent (100ms dummy wav); preview audio returns 200 in 2ms | Groq TTS 400 terms required on `canopylabs/orpheus-v1-english`; product code had silent fallback to `MockTtsProvider` generating 100-byte wav | Fixed | `25f050f` |
| B3 | Red banner "Server not ready" stays visible after Test Connection succeeds | Banner state only updated on initial load; lacked 15s periodic health check, lifecycle resume trigger, refresh handler, and dialog sync | Fixed | `6f4cfba` |
| B4 | 401 Unauthorized on `/api/auth/set-parent-pin`, `/api/learning/vocabulary/{id}`, etc. | Missing `auth_token` key in `DeviceAuthResponse` caused null cast exception in Dart; missing auto-registration and 401 retry interceptor in `api_service.dart` | Fixed | `b395ee5` |
| B5 | 404 on `GET /api/learning/shadowing` | `api_service.dart` called `/api/learning/shadowing` instead of backend `/api/learning/shadowing/scripts` and evaluation parameters mismatched | Fixed | `f8c5321` |
| B6 | Dark theme contrast unreadable; empty "Vocabulary Focus:" row | Hardcoded light palette tokens and missing `vocabulary_focus` in character JSON data, `Character` dataclass, and `CharacterResponse` | Fixed | `5610304` |

## Test Suite Status
- **Backend pytest**: 25+ tests passing (`test_characters.py`, `test_conversation.py`, `test_debug.py`, `test_learning_modes.py`, `test_device_and_group_chat.py`, `test_phase1_security_and_streaming.py`).
- **Flutter unit & widget tests**: 46/46 tests passing (`auth_retry_test.dart`, `server_banner_test.dart`, `data_layer_test.dart`, `billing_test.dart`, `widget_test.dart`).
- **Dart analyze**: 0 errors, 0 warnings.
- **End-to-end turns (`backend/scripts/e2e_turns.py`)**: 8 consecutive turns executed through real STT, LLM, state roll forward, diagnostics ring buffer.

## Current Phase
All Fix Phases (Phase 0 - Phase 6) Complete.
Checklist created in `fixloop/PHONE_TEST.md`.
Final report in `fixloop/FINAL_REPORT.md`.
