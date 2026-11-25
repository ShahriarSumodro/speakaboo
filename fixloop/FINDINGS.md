# Speakaboo Fix Loop Findings & Evidence

## Bug Evidence Log

### B1: Turn 2+ Stops Answering and Speaking
- **Symptom:** First turn (greeting) shows, but after the user speaks, nothing happens: no reply, no voice, no error shown.
- **Root Cause:** `[READ]` `backend/routes/conversation.py:426-428` yields SSE formatted events `event: {event_name}\ndata: {event_data}\n\n`. In `app/lib/services/api_service.dart:501-512`, `streamTurn` discarded the `event:` header and yielded `data` directly without `type`. In `app/lib/providers/conversation_provider.dart:202-235`, every branch checks `if (type == 'transcript')`, `else if (type == 'reply_chunk')`, `else if (type == 'audio_chunk')`, `else if (type == 'turn_complete')`. Because `event['type']` was always `null`, all incoming messages were skipped. The stream completed cleanly, adding no chat messages, playing no audio, and throwing no exception.

### B2: Voice 100ms / Fake / Silent Audio
- **Symptom:** Audio files last 100ms on phone (`getDuration: 100 (msec)`); preview audio returns 200 in 2ms.
- **Root Cause:** `[RAN]` Groq `/openai/v1/audio/speech` with `canopylabs/orpheus-v1-english` returned HTTP 400: `{"error":{"message":"The model canopylabs/orpheus-v1-english requires terms acceptance. Please have the org admin accept the terms at https://console.groq.com/playground?model=canopylabs%2Forpheus-v1-english","type":"invalid_request_error","code":"model_terms_required"}}`. Product code in `backend/routes/characters.py:114` and `backend/engine/conversation.py:424, 495` had an exception handler that fell back to `MockTtsProvider()`. `MockTtsProvider` generates a dummy ~100-byte WAV header without synthesized audio, returning 200 OK in 2ms and 100ms audio.

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
