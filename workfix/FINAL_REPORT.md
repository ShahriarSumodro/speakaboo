# Speakaboo Make-It-Work Loop — Final Report

All symptoms **W1–W6** were reproduced against the live backend (`uvicorn`) and real Groq APIs, attributed cleanly across `[API]`, `[BACKEND]`, and `[APP]`, fixed one issue per commit with failing-first tests, and verified end-to-end.

---

## 1. What Broke and Why (`W1`–`W6`)

| ID | Fault Layer | Root Cause | Fix Commits & Changes |
|----|-------------|------------|------------------------|
| **W1** | `[API]` + `[BACKEND]` + `[APP]` | Default LLM `openai/gpt-oss-120b` failed with `400 json_validate_failed` (`max_tokens=256` consumed by reasoning) and fell back to `404` models not on the key (`llama-3.3-70b-versatile`, `llama-3.1-8b-instant`). Groq Orpheus TTS (`canopylabs/orpheus-v1-english`) returned `400 model_terms_required`. On mobile, `AudioService.playChunks()` concatenated WAV files with raw 44-byte RIFF headers, and `TalkScreen` Retry called `clearError()` instead of resending audio. | `da0070e`: Switched default LLM to `qwen/qwen3.8-27b`, fallback chain `(qwen/qwen3.8-27b, openai/gpt-oss-120b, openai/gpt-oss-20b)`, `max_tokens=512`, explicit `audio_unavailable` flag.<br>`59668ec`: Sequential WAV playback in `AudioService.playChunks()`, stored `_lastRecordedAudio` + `ConversationProvider.retryLastTurn()`, `TalkScreen` Retry invokes `retryLastTurn()`, plus `flutter_tts` fallback when server TTS is unavailable. |
| **W2** | `[API]` + `[APP]` | `GET /api/characters/rule_farmer/preview-audio` returned HTTP `502` because `canopylabs/orpheus-v1-english` returned `400 model_terms_required`, and `CharacterDetailScreen` lacked an on-device TTS fallback. | `fe723ce`: Added `flutter_tts` fallback (`AudioService.speakOnDevice`) when server preview returns an error; added manual Groq Console terms acceptance steps in `workfix/NEEDS_FROM_USER.md`. |
| **W3** | `[APP]` | `DevServerDialog` "Test Connection" only probed unauthenticated `GET /api/health`, while `Save & Apply` left stale cached credentials without re-authenticating against the selected server. | `e35bb7f`: `DevServerDialog._testConnection()` now verifies `/api/health` -> `POST /api/auth/device` -> `GET /api/auth/profile` before showing `Connected!`, and `_save()` awaits `AuthProvider.reauthenticate()`.<br>`39f3fe4`: Added **Settings > Diagnostics** (7 live checks + `Copy report`) and `POST /api/debug/diagnostics/{stt,llm,tts}`. |
| **W4** | `[APP]` + `[BACKEND]` | `ShadowingScreen` discarded recorded audio and uploaded `transcript: _selectedItem!.targetText` (`100%` fake score even on `"I kill people"`), had no companion audio playback, and `ShadowingEngine.evaluate()` lacked a WPM sanity clamp. | `d1bc362`: Added `POST /api/learning/shadowing/evaluate-audio` (real `SttProvider` transcription + safety check + WPM clamped to `[0, 300]`, 0 score on silence/unsafe/mismatched speech), updated `ShadowingScreen` to upload real audio and added `Listen` (`flutter_tts`) playback button. |
| **W5** | `[APP]` | `ApiService.getTopics()` / `getScenarios()` indexed `data['topics']` / `data['scenarios']` on top-level JSON lists, throwing `TypeError` silently caught in both screens; **Free Talk** on Home switched to Tab 1 without resetting prior topic/scenario/error state. | `3c98132`: Parsed direct JSON lists & backend schema fields (`suggested_vocabulary`, `sample_questions`).<br>`c3f34cc`: Surfaced real error messages + `RefreshIndicator` + Refresh button on `TopicsScreen` and `ScenariosScreen`; added `ConversationProvider.startFreeTalk()` and wired Home **Free Talk** / **Start Speaking** to clear scenario/topic/error cleanly. |
| **W6** | `[APP]` | `VocabularyScreen` swallowed add/load errors silently, popped the Add Word dialog before awaiting save, and stayed on `userId = 'anonymous'` when unauthenticated. | `d0ed38c`: Ensures `auth.initialize()` when `'anonymous'`, awaits `addVocabulary()` + `_loadVocabulary()` before dismissing dialog, preserves text & displays SnackBar/dialog errors on failure, and shows Retry on load failure. |

---

## 2. Manual Action Required for Groq Server Voices

See [`workfix/NEEDS_FROM_USER.md`](file:///F:/Speakaboo/workfix/NEEDS_FROM_USER.md):
- `canopylabs/orpheus-v1-english` returns `400 model_terms_required` on all 6 voices until the org admin accepts the Orpheus model terms in the Groq Console.
- Until accepted, the backend marks `audio_unavailable: true` cleanly and the Flutter app speaks replies and previews automatically via on-device `flutter_tts`. Once accepted, Groq Orpheus voices activate automatically with zero code changes.

---

## 3. Verification Results (Fresh Runs After Final Changes)

1. **`powershell -ExecutionPolicy Bypass -File scripts/verify_all.ps1`** — **PASS (exit 0)**:
   - Backend `pytest`: **178 passed** (`178 passed, 1 warning in 4.72s`)
   - `dart analyze lib test`: **0 issues**
   - `flutter test --no-pub --reporter expanded`: **59 passed, 0 failed**
   - `scripts/check_docs.py`: **PASSED** (all docs, module paths, API routes, and error checks valid)
2. **`backend/scripts/e2e_real.py --base-url http://127.0.0.1:8000`** (against live detached `uvicorn` + real `.env` Groq key) — **19/19 checks PASSED (exit 0)**:
   - Health, Device Auth + Profile, Characters list, Honest Orpheus terms block check (`502` fallback signal), Topics (3), Scenarios (5)
   - **8/8 consecutive Talk turns** (`/api/conversation/stream-turn`): real STT transcripts + coherent contextual Qwen LLM replies + `audio_unavailable=True`
   - Vocabulary add + list (`POST` + `GET`)
   - Real Shadowing (`/api/learning/shadowing/evaluate-audio`):
     - Target passage -> `100.0%`, `158.7 WPM`
     - Wrong/unsafe speech (`"I kill people"`) -> `0.0%`, `0.0 WPM`
     - Silence (`2.0s`) -> `0.0%`, `0.0 WPM`
3. **`backend/scripts/probe_providers.py`**:
   - `/models`: `200` (`11` models)
   - `whisper-large-v3-turbo` STT: `200`
   - `qwen/qwen3.8-27b`, `openai/gpt-oss-120b`, `openai/gpt-oss-20b` (`max_tokens=512`): `200` with valid Speakaboo JSON prompt (`qwen3.8-27b` transient `429` handled by configured fallback chain)
   - `canopylabs/orpheus-v1-english`: `400 model_terms_required` (documented in `NEEDS_FROM_USER.md`)

---

## 4. Next Step on Your Phone

Follow the 10-minute verification walkthrough in [`workfix/PHONE_TEST.md`](file:///F:/Speakaboo/workfix/PHONE_TEST.md).
