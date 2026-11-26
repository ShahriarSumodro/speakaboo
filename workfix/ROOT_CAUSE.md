# Speakaboo Make-It-Work Loop — Root Cause Analysis

Every symptom below was traced end-to-end across real Groq HTTPS probes (`probe_providers.py`), a detached live `uvicorn` backend (`logs/uvicorn_stderr.log`), and the Flutter app source (`app/lib/`).

---

## Summary Attribution Table

| ID | Primary Fault Layer | Root Cause (One Sentence) |
|----|---------------------|---------------------------|
| **W1** | `[API]` + `[BACKEND]` + `[APP]` | `openai/gpt-oss-120b` hits `400 json_validate_failed` (reasoning eats `max_tokens=256`) and falls back to `404` models not in the Groq key allowlist, Orpheus TTS returns `400 model_terms_required`, and TalkScreen's Retry button calls `clearError()` instead of resending audio. |
| **W2** | `[API]` + `[APP]` | Groq Orpheus (`canopylabs/orpheus-v1-english`) returns `400 model_terms_required` -> backend returns HTTP `502` on `/preview-audio`, and `CharacterDetailScreen` has no real on-device `flutter_tts` fallback. |
| **W3** | `[APP]` | `DevServerDialog` "Test Connection" only checks unauthenticated `GET /api/health` and `Save & Apply` leaves stale `user_id`/`auth_token` in `AuthStorage` without re-verifying auth or authenticated routes. |
| **W4** | `[APP]` + `[BACKEND]` | `ShadowingScreen` never uploads recorded audio (it sends `transcript: _selectedItem!.targetText`), lacks any companion playback (`flutter_tts` / server audio), and `ShadowingEngine.evaluate()` has no WPM sanity clamp. |
| **W5** | `[APP]` | `ApiService.getTopics()` and `getScenarios()` expect Map wrappers (`data['topics']`, `data['scenarios']`) while the backend returns JSON lists (`[...]`), throwing `TypeError` that `TopicsScreen`/`ScenariosScreen` swallow; and "Free Talk" on Home does not reset/start a clean free-talk session if `TalkScreen` is already initialized or in error. |
| **W6** | `[APP]` | `VocabularyScreen` swallowed `addVocabulary`/`getVocabulary` errors silently (and prior to commit `b964a42`, `ApiService.addVocabulary` called non-existent `/api/learning/vocabulary/add` with mismatched field names, while empty/anonymous `userId` triggers `403` without re-auth). |

---

## Detailed Traces (W1 – W6)

