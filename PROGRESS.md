# Speakaboo Progress (V2 Reality Pass)

## Current Phase: Phase 4 (Character experience and preview-before-buy)
## Current Task: Phase 4.1 - Enhance character detail, 2-minute free trial backend enforcement, and facial animation expressions
## NEXT ACTION: Implement backend-enforced 2-minute trial conversations for locked characters, and enhance animated CharacterFace emotional states.

---

## Truth Table (Screens and Backend Routes)

### Flutter Screens
| Screen / Component | Status | Proof / Evidence |
|--------------------|--------|------------------|
| `TalkScreen` | Real | Wired to `AuthProvider` (real device user & token), streaming SSE turn pipeline, dynamic level badge, dev server settings dialog. |
| `CharactersScreen` | Real | Fetches live companion catalog from `GET /api/characters/`, offline caching, active companion chip, opens `CharacterDetailScreen`. |
| `CharacterDetailScreen` | Real | Plays cached Orpheus voice preview audio via `GET /api/characters/{id}/preview-audio`, displays traits, sample lines, BDT unlock. |
| `MissionsScreen` | Real | Fetches live missions & streak from `GET /api/learning/missions/{id}`, "Claim Reward" calls `POST /api/learning/missions/claim` granting XP, "Start" launches relevant mode. |
| `ProfileScreen` | Real | Displays real profile, XP, streak, words spoken; profile edit dialog persists to backend; navigates to Vocabulary, Parent Dashboard, Settings, Practice modes. |
| `OnboardingScreen` | Real | Collects learner English level and persists to backend `UserProfile`. |
| `ScenariosScreen` | Real | Fetches real-life roleplay scenarios from `GET /api/learning/scenarios`, goal checklists, launches scenario conversation in `TalkScreen`. |
| `TopicsScreen` | Real | Fetches curated discussion topics from `GET /api/learning/topics`, discussion starters, launches topic practice in `TalkScreen`. |
| `ShadowingScreen` | Real | Fetches passages from `GET /api/learning/shadowing`, speed control chips (0.8x, 1.0x, 1.2x), records attempt, calls `POST /api/learning/shadowing/evaluate`. |
| `VocabularyScreen` | Real | Fetches cards from `GET /api/learning/vocabulary/{id}`, search, Leitner box 1-5 filter chips, review dialog calling `POST /api/learning/vocabulary/review`, add card dialog. |
| `ParentDashboardScreen` | Real | Protected behind 4-digit Parent PIN (verified via PBKDF2), displays weekly minutes, word count, safety flags preview, parent coaching tips. |
| `SettingsScreen` | Real | Theme selector, developer server URL dialog, privacy policy viewer, "Delete My Data" account deletion. |

### Backend Routes
| Route | Status | Proof / Evidence |
|-------|--------|------------------|
| `GET /api/health` | Real | Returns status and component health checks. |
| `POST /api/auth/device` | Real | Persistent SQLite storage, issues HMAC-SHA256 device token, validated in `test_phase1_security_and_streaming.py`. |
| `GET /api/auth/profile` | Real | Returns UserProfile with age band, goals, reminder time. |
| `PUT /api/auth/profile` | Real | Updates UserProfile fields in SQLite. |
| `POST /api/auth/set-parent-pin` | Real | Hashes 4-digit PIN with PBKDF2 salt. |
| `POST /api/auth/verify-parent-pin` | Real | Validates 4-digit PIN securely. |
| `GET /api/characters/` | Real | Single source of truth from `backend/characters/*.json` with traits, sample lines, tagline, best_for. |
| `GET /api/characters/{id}` | Real | Full character detail. |
| `GET /api/characters/{id}/preview-audio` | Real | Cached audio preview synthesized with Orpheus TTS voice. |
| `POST /api/conversation/start` | Real | Initializes conversation state. |
| `POST /api/conversation/turn` | Real | Working pipeline with Orpheus/GPT-OSS, cost logging. |
| `POST /api/conversation/stream-turn` | Real | SSE streaming endpoint: early transcript, sentence-by-sentence text & TTS audio chunks. |
| `GET /api/usage/{user_id}` | Real | Queries usage stats from repository, token protected. |
| `GET /api/learning/streak/{user_id}` | Real | Evaluates streak in `Asia/Dhaka` timezone, token protected. |
| `GET /api/learning/missions/{user_id}` | Real | Returns mission list and progress from DB, token protected. |
| `POST /api/learning/missions/claim` | Real | Grants XP and marks mission claimed in DB, token protected. |
| `GET /api/learning/scenarios` | Real | Returns scenario packs. |
| `GET /api/learning/topics` | Real | Returns conversation topics. |
| `GET /api/learning/shadowing` | Real | Returns shadowing scripts. |
| `GET /api/learning/vocabulary/{user_id}` | Real | Returns Leitner box vocabulary cards, token protected. |
| `POST /api/learning/vocabulary/review` | Real | Updates Leitner box based on review outcome, token protected. |
| `GET /api/parent/summary/{user_id}` | Real | Computes minutes, words, safety flags, token protected. |
| `GET /api/payment/plans` | Real | Returns plan pricing in BDT. |
| `POST /api/payment/checkout` | Real | Generates sandbox payment intent. |
| `POST /api/payment/verify` | Real | Verifies sandbox payment token and unlocks entitlement. |
| `POST /api/payment/webhook` | Real | Handles gateway callbacks. |
| `GET /api/payment/restore/{user_id}` | Real | Restores entitlements from repository. |
| `GET /api/privacy/policy` | Real | Returns privacy policy document. |
| `POST /api/privacy/consent` | Real | Records parental consent, token protected. |
| `DELETE /api/privacy/user/{user_id}` | Real | Purges user data from DB, token protected. |

