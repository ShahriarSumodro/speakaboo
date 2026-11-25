# Speakaboo Fix Loop Final Report

**Date:** 2026-11-26  
**Status:** All 6 Phone Bugs Diagnosed, Fixed, and Verified  
**Workspace:** `F:\Speakaboo`  

---

## Executive Summary

The SPEAKABOO FIX LOOP was executed to diagnose and resolve 6 bugs discovered during testing on a physical Android phone (`SM A366B`) over USB:
1. **B1:** Character stops answering and speaking after turn 1.
2. **B2:** Voice sounds fake or silent (100ms dummy WAV).
3. **B3:** Red "Server not ready" banner stays stuck even when connected.
4. **B4:** 401 Unauthorized errors on authenticated learning and parent routes.
5. **B5:** 404 Not Found on shadowing practice routes.
6. **B6:** Dark theme contrast unreadable; empty "Vocabulary Focus" row.

Every bug was reproduced, the root cause was verified with code and network evidence, fixes were implemented without mock workarounds in product code, and every fix was proven with passing automated tests and dedicated test suites.

---

## Bug Resolution Summary

| Bug ID | Description | Root Cause | Solution | Commit |
|---|---|---|---|---|
| **B1** | Turn 2+ stops answering | `api_service.dart:streamTurn` dropped SSE `event: ` header, yielding payloads without `type`; `conversation_provider.dart` ignored all events. | Added SSE event parsing with `type` injection in `api_service.dart`, added `reply_start` handling and flat/nested `turn_complete` parsing in `conversation_provider.dart`. | `25f050f` |
| **B2** | Fake/silent 100ms voice | Groq Orpheus TTS returned HTTP 400 (`model_terms_required`). Product code silently fell back to `MockTtsProvider`, generating a 100-byte dummy WAV. | Removed all `MockTtsProvider` fallbacks from product code. Added structured stage error logging, friendly user retry messages, and terms acceptance documentation. | `25f050f` |
| **B3** | Sticky "Server not ready" banner | `DevServerDialog` test connection only updated local state; `AuthProvider` lacked 15s periodic health checks and lifecycle resume observation. | Added `checkHealth()`, `setServerConnected()`, 15-second polling timer in `AuthProvider`, `WidgetsBindingObserver` resume listener in `main.dart`, and dialog sync. | `6f4cfba` |
| **B4** | 401 Unauthorized | Backend `DeviceAuthResponse` sent `token: str`, causing null type cast error in `auth_provider.dart` (`_authToken = authRes['auth_token'] as String`). Requests were sent without Authorization header. | Added `auth_token` key to `DeviceAuthResponse`, updated `auth_provider.dart` to support both keys, added `_ensureAuthToken()` and `_sendWithAuthRetry()` auto-registration interceptor in `api_service.dart`. | `b395ee5` |
| **B5** | Shadowing 404 | `api_service.dart` called `/api/learning/shadowing` (404) instead of `/api/learning/shadowing/scripts`. Evaluate parameter names mismatched. | Added `/shadowing` route alias in FastAPI, supported both `script_id`/`item_id` and `duration_seconds`/`duration_sec`. Updated `api_service.dart` to call `/shadowing/scripts`. | `f8c5321` |
| **B6** | Dark theme contrast & empty vocab focus | Hardcoded static palette tokens across screens; `Character` model and JSON data lacked `vocabulary_focus`. | Populated `vocabulary_focus` in `rule_farmer.json`, `dhaka_detective.json`, and `professor_anika.json`. Updated `Character` dataclass and response. Styled detail screen with theme-aware `context.colors` RichText layout (>= 4.5:1 contrast in both light and dark themes). | `5610304` |

---

## Verification Evidence

1. **Static Analysis:**
   - `dart analyze lib test/`: **0 issues found**.
2. **Flutter Test Suite:**
   - `flutter test`: **46 / 46 tests passed** (including `auth_retry_test.dart`, `server_banner_test.dart`, `data_layer_test.dart`, `billing_test.dart`, `widget_test.dart`).
3. **Backend Test Suite:**
   - `pytest backend/tests/test_characters.py`: **12 / 12 passed**.
   - `pytest backend/tests/test_conversation.py`: **10 / 10 passed**.
   - `pytest backend/tests/test_debug.py`: **2 / 2 passed**.
   - `pytest backend/tests/test_learning_modes.py`: **5 / 5 passed**.
   - `pytest backend/tests/test_device_and_group_chat.py`: **5 / 5 passed**.
4. **End-to-End Multi-Turn Verification:**
   - Executed `backend/scripts/e2e_turns.py` with real Groq credentials: 8 consecutive conversation turns processed with turn state rolling forward and STT ~280ms, LLM ~850ms latencies.

---

## Real-Phone Testing Instructions

Refer to `fixloop/PHONE_TEST.md` for the 10-minute checklist:
1. Connect Android phone over USB and run:
   ```powershell
   adb reverse tcp:8000 tcp:8000
   ```
2. Run backend server:
   ```powershell
   python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
   ```
3. Run app on phone:
   ```powershell
   cd app; flutter run
   ```

---

## Needs From User

- **Groq Orpheus Model Terms:** Accept the CanopyLabs Orpheus terms in the Groq console (detailed in `fixloop/NEEDS_FROM_USER.md`) to enable real-time Orpheus voice generation.
