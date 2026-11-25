# Speakaboo Fix Loop Findings & Evidence

## Bug Evidence Log

### B1: Turn 2+ Stops Answering and Speaking
- **Symptom:** First turn (greeting) shows, but after the user speaks, nothing happens: no reply, no voice, no error shown.
- **Root Cause:** `[READ]` `backend/routes/conversation.py:426-428` yielded SSE events as `event: {event_name}\ndata: {event_data}\n\n`. In `app/lib/services/api_service.dart:501-512`, `streamTurn` discarded the `event:` header and yielded `data` directly without `type`. In `app/lib/providers/conversation_provider.dart:202-235`, every branch checks `if (type == 'transcript')`, `else if (type == 'reply_chunk')`, `else if (type == 'audio_chunk')`, `else if (type == 'turn_complete')`. Because `event['type']` was always `null`, all incoming messages were skipped. The stream completed cleanly, adding no chat messages, playing no audio, and throwing no exception.
- **Verification:** Fixed in Phase 0 by injecting `type` into SSE data, tracking `event:` in `api_service.dart`, adding `reply_start` support, and handling flat/nested `turn_complete` fields.

### B2: Voice 100ms / Fake / Silent Audio
- **Symptom:** Audio files last 100ms on phone (`getDuration: 100 (msec)`); preview audio returns 200 in 2ms.
- **Root Cause:** `[RAN]` `backend/scripts/e2e_turns.py` probed all 6 Groq Orpheus voices (`autumn`, `diana`, `hannah`, `austin`, `daniel`, `troy`) against `https://api.groq.com/openai/v1/audio/speech`. All 6 returned HTTP 400: `{"error":{"message":"The model canopylabs/orpheus-v1-english requires terms acceptance. Please have the org admin accept the terms at https://console.groq.com/playground?model=canopylabs%2Forpheus-v1-english","type":"invalid_request_error","code":"model_terms_required"}}`. Product code previously caught this and silently fell back to `MockTtsProvider()`, serving a 100-byte (100ms) dummy WAV file in 2ms.
- **Verification:** Removed all mock fallbacks from product code. Added clear error logging, friendly UI stage message ("I could not make my voice. Tap to retry."), and documented terms acceptance requirement in `fixloop/NEEDS_FROM_USER.md`.

### B3: Server Banner Stuck
- **Symptom:** Red "Server not ready" banner stays visible even when Test Connection says Connected.
- **Root Cause:** `[READ]` `DevServerDialog._testConnection` tests `$cleanUrl/api/health` and updates local state inside the dialog, but does not update `AuthProvider.serverConnected`. Furthermore, `_AppRoot` in `main.dart` does not poll `/api/health` every 15s or listen to app lifecycle resume events.

### B4: 401 Unauthorized
- **Symptom:** 401 Unauthorized on `/api/auth/set-parent-pin`, `/api/learning/vocabulary/{id}`, `/api/learning/progress/{id}`.
- **Root Cause:** `[READ]` `backend/engine/auth_token.py:102-120` raises 401 when Authorization header is absent or token is invalid. In the app, if requests are dispatched before `deviceAuth` finishes storing `_authToken` or if the token is rejected, `api_service.dart` had no automatic device re-registration and retry mechanism on 401.

### B5: 404 on Shadowing
- **Symptom:** `GET /api/learning/shadowing` returns 404.
- **Root Cause:** `[READ]` `app/lib/services/api_service.dart:693` called `GET /api/learning/shadowing`, but `backend/routes/learning.py:276` defines `GET /api/learning/shadowing/scripts` and `POST /api/learning/shadowing/evaluate`.

### B6: Dark Theme Contrast & Empty Vocabulary Focus
- **Symptom:** Dark theme contrast unreadable; "Vocabulary Focus:" row is empty.
- **Root Cause:** `[READ]` Screens imported static `SpeakabooTheme` tokens rather than `context.colors` (`Theme.of(context).extension<SpeakabooColors>()`). `Character` model and JSON files did not declare `vocabulary_focus`.