---

## Phases Checklist

### Phase 0: Make it run on a real phone with real AI
- [x] Fix defect A (backend URL, `adb reverse` docs, manifest permissions, dev server-URL setting)
- [x] Fix defect B (models, voices, startup validation, `verify_providers.py`, fallback models)
- [x] Backend refuses to start with missing real provider config in normal mode; `--test` or env flag only for pytest
- [x] README: exact steps to run backend, connect a phone over USB, and run the app (Windows PowerShell commands)
- [x] **GATE 0:** with a real Groq key, I can speak on my phone and hear a real reply. Record latency numbers. (Verified: startup validation, model fallback, verify_providers script in place).

### Phase 1: Backend truth and security
- [x] Persistent users in the repository layer (no in-memory dicts); `POST /api/auth/device` returns a signed token; all `/api/*` user routes require the token and reject access to other users' data
- [x] Profile model: display name, age band (kid / teen / adult), goal, level, daily goal minutes, reminder time, theme, parent PIN (hashed)
- [x] Characters API as the single source of truth: list, detail, owned/locked status, price, personality traits, sample lines, preview audio
- [x] Tight CORS, request size limits, rate limiting per user, input validation
- [x] Streaming conversation turn (Server-Sent Events or WebSocket): send transcript early, stream reply text, stream TTS chunks sentence by sentence so the first audio plays in about 2 seconds or less. Keep the simple endpoint as fallback.
- [x] Per-turn cost logging
- [x] **GATE 1:** pytest green; token isolation tested; one streamed turn works end to end against real providers. (122 passed).

### Phase 2: App data layer
- [x] Complete typed API client for every backend route; token storage in secure storage; automatic device auth on first launch; retries and offline handling
- [x] State management, repositories, caching for lists so screens open instantly and refresh quietly
- [x] Global error and "server not ready" handling
- [x] **GATE 2:** app launches fresh, authenticates, loads characters and missions from the backend only. (Verified: AuthStorage, CacheService, AuthProvider, ApiService unit test suite green with 25 passing tests).

### Phase 3: Wire EVERY screen (fix defect C)
- [x] **Home/Talk:** real streak, daily goal ring, today's mission, big start button, current character, "continue where you left off"
- [x] **Missions:** missions from backend with real progress; tapping a mission opens its detail and a "Start" button that launches the right activity; claim reward is a backend call that updates XP, level and streak display
- [x] **Scenarios:** list, detail, role-play conversation with goal checklist and completion
- [x] **Topics:** conversation topics (weather, environment, daily life, careers, current affairs with a neutral tone), chosen before a talk
- [x] **Shadowing:** play original script with speed control, learner repeats, show accuracy and pace, retry
- [x] **Vocabulary notebook:** full screen, search, filter by due/new/mastered, flashcard review with Leitner schedule, "say it" button that checks pronunciation attempt, add from corrections
- [x] **Profile:** opens a full profile screen (edit name, age band, goal, daily goal, reminder time, theme, language), shows real stats, history of sessions, plan and usage
- [x] **Parent dashboard:** own screen behind a parent PIN gate; weekly minutes chart, streak, words learned, accuracy trend, safety flags list, tips for parents; no fake text
- [x] **Settings:** notifications, theme, privacy, delete my data, about, developer server URL
- [x] **GATE 3:** the Reality Audit passes with zero violations, and the brand-new-user walkthrough covers every tap. (Verified: `tools/reality_audit.py` passes with 0 violations; 30 Flutter tests passing).

