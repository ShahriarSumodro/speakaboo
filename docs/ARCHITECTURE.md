# Speakaboo — System Architecture

## Overview
Speakaboo is a voice-first English speaking companion for learners in Bangladesh. It consists of:
1. **Flutter App (`app/lib/`)**: Records learner speech, streams/receives character replies + audio chunks, renders corrections, tracks missions/streaks/vocabulary, and gates parent tools behind a PIN.
2. **FastAPI Backend (`backend/`)**: Orchestrates STT -> Safety -> Level -> LLM -> Correction -> Safety -> TTS, persists state in SQLite (`speakaboo.db`), and exposes REST + SSE endpoints.

## Backend Layers
```
backend/main.py (FastAPI app, CORS, 120 req/min rate limiter, 10MB max upload, crash telemetry)
  └── backend/routes/ (HTTP endpoints, Pydantic schemas, Depends(get_current_user_id))
        ├── backend/engine/ (business logic: conversation, correction, safety, characters, level, gamification, missions, vocabulary, shadowing, experiments, auth_token)
        ├── backend/providers/ (external adapters: groq_stt, groq_llm, groq_tts, payment, mock)
        └── backend/repositories/ (BaseRepository ABC + SqliteRepository with 16 tables, WAL mode)
              └── backend/models/ (dataclasses & enums: user.py, learning.py)
```

## Flutter Layers
```
app/lib/main.dart (MultiProvider + MaterialApp with SpeakabooTheme light/dark)
  └── app/lib/screens/ & app/lib/widgets/ (UI)
        └── app/lib/providers/ (AuthProvider, ConversationProvider)
              └── app/lib/services/ (ApiService, AudioService, AuthStorage, CacheService, BillingProvider)
                    └── app/lib/models/ & app/lib/config/ (AppConfig, SpeakabooColors)
```
