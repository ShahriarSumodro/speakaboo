# Speakaboo — Agent Architecture Guide

> Start here before editing any file in `F:\Speakaboo`. Designed so you can locate, understand, and safely modify any feature without scanning the whole repo.

## 1. Repository Layout
- `backend/` — Python FastAPI backend (SQLite + Groq STT/LLM/TTS + Asia/Dhaka timezone rules).
- `app/` — Flutter mobile client (`Provider` state management, `ApiService` HTTP/SSE client, warm 60-30-10 theme).
- `docs/` — Architecture, data flow, module map, API contract, domain rules, decisions, and per-module briefs (`docs/ai/`).
- `scripts/verify_all.ps1` — Runs backend pytest, `dart analyze`, `flutter test`, and `scripts/check_docs.py`.

## 2. How to Run Checks
- **All checks:** `powershell -ExecutionPolicy Bypass -File scripts/verify_all.ps1`
- **Backend tests:** `cd backend; $env:TEST_MODE="true"; C:\Users\User\AppData\Local\Python\bin\python.exe -m pytest tests/ -q --tb=short`
- **Flutter analyze & test:** `cd app; dart analyze lib test; flutter test --no-pub`

## 3. Non-Negotiable Rules
1. **No mocks in product code:** `MockSttProvider`, `MockLlmProvider`, `MockTtsProvider` are strictly for `tests/` or `TEST_MODE=true`. Real providers must fail loudly with clear errors.
2. **No swallowed errors:** Never write `except: pass` or `catch (_) {}`. Log or surface errors.
3. **Layering boundaries:**
   - `backend/engine/`, `backend/models/`, `backend/repositories/`, `backend/providers/` must NEVER import `backend.routes`.
   - `app/lib/models/` and `app/lib/services/` must NEVER import `package:flutter/material.dart`.
4. **API route parity:** Every URL in `app/lib/services/api_service.dart` must match a `@router.*` endpoint in `backend/routes/*.py` (verified by `scripts/check_docs.py`).
5. **Asia/Dhaka timezone (`UTC+6`):** All streaks, daily caps, missions, and Leitner review dates use `dhaka_today()` / `dhaka_date_add()`.
6. **TTS 200-char limit:** Groq Orpheus (`canopylabs/orpheus-v1-english`) rejects >200 chars; always split text via `ConversationEngine._split_text(..., max_chars=200)`.

## 4. Key Docs
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System architecture & layer boundaries
- [docs/DATA_FLOW.md](docs/DATA_FLOW.md) — Turn pipeline (sync + SSE), auth, payments
- [docs/MODULE_MAP.md](docs/MODULE_MAP.md) — Where every feature lives
- [docs/API_CONTRACT.md](docs/API_CONTRACT.md) — All backend endpoints & Flutter client methods
- [docs/DOMAIN_RULES.md](docs/DOMAIN_RULES.md) — Pedagogical, safety, billing, and retention rules
- [docs/CHANGE_CHECKLIST.md](docs/CHANGE_CHECKLIST.md) — Before-you-commit checklist