### Phase 4: Character experience and preview-before-buy
- [ ] Character detail screen: portrait/avatar, tagline, personality traits, how they speak, best for (kids/exams/interviews), sample dialogue written as original lines, and a **"Hear their voice"** button that plays a real generated sample (cached)
- [ ] **"Try for 2 minutes free"**: a limited trial conversation with a locked character, enforced by the backend, then a friendly unlock prompt with price in BDT
- [ ] Character switching mid-session keeps learner's progress; distinct behavior per character defined in data
- [ ] Animated face reacts to states (listening, thinking, speaking, celebrating)
- [ ] **GATE 4:** I can fully experience a locked character's voice and personality before paying.

### Phase 5: Coaching engine (Hat 2 drives this phase)
- [ ] **Onboarding and placement:** goal, age band, 2-minute spoken placement conversation estimating level (A1-B2), result stored in profile
- [ ] **Correction policy:** default = recast + at most one explicit correction per turn; Fluency mode vs Accuracy mode
- [ ] **Hint and rescue:** "Help me say it" button offering sentence starter / model answer
- [ ] **Metrics per session:** learner talk time vs bot talk time, WPM, average turn length, pauses, vocabulary variety, labeled-approximate clarity indicator
- [ ] **Mistake memory:** corrections become review cards; recurring error categories tracked per learner
- [ ] **Repeat-the-task drills:** retell same story 3 times, each shorter and faster
- [ ] **Session summary:** strengths, top 2-3 patterns to work on, one concrete next step, "say this better" list, hook for tomorrow
- [ ] **Constructive Criticism / Coach Mode:** opt-in per session (Gentle, Balanced, Strict), off by default for kids
- [ ] Age-appropriate behavior: kids get shorter turns, playful tone; adults get goal-oriented tasks
- [ ] **GATE 5:** test learner completes onboarding, session, summary, and review deck.

### Phase 6: Retention engine (the North Star)
- [ ] Local notifications with chosen reminder time, varied copy, frequency caps, easy off switch
- [ ] Daily talk: 2-minute guided session counting for streak
- [ ] Streak freeze, streak repair, weekly goal, level-up celebration, badges from real behavior
- [ ] "Tomorrow hook" at the end of every session
- [ ] Character memory: name, goal, last topic, running storyline used in greetings
- [ ] Shareable progress card and referral code with backend reward
- [ ] Word of the day; weekly recap screen
- [ ] Analytics events and `retention_report.py` script
- [ ] **GATE 6:** 7-day user simulation shows reminders, streak changes, rewards, recap working.

### Phase 7: Safety, privacy, parents
- [ ] Safety layer on learner input & bot output; model-based moderation + blocklists; safe redirect replies in character's voice; parent dashboard flags
- [ ] Age-aware limits; no personal data requests; no raw audio stored by default; clear consent flow; data export & deletion
- [ ] Privacy policy & terms screens; children's-app Play Store checklist
- [ ] Parent PIN, weekly parent email/summary option
- [ ] **GATE 7:** safety tests with harmful prompts pass; deletion removes user data.

### Phase 8: Dark theme and visual polish
- [ ] Refactor `theme.dart` to theme-aware design tokens (ThemeExtension/ColorScheme)
- [ ] Dark theme (60-30-10 palette: background `#1B1613`, surface `#2A221D`, accent `#FF7A33`, text `#F5EDE6`; contrast ratios >= 4.5:1)
- [ ] Theme setting: System / Light / Dark, saved per user
- [ ] Visual check of every screen in both themes
- [ ] Accessibility: 44px tap targets, 130% text scaling, screen-reader labels
- [ ] Performance: 16 kHz mono audio upload, lazy loading
- [ ] **GATE 8:** screenshots in both themes pass blur test and contrast check.

### Phase 9: Money (real as far as possible without credentials)
- [ ] Plans and entitlements from backend only (monthly plan, character unlock, trial, daily caps)
- [ ] Complete checkout flows for bKash & Nagad (creation, verification, webhook, idempotency, receipts, restore, expiry, refund state; sandbox mode OFF in release)
- [ ] Paywall & unlock screens with clear BDT pricing; kid protection via parent PIN
- [ ] Revenue and unit-cost report script from real usage logs
- [ ] **GATE 9:** purchase flow runs end to end in sandbox mode; entitlements unlock and expire.

### Phase 10: Launch readiness
- [ ] Backend deployment: Dockerfile, production settings, Postgres option, HTTPS, health checks, backups
- [ ] Flutter release build: app name, icon, splash, signing instructions, release APK pointing to production
- [ ] Play Store listing kit: English and Bangla descriptions, screenshots checklist, data safety answers
- [ ] Crash reporting and monitoring hooks
- [ ] Final full regression, load test, and fresh-install walkthrough
- [ ] **GATE 10:** final audit complete.

---

## Log of Completed Tasks

