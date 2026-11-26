# Spec 14: App State Machines (`app/lib/providers/`)

## Purpose
Manages authentication/connectivity (`AuthProvider`) and turn lifecycle (`ConversationProvider`).

## Rules & Invariants
1. `AuthProvider`:
   - `checkHealth()` probes `/health`; marks `serverConnected = true` on `ok` or `degraded`, else `false` and starts 15s polling timer `_healthTimer`.
   - `initialize()` loads stored userId/token, registers device via `/api/auth/device` if missing, loads cached profile then refreshes from `/api/auth/profile`.
2. `ConversationProvider`:
   - States: `idle`, `ready`, `recording`, `processing`, `playing`, `error`, `busy`.
   - `stopRecordingAndSend()` uses SSE streaming (`_processAudioStreaming`) with automatic fallback to blocking `/api/conversation/turn` (`_processAudioBlocking`) on stream exception.
   - `clearError()` returns to `ready` if `_conversationId != null`, else `idle`.
