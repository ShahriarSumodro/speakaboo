# Speakaboo — API Contract

All REST and SSE endpoints exposed by `backend/routes/*.py` and consumed by `app/lib/services/api_service.dart`.

## Health & Debug
- `GET /health` — Server + provider health (`ok` / `degraded`)
- `GET /api/debug/last_turns` — Last 20 turn diagnostics (timings, errors, costs)

## Auth & Profile (`/api/auth`)
- `POST /api/auth/device` — Register/login device, returns `user_id`, `token`, `auth_token`, `profile`
- `GET /api/auth/profile` — Get authenticated user's profile
- `PUT /api/auth/profile` — Update profile fields
- `POST /api/auth/set-parent-pin` — Set 4-6 digit parent PIN
- `POST /api/auth/verify-parent-pin` — Verify parent PIN

## Characters (`/api/characters`)
- `GET /api/characters/` — List all characters
- `GET /api/characters/{character_id}` — Get character details
- `GET /api/characters/{character_id}/preview-audio` — Synthesize or return cached greeting WAV

## Conversation (`/api/conversation`)
- `POST /api/conversation/start` — Start/resume conversation (enforces locked character 2-min trial)
- `POST /api/conversation/turn` — Synchronous multipart turn (`conversation_id`, `audio`, `audio_format`)
- `POST /api/conversation/stream-turn` — SSE streaming turn (`transcript`, `reply_start`, `audio_chunk`, `tts_error`, `error`, `turn_complete`)
- `POST /api/conversation/hint` — Sentence starter, model answer, vocabulary hints
- `POST /api/conversation/summary` — End-of-session coaching metrics & tomorrow hook
- `POST /api/conversation/placement` — Spoken CEFR placement evaluation (A1-B2)
- `GET /api/conversation/mistakes/{user_id}` — Top recurring mistake patterns

## Learning, Gamification, Vocabulary, Shadowing (`/api/learning`)
- `GET /api/learning/progress/{user_id}` — XP, level, current/longest streak, freezes
- `POST /api/learning/freeze/{user_id}` — Add streak freeze
- `POST /api/learning/streak/repair` — Repair lost streak
- `GET /api/learning/missions/{user_id}` — Daily missions
- `POST /api/learning/missions/{user_id}/claim/{mission_id}` — Claim completed mission XP
- `GET /api/learning/scenarios` / `GET /api/learning/scenarios/{scenario_id}` / `POST /api/learning/scenarios/{scenario_id}/complete/{user_id}`
- `GET /api/learning/topics` / `GET /api/learning/topics/{topic_id}`
- `GET /api/learning/shadowing` & `GET /api/learning/shadowing/scripts` — List scripts
- `POST /api/learning/shadowing/evaluate` — Evaluate transcript + duration vs target script
- `GET /api/learning/vocabulary/{user_id}` — Full vocabulary notebook
- `GET /api/learning/vocabulary/{user_id}/due` — Due Leitner review cards
- `POST /api/learning/vocabulary/{user_id}` — Add word/phrase
- `POST /api/learning/vocabulary/{user_id}/review/{item_id}` — Submit review (`remembered: bool`)
- `GET /api/learning/word-of-the-day` — Daily word with Bengali meaning
- `GET /api/learning/weekly-recap/{user_id}` — 7-day recap
- `GET /api/learning/referral/{user_id}` / `POST /api/learning/referral/claim`

## Usage (`/api/usage`)
- `GET /api/usage/{user_id}/daily` — Daily spoken minutes, turns, limit, remaining

## Payments (`/api/payment`)
- `GET /api/payment/plans` — Available plans & pricing
- `POST /api/payment/checkout` — Create payment intent
- `POST /api/payment/verify` — Idempotent payment verification + entitlement grant
- `POST /api/payment/webhook` — Asynchronous gateway webhook
- `POST /api/payment/manual-verify` — Manual TrxID verification (globally unique TrxID)
- `GET /api/payment/entitlements/{user_id}` — Active entitlements
- `GET /api/payment/restore/{user_id}` — Restore active entitlements

## Parent & Privacy (`/api/parent`, `/api/privacy`)
- `GET /api/parent/{user_id}/summary` — Weekly minutes, streak, XP, words, safety flag counts
- `GET /api/parent/{user_id}/safety-flags` — Recent safety flag incidents
- `GET /api/privacy/policy` — Privacy policy markdown
- `GET /api/privacy/parental-consent` — Parental consent markdown
- `GET /api/privacy/export/{user_id}` — Full JSON data export (`raw_audio_stored: false`)
- `DELETE /api/privacy/user/{user_id}` — Irreversible full user purge
