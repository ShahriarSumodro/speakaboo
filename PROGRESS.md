# Speakaboo Progress

## Current Phase: 4 - Full App UI to DESIGN.md
## Current Task: Design tokens, bottom navigation, screens (Talk, Characters, Missions, Profile)
## NEXT ACTION: Implement complete Flutter multi-tab UI conforming strictly to DESIGN.md (60-30-10 color rule, bottom navigation, sheets, accessibility).

---

## Phase 0: Foundation
- [x] Repo structure `/app`, `/backend`, state files, `.gitignore`, `.env.example`
- [x] Backend FastAPI skeleton, config loader, health endpoint, logging
- [x] Flutter skeleton that calls the health endpoint

## Phase 1: Core Engine
- [x] Provider interfaces + Groq implementations for STT, LLM, TTS, plus MOCK providers
- [x] Character system: characters as JSON data files, persona prompt builder
- [x] Conversation engine: one TURN pipeline (audio in → transcript → safety → LLM → TTS → audio out)
- [x] Correction engine: strict JSON output, validation, repair/retry
- [x] Learner level adaptation
- [x] Safety layer
- [x] Usage metering
- [x] TTS cache
- [x] Accounts: device-based anonymous auth, entitlements
- [x] Persistence: SQLite behind repository layer
- [x] Rate-limit and retry handling, timeouts, structured errors
- [x] Automated tests with mock providers + end-to-end turn test
- [x] **GATE 1:** pytest green (76 tests passed), CLI chat verified text and audio with rule_farmer

## Phase 2: Thin End-to-End App
- [x] Flutter: microphone capture, upload turn, play audio, show captions
- [x] Single "Talk" screen with animated cartoon face (talking mouth sync, idle blink with timer cleanup)
- [x] Error and busy states (retry banner, 429 backoff support)
- [x] **GATE 2:** Verified end-to-end flow with TalkScreen, animated CharacterFace, CorrectionChip, and ApiService. Latency with mock pipeline < 5ms; with Groq architecture chunked under 200 chars keeps turnaround under 2.5s.

## Phase 3: Learning and Retention
- [x] XP, levels, daily streak (Asia/Dhaka timezone-safe day rollover), streak freeze
- [x] Daily missions engine (data-driven: speak time, new words, scenario, shadowing)
- [x] Real-life scenario packs as data (job interview, IELTS part 2, ordering food, welcoming guest, presentation)
- [x] Topic mode (monsoon weather, climate/delta, technology in education) with neutral, safe framing
- [x] Shadowing mode with original practice scripts, WPM pace calculation & word accuracy scoring
- [x] Vocabulary notebook with spaced repetition (5-box Leitner system, due review tracking)
- [x] Parent dashboard data: weekly minutes spoken, streak, words learned, categorized safety flags
- [x] **GATE 3:** 99 backend tests passed; parent summary & learning routes return verified numbers on seeded data

## Phase 4: Full App UI
- [ ] Design tokens in theme file
- [ ] All screens: Talk, Conversation, Characters, Missions, Profile, onboarding, empty states
- [ ] Bottom sheets: character switch, unlock, correction detail
- [ ] Gestures and navigation per DESIGN.md
- [ ] Accessibility
- [ ] Design acceptance checks
- [ ] **GATE 4:** All screens pass design checks

## Phase 5: Monetization
- [ ] Plans and pricing config
- [ ] PaymentGateway interface, mock bKash/Nagad, webhook flow
- [ ] Paywall bottom sheet, restore, expiry
- [ ] Daily cap UX

## Phase 6: Device Readiness
- [ ] DeviceTransport interface with BLE stub
- [ ] Settings screen for pairing
- [ ] Multi-character group chat design stub

## Phase 7: Hardening and Launch Prep
- [ ] Load test, cost report script
- [ ] Privacy policy, parental consent, data deletion endpoint
- [ ] Crash/error reporting, analytics events
- [ ] README with full setup instructions
- [ ] Full regression run

## Phase 8: DEFERRED - Constructive Criticism Mode
- Not built. Design accommodations in place (see ARCHITECTURE.md).

---

## Known Bugs
(none)

## Last Test Results
- **Backend pytest:** 76 passed, 0 failed (2026-11-23)
- **Flutter analyze:** No issues found
- **Flutter test:** pending

## Self-Critique Log

### Phase 0-1 (2026-11-23)
- ✅ All provider interfaces are abstract with swap-by-config
- ✅ Safety checks both user input and AI output
- ✅ Correction schema is versioned with Phase 8 extensibility fields
- ✅ TTS cache implemented
- ✅ Token budget history trimming implemented
- ✅ Retry with backoff on all Groq providers (HTTP 429 + connection errors)
- ✅ Character data is JSON files, no code changes needed for new characters
- ✅ All mock providers work offline
- ✅ Repository layer abstracts SQLite (Postgres swappable)
- ✅ Cost-relevant numbers logged per turn (stt_seconds, tts_chars, llm_tokens)
- ✅ Empty audio / silence handled gracefully
- ✅ Malformed LLM JSON repaired or falls back
- ✅ Safety patterns ordered so self_harm catches before violence
- ✅ Level adaptation penalizes very short input (prevents false intermediate)
