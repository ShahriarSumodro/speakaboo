# Speakaboo Progress

## Current Phase: 6 - Device Readiness
## Current Task: DeviceTransport interface with BLE stub, pairing screen, and multi-character group chat stub
## NEXT ACTION: Implement DeviceTransport interface with BLE stub, Bluetooth pairing screen, multi-character group chat design stub, and ARCHITECTURE.md hardware docs.

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
- [x] Design tokens in theme file (60-30-10 palette: #FBF8F5, #F1E9E1, #F26B21, text #2A211B)
- [x] Screens: Talk, Characters, Missions, Profile, Onboarding, Empty states
- [x] Bottom sheets: character switch, unlock (bKash/Nagad), correction detail
- [x] Gestures and navigation per DESIGN.md: MainShell with 4 bottom navigation tabs, dismissible sheets
- [x] Accessibility: minimum 44px tap targets, readable contrast, scalable typography
- [x] **GATE 4:** All 15 Flutter tests passed, 0 analyzer issues, every screen passes DESIGN.md rules

## Phase 5: Monetization
- [x] Plans: base monthly plan (200 BDT) and per-character unlock (350 BDT) in config
- [x] PaymentGateway interface, mock bKash and Nagad implementations, webhook and verification flow
- [x] Paywall bottom sheet, restore purchases, expiry handling
- [x] Daily cap UX: friendly "come back tomorrow or upgrade" sheet (DailyCapSheet)
- [x] Entitlement enforcement in turn pipeline (blocks locked character practice and enforces daily practice limit)

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
- **Backend pytest:** 105 passed, 0 failed (2026-11-23)
- **Flutter analyze:** No issues found (2026-11-23)
- **Flutter test:** 16 passed, 0 failed (2026-11-23)

## Self-Critique Log

### Phase 5 (2026-11-23)
- ✅ Hard Rule 8 respected: PaymentGateway interface with mock bKash and Nagad implementations. Real merchant integration ready without faking success in production paths.
- ✅ Timeouts and expiration handled: PaymentIntent expires in 15 mins, subscriptions expire in 30 days, character unlocks permanent.
- ✅ DailyCapSheet provides friendly "come back tomorrow or upgrade" UX per DESIGN.md rules (60-30-10 palette, minimum 44px tap targets).
- ✅ Turn endpoint enforces daily cap and character unlock entitlements before running the engine.

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