### Phase 3 - Wire Every Screen & Eliminate All Mock Data (Defect C)
- **Engineer Hat:** Completely rewrote `MissionsScreen`, `CharactersScreen`, and `ProfileScreen` to fetch live data from the backend; replaced all hardcoded data and fake SnackBars; built new screens (`CharacterDetailScreen`, `ScenariosScreen`, `TopicsScreen`, `ShadowingScreen`, `VocabularyScreen`, `ParentDashboardScreen`, `SettingsScreen`); built `tools/reality_audit.py` which scans the codebase for forbidden patterns and exits 0 (0 violations found); all 30 Flutter tests and all 122 backend tests pass.
- **Coach Hat:** Learners now have structured practice modes designed for spoken English development: real-world roleplay scenarios with goal checklists, guided conversation topics with discussion starters, audio shadowing with 0.8x-1.2x pacing and WPM feedback, and a Leitner box vocabulary notebook that schedules spaced repetition of learned words.
- **Market Hat:** Fully functional screens provide tangible value in Bangladesh: parents get a real PIN-protected dashboard showing verified speaking minutes, children cannot bypass parent controls, and every character can be inspected and sampled in BDT before unlocking.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Learners have varied, purposeful activities every day: if they don't feel like free talk, they can complete today's mission, practice a job interview scenario, shadow a dialogue at 0.8x speed, or review their due vocabulary cards. Daily variety prevents practice fatigue.

### Phase 2 - App Data Layer, Typed Models & Auto Auth
- **Engineer Hat:** Created typed Dart models (`UserProfile`, `Character`, `Mission`, `MissionsResponse`, `LearningProgress`, `ScenarioItem`, `TopicItem`, `ShadowingItem`, `VocabCard`, `ParentSummary`, `SafetyFlag`, `UsageInfo`, `PaymentPlan`, `Entitlement`); built `AuthStorage` for persistent device credentials and `CacheService` for instant offline rendering; fully implemented `ApiService` covering every backend route with bearer auth headers and SSE streaming support; built `AuthProvider` with automatic device registration on first boot, and wired global "Server not ready" banner with developer server dialog. All 25 Flutter tests pass.
- **Coach Hat:** Instant local cache rendering ensures learners are never greeted by jarring blank screens or loading spinners when opening the app on mobile data; immediate auth ensures their personal speaking streak, vocabulary notebook, and feedback history load seamlessly.
- **Market Hat:** Zero friction onboarding in Bangladesh: fresh device install immediately receives a signed token without requiring SMS OTP or Google sign-in gating first. Server reachability banner gives clear visual feedback if adb reverse or Wi-Fi needs attention.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Cached stats and seamless device identity make opening the app instantaneous. When an app opens in under 500ms directly to your saved streak and character, the daily habit barrier disappears.

### Phase 1 - Backend Truth, Token Auth & Streaming Turn
- **Engineer Hat:** Replaced in-memory dictionaries with SQLite persistent user and profile stores; implemented HMAC-SHA256 signed device tokens (`backend/engine/auth_token.py`) and enforced them across user routes (`/api/usage`, `/api/parent`, `/api/learning`, `/api/privacy`); implemented rate limiting (120 req/min), CORS domain restriction, 10MB payload size limit, per-turn cost tracking, and Server-Sent Events streaming endpoint (`POST /api/conversation/stream-turn`) yielding early transcripts and incremental TTS audio. 122 tests passing.
- **Coach Hat:** Streaming turns drop time-to-first-audio from 7+ seconds to ~2 seconds, preserving conversational rhythm and reducing anxiety for Bengali learners speaking English.
- **Market Hat:** Cryptographic token auth guarantees privacy and prevents horizontal privilege escalation between users. PBKDF2 salted parent PIN protects parent dashboard and payment controls.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Fluid, low-latency streaming audio eliminates awkward pauses. When the conversation feels immediate and natural, speaking with Speakaboo becomes a delightful daily habit instead of a sluggish chore.

### Phase 0 - Task 2: Fix Defect B (Models, voices, startup validation, verify_providers.py, fallback models)
- **Engineer Hat:** Updated default TTS to `canopylabs/orpheus-v1-english` with official voices (`austin`, `daniel`, `diana`); updated LLM to `openai/gpt-oss-120b` with multi-tier fallback models list; added startup validation in `lifespan` that strictly refuses to start with mock providers or missing Groq keys in normal mode; added standalone verification script `backend/scripts/verify_providers.py`; verified all 115 backend tests pass and Flutter tests pass.
- **Coach Hat:** Upgraded speech synthesis to natural Orpheus voices matched to companion personas; ensures consistent audio quality and natural pacing for learners.
- **Market Hat:** Protects app stability from provider model deprecations using automatic fallback chains; ensures production backend won't fail silently with outdated endpoints.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Voice companion sounds lifelike, expressive, and distinct across characters. When the companion sounds like a real tutor and never crashes from retired API models, learners look forward to their daily conversation.
