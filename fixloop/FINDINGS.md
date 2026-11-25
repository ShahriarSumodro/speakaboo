# Speakaboo Fix Loop Findings & Evidence

## Bug Evidence Log

### B1: Turn 2+ Stops Answering and Speaking
- **Symptom:** First turn (greeting) shows, but after the user speaks, nothing happens: no reply, no voice, no error shown.
- **Root Cause:** `backend/routes/conversation.py:426-428` yielded SSE events as `event: {event_name}\ndata: {event_data}\n\n`. In `app/lib/services/api_service.dart:501-512`, `streamTurn` discarded the `event:` header and yielded `data` directly without `type`. In `app/lib/providers/conversation_provider.dart:202-235`, every branch checked `if (type == 'transcript')`, `else if (type == 'reply_chunk')`, `else if (type == 'audio_chunk')`, `else if (type == 'turn_complete')`. Because `event['type']` was always `null`, all incoming messages were skipped. The stream completed cleanly, adding no chat messages, playing no audio, and throwing no exception.
- **Verification:** Fixed in `25f050f` by injecting `type` into SSE data, tracking `event:` in `api_service.dart`, adding `reply_start` support, and handling flat/nested `turn_complete` fields. Verified 8 consecutive turns in `backend/scripts/e2e_turns.py`.

### B2: Voice 100ms / Fake / Silent Audio
- **Symptom:** Audio files last 100ms on phone (`getDuration: 100 (msec)`); preview audio returns 200 in 2ms.
- **Root Cause:** Probed all 6 Groq Orpheus voices (`autumn`, `diana`, `hannah`, `austin`, `daniel`, `troy`) against `https://api.groq.com/openai/v1/audio/speech`. All 6 returned HTTP 400: `{"error":{"message":"The model canopylabs/orpheus-v1-english requires terms acceptance. Please have the org admin accept the terms at https://console.groq.com/playground?model=canopylabs%2Forpheus-v1-english","type":"invalid_request_error","code":"model_terms_required"}}`. Product code previously caught this and silently fell back to `MockTtsProvider()`, serving a 100-byte (100ms) dummy WAV file in 2ms.
- **Verification:** Removed all mock fallbacks from product code. Added clear error logging, friendly UI stage message ("I could not make my voice. Tap to retry."), and documented terms acceptance requirement in `fixloop/NEEDS_FROM_USER.md`.

### B3: Server Banner Stuck
- **Symptom:** Red "Server not ready" banner stays visible even when Test Connection says Connected.
- **Root Cause:** `DevServerDialog._testConnection` tested health and updated local state inside the dialog, but did not update `AuthProvider.serverConnected`. Furthermore, `_AppRoot` in `main.dart` did not poll `/api/health` every 15s or listen to app lifecycle resume events.
- **Verification:** Fixed in `6f4cfba`. Added `checkHealth()`, `setServerConnected()`, 15-second polling timer in `AuthProvider`, `WidgetsBindingObserver` lifecycle resume trigger in `_AppRoot`, and dialog synchronization in `DevServerDialog`. Verified with widget test `app/test/server_banner_test.dart`.

### B4: 401 Unauthorized
- **Symptom:** 401 Unauthorized on `/api/auth/set-parent-pin`, `/api/learning/vocabulary/{id}`, `/api/learning/progress/{id}`.
- **Root Cause:** In `backend/routes/auth.py`, `DeviceAuthResponse` returned `token: str`. In `auth_provider.dart:95`, `_authToken = authRes['auth_token'] as String;` threw a null type cast exception (`Null is not a subtype of String`), leaving `_authToken` null in both `AuthProvider` and `ApiService`. Subsequent requests lacked `Authorization: Bearer <token>`, causing `get_current_user_id` to raise 401. Additionally, `ApiService` had no retry mechanism on 401.
- **Verification:** Fixed in `b395ee5`. Added `auth_token` to `DeviceAuthResponse`, updated `auth_provider.dart` to check both keys, implemented `_ensureAuthToken()` and `_sendWithAuthRetry()` with auto device re-registration in `api_service.dart`. Verified with 5 unit tests in `app/test/auth_retry_test.dart`.

### B5: 404 on Shadowing
- **Symptom:** `GET /api/learning/shadowing` returns 404.
- **Root Cause:** `app/lib/services/api_service.dart` called `GET /api/learning/shadowing` (which did not exist), while backend defined `GET /api/learning/shadowing/scripts`. Also evaluation payload expected `user_id`, `script_id`, and `duration_seconds`.
- **Verification:** Fixed in `f8c5321`. Added `/shadowing` alias in backend, supported both `script_id` and `item_id`, and `duration_seconds` and `duration_sec` with default `user_id`. Updated `api_service.dart` to call `/shadowing/scripts`. Verified with pytest `backend/tests/test_learning_modes.py` and Flutter widget tests.

### B6: Dark Theme Contrast & Empty Vocabulary Focus
- **Symptom:** Dark theme contrast unreadable; "Vocabulary Focus:" row is empty.
- **Root Cause:** Character JSON files in `backend/characters/`, `Character` dataclass in `backend/engine/characters.py`, and `CharacterResponse` in `backend/routes/characters.py` lacked `vocabulary_focus`. In `character_detail_screen.dart`, static theme tokens were previously used instead of `context.colors`, leading to low contrast in dark theme.
- **Verification:** Fixed in `5610304`. Added `vocabulary_focus` to `rule_farmer.json`, `dhaka_detective.json`, and `professor_anika.json`. Updated `Character` model and API response. Updated `character_detail_screen.dart` with theme-aware `context.colors` RichText layout and conditional row display. Verified with `backend/tests/test_characters.py` (12 passed) and `flutter test` (46 passed).
