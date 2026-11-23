# Speakaboo Progress

## Current Phase: 0 - Foundation
## Current Task: Repo structure, state files, .gitignore, .env.example
## NEXT ACTION: Create backend FastAPI skeleton with config loader, health endpoint, and logging.

---

## Phase 0: Foundation
- [x] Repo structure `/app`, `/backend`, state files, `.gitignore`, `.env.example`
- [ ] Backend FastAPI skeleton, config loader, health endpoint, logging
- [ ] Flutter skeleton that calls the health endpoint

## Phase 1: Core Engine
- [ ] Provider interfaces + Groq implementations for STT, LLM, TTS, plus MOCK providers
- [ ] Character system: characters as JSON data files, persona prompt builder
- [ ] Conversation engine: one TURN pipeline (audio in → transcript → safety → LLM → TTS → audio out)
- [ ] Correction engine: strict JSON output, validation, repair/retry
- [ ] Learner level adaptation
- [ ] Safety layer
- [ ] Usage metering
- [ ] TTS cache
- [ ] Accounts: device-based anonymous auth, entitlements
- [ ] Persistence: SQLite behind repository layer
- [ ] Rate-limit and retry handling, timeouts, structured errors
- [ ] Automated tests with mock providers + end-to-end turn test
- [ ] **GATE 1:** pytest green, CLI chat works with text and audio

## Phase 2: Thin End-to-End App
- [ ] Flutter: microphone capture, upload turn, play audio, show captions
- [ ] Single "Talk" screen with animated cartoon face
- [ ] Error and busy states
- [ ] **GATE 2:** Speak and hear character answer on device/emulator

## Phase 3: Learning and Retention
- [ ] XP, levels, daily streak (Asia/Dhaka timezone)
- [ ] Daily missions engine
- [ ] Real-life scenario packs
- [ ] Topic mode
- [ ] Shadowing mode
- [ ] Vocabulary notebook with spaced review
- [ ] Parent dashboard data
- [ ] **GATE 3:** Tests green, metrics endpoints correct

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
(none yet)

## Last Test Results
(not yet run)

## Self-Critique Log
(entries added per task)