### W1: Talk — "I could not think of a reply. Tap to retry.", Retry does nothing, text-only then stopped
- **Trace:** `TalkScreen._buildRecordArea` -> `ConversationProvider.stopRecordingAndSend()` -> `ApiService.streamTurn` (`POST /api/conversation/stream-turn`) or fallback `sendTurn` (`POST /api/conversation/turn`) -> `ConversationEngine` -> `GroqSttProvider` (`whisper-large-v3-turbo`) -> `GroqLlmProvider` -> `GroqTtsProvider` (`canopylabs/orpheus-v1-english`).
- **Evidence:**
  1. **`[API]` / `[BACKEND]` (`backend/config.py:54-59`, `.env`):** `probe_providers.py` showed `openai/gpt-oss-120b` passes simple prompts (`200`), but on the real `build_system_prompt()` fails with `400 {"code":"json_validate_failed","failed_generation":""}` because internal reasoning consumes `max_tokens=256`, and rate limit is `8000 TPM`. Both configured fallbacks (`llama-3.3-70b-versatile`, `llama-3.1-8b-instant`) return `404 model_not_found`. Meanwhile `qwen/qwen3.8-27b` (in the key's 11 models) returned `200 OK` (409 ms) with valid Speakaboo JSON.
  2. **`[API]` / `[APP]` (`logs/uvicorn_stderr.log:21-27`):** `GroqTtsProvider` returns `400 model_terms_required` on all 6 voices (`orpheus-v1-english`). `TurnResult` returns `audio_base64: []` without an explicit `audio_unavailable: true` signal or on-device `flutter_tts` fallback.
  3. **`[APP]` (`app/lib/services/audio_service.dart:108,117-131`):** `playChunks()` concatenates full WAV files (keeping embedded 44-byte RIFF headers) instead of playing chunks sequentially, and `playAudio()` completes before playback finishes.
  4. **`[APP]` (`app/lib/screens/talk_screen.dart:372`):** Error banner's `Retry` button executes `onPressed: conv.clearError`, which dismisses the error without resending the stored audio!

### W2: Characters — Farmer Reggie "Hear their voice" fails
- **Trace:** `CharacterDetailScreen._playVoicePreview()` -> `ApiService.getPreviewAudio('rule_farmer')` -> `GET /api/characters/rule_farmer/preview-audio` -> `GroqTtsProvider.synthesize()`.
- **Evidence:** Live trace returned `HTTP 502` (`logs/uvicorn_stderr.log:26-28`): `Groq TTS error: 400 ... model_terms_required` for `canopylabs/orpheus-v1-english`. `CharacterDetailScreen` (`character_detail_screen.dart:43-58`) shows SnackBar and has no real on-device `flutter_tts` fallback when server TTS is unavailable.

### W3: Settings — "Test Connection" green, features still fail
- **Trace:** `SettingsScreen` -> `DevServerDialog._testConnection()` -> `GET /api/health` (`dev_server_dialog.dart:55`), and `_save()` (`dev_server_dialog.dart:94-105`) calls `widget.onSaved` (`auth.initialize()`).
- **Evidence:** `[APP]` `_testConnection()` only probes unauthenticated `/api/health`. In `auth_provider.dart:91`, `initialize()` skips `/api/auth/device` if `_userId != null && _authToken != null` are already cached locally, so stale credentials against a fresh/changed server still fail downstream endpoints until manually cleared, and there is no Settings > Diagnostics check for auth/STT/LLM/TTS/topics/vocab.

### W4: Shadowing — nothing spoken, wrong speech ("I kill people") gets 100% and 930 WPM
- **Trace:** `ShadowingScreen._toggleRecording()` (`app/lib/screens/shadowing_screen.dart:96-100`) -> `ApiService.evaluateShadowing()` -> `POST /api/learning/shadowing/evaluate` -> `ShadowingEngine.evaluate()` (`backend/engine/shadowing.py:65`).
- **Evidence:**
  1. **`[APP]` (`shadowing_screen.dart:98`):** Hardcodes `transcript: _selectedItem!.targetText` (`// simulated target alignment`) and discards `bytes`! So the backend always grades the target script against itself (= `100.0%` accuracy even if user said `"I kill people"` or nothing!).
  2. **`[BACKEND]` (`shadowing.py:121-125`):** `pace_wpm = (len(user_words) / duration_seconds) * 60.0` with no sanity clamp or silence guard, yielding ~930 WPM on short taps. And `/shadowing/evaluate` expects a text `transcript` rather than transcribing real audio via `SttProvider`.
  3. **`[APP]` (`shadowing_screen.dart:156-200`):** No "Listen" button or audio/TTS playback exists on the screen, so nothing is spoken.

### W5: Topics & Scenarios — Refresh does nothing; Free Talk returns to Talk
- **Trace:** `TopicsScreen._loadTopics()` / `ScenariosScreen._loadScenarios()` -> `ApiService.getTopics()` / `getScenarios()` -> `GET /api/learning/topics` / `/scenarios`.
- **Evidence:**
  1. **`[APP]` (`api_service.dart:749,764` vs `logs/uvicorn_stderr.log:33-34`):** Live trace proved backend returns top-level JSON lists (`is_list=True`), while `ApiService.getTopics()` parses `data['topics']` and `getScenarios()` parses `data['scenarios']`, throwing `TypeError` on every call! Both screens catch and ignore the error (`topics_screen.dart:55`, `scenarios_screen.dart:58`), staying on the empty Refresh state forever. Also `ScenarioItem.fromJson` / `TopicItem.fromJson` mismatch backend field names (`suggested_vocabulary` / `sample_questions`).
  2. **`[APP]` (`home_screen.dart:354`, `talk_screen.dart:30-49`):** Tapping "Free Talk" switches `MainShell` tab to index 1 (`TalkScreen` inside `IndexedStack`), which keeps previous scenario/topic state or an error state without resetting to a fresh free-talk session.

### W6: Vocabulary notebook — adding word does nothing, stays empty
- **Trace:** `VocabularyScreen._showAddWordDialog()` (`app/lib/screens/vocabulary_screen.dart:95-105`) -> `ApiService.addVocabulary()` -> `POST /api/learning/vocabulary/{user_id}` -> `VocabularyScreen._loadVocabulary()`.
- **Evidence:** Live trace against `POST /api/learning/vocabulary/{uid}` succeeded (`200 OK`, `logs/uvicorn_stderr.log:35`) **after** our earlier route fix (`b964a42`). Previously, `api_service.dart:855` hit `404` on `/api/learning/vocabulary/add` with wrong JSON keys, and `vocabulary_screen.dart:103-105` caught exceptions with only `debugPrint(...)` (plus line 63 swallowed load errors, and if `auth.userId == 'anonymous'` before auth completes, backend returns `403`). Note also `_showAddWordDialog()` pops the dialog immediately before awaiting the save and shows zero error SnackBar on failure!
