# Speakaboo — Data Flow

## 1. Conversation Turn (SSE Streaming & Blocking Fallback)
```
User taps mic -> TalkScreen -> ConversationProvider.startRecording() -> AudioService
User stops mic -> ConversationProvider.stopRecordingAndSend()
  ├── Primary: ApiService.streamTurn() -> POST /api/conversation/stream-turn (SSE)
  │     Backend ConversationEngine.stream_turn():
  │       1. SttProvider.transcribe(audio) -> emits `transcript` (or `error` on failure)
  │       2. check_content_safety(user_text) -> if blocked, emits `safety` + `audio_chunk` + `turn_complete`
  │       3. estimate_level(user_transcripts) + build_system_prompt()
  │       4. LlmProvider.chat(json_mode=True) + parse_turn_response() (up to 2 retries on bad JSON)
  │       5. check_content_safety(reply, is_user_message=False)
  │       6. emits `reply_start`
  │       7. _split_text(reply, 200) -> TtsProvider.synthesize() per chunk (cached) -> emits `audio_chunk` (or `tts_error`)
  │       8. _finalize_turn_state() + record_turn_log() -> emits `turn_complete`
  └── Fallback (if SSE throws): ApiService.sendTurn() -> POST /api/conversation/turn
```
After each turn, `routes/conversation.py:_record_turn_metrics()` updates:
- `daily_usage` (minutes + turns) and `character_trials` (if locked character)
- `GamificationEngine.on_turn_completed()` (XP + Asia/Dhaka streak)
- `MissionsEngine.track_speaking_time()` + `track_new_words()`
- `VocabularyEngine.add_from_turn()`
- `MistakeLog` (categorized via `categorize_error()`)

## 2. Authentication & 401 Retry
1. `AuthProvider.initialize()` loads `user_id` + `auth_token` from `AuthStorage`.
2. If missing, calls `POST /api/auth/device` -> backend creates `User` + `UserProfile`, signs HS256 JWT (`create_device_token`), returns `token` + `auth_token`.
3. `ApiService._sendWithAuthRetry()` attaches `Bearer <token>`; on `401`, calls `_refreshDeviceAuth()` once and retries the request.
