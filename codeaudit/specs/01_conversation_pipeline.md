# Spec 01: Conversation Turn Pipeline (`backend/engine/conversation.py`)

## Purpose
Orchestrates a single user-AI speaking turn:
1. Audio in -> STT transcription (`SttProvider.transcribe`)
2. If STT fails or returns empty transcript -> return friendly retry message (no crash, no history mutation).
3. User safety check (`check_content_safety(..., is_user_message=True, age_band=state.age_band)`).
   - If blocked -> return/stream character-voiced redirect message + TTS audio (best-effort; TTS failure must not crash safety redirect).
4. Estimate learner level (`estimate_level(state.user_transcripts)`).
5. Build system prompt + trimmed history (within `MAX_HISTORY_TOKENS * CHARS_PER_TOKEN` chars).
6. Call LLM (`LlmProvider.chat(..., json_mode=True)`) up to `max_llm_retries` times, parsing JSON with `parse_turn_response()`.
   - If all attempts fail -> fallback reply `"Good try! Let's keep practicing."` (in `process_turn`) or error event / fallback (in `stream_turn`).
7. AI reply safety check (`check_content_safety(response.reply, is_user_message=False)`).
   - If `SafetyError` raised -> replace with safe fallback reply.
8. TTS synthesis (`TtsProvider.synthesize`) in <=200-char sentence chunks, cached by `"{voice_id}:{chunk}"`.
   - If TTS fails -> log error, set `tts_error`, still return text reply (do not crash or swap in mock audio).
9. Update `ConversationState` (history, turn_count, word counts, speech seconds, corrections, new words, timestamps) and record turn diagnostics in `_last_turns`.

## Invariants
- Both `process_turn` and `stream_turn` must catch STT, LLM, and TTS provider errors gracefully without crashing.
- History trimming keeps total character length <= `MAX_HISTORY_TOKENS * CHARS_PER_TOKEN` (unless a single message exceeds it) and drops oldest pairs first.
- Text splitting produces chunks <= `max_chars` (200) breaking at `.`, `!`, `?`, then space.
