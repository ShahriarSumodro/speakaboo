# Speakaboo Progress (V2 Reality Pass)

## Current Phase: Phase 0 (Make it run on a real phone with real AI)
## Current Task: Phase 0.1 - Fix Defect A (Backend URL, adb reverse docs, manifest permissions, dev server-URL setting)
## NEXT ACTION: Implement runtime backend URL config in Flutter, update Android manifests & network security, and verify real phone connectivity setup.

---

## Truth Table (Screens and Backend Routes)

### Flutter Screens
| Screen / Component | Status | Proof / Evidence |
|--------------------|--------|------------------|
| `TalkScreen` | Partial | Talks to `/api/conversation/turn`, but uses hardcoded `'device-user'`, no streaming, no topic/scenario context. |
| `CharactersScreen` | Fake | Hardcoded list in `characters_screen.dart`, wrong IDs (`eco_scholar`), mock unlock SnackBar. |
| `MissionsScreen` | Fake | Hardcoded list in `missions_screen.dart`, reward claim only mutates local in-memory state. |
| `ProfileScreen` | Fake | Hardcoded stats, Vocabulary & Parent Dashboard cards do not navigate to real screens (fake SnackBar). |
| `OnboardingScreen` | Partial | Collects level locally, never persists to profile or runs spoken diagnostic test. |
| `ScenariosScreen` | Missing | Not yet implemented in Flutter. |
| `TopicsScreen` | Missing | Not yet implemented in Flutter. |
| `ShadowingScreen` | Missing | Not yet implemented in Flutter. |
| `VocabularyScreen` | Missing | Not yet implemented in Flutter. |
| `ParentDashboardScreen` | Missing | Not yet implemented in Flutter (only fake SnackBar in Profile). |
| `SettingsScreen` | Missing | Not yet implemented in Flutter. |
| `CharacterDetailScreen` | Missing | Not yet implemented in Flutter. |

### Backend Routes
| Route | Status | Proof / Evidence |
|-------|--------|------------------|
| `GET /api/health` | Real | Returns status and component health checks. |
| `POST /api/auth/device` | Partial | In-memory dicts (`_users`, `_device_to_user`), lost on restart, no signed token. |
| `GET /api/characters/` | Real | Loads real JSON characters from `backend/characters`. |
| `GET /api/characters/{id}` | Real | Loads single character details. |
| `POST /api/conversation/start` | Real | Initializes conversation state. |
| `POST /api/conversation/turn` | Partial | Working pipeline, but blocking HTTP (not streaming) and models/voices were retired. |
| `GET /api/usage/{user_id}` | Real | Queries usage stats from repository. |
| `GET /api/learning/streak/{user_id}` | Real | Evaluates streak in `Asia/Dhaka` timezone. |
| `GET /api/learning/missions/{user_id}` | Real | Returns mission list and progress from DB. |
| `POST /api/learning/missions/claim` | Real | Grants XP and marks mission claimed in DB. |
| `GET /api/learning/scenarios` | Real | Returns scenario packs. |
| `GET /api/learning/topics` | Real | Returns conversation topics. |
| `GET /api/learning/shadowing` | Real | Returns shadowing scripts. |
| `GET /api/learning/vocabulary/{user_id}` | Real | Returns Leitner box vocabulary cards. |
| `POST /api/learning/vocabulary/review` | Real | Updates Leitner box based on review outcome. |
| `GET /api/parent/summary/{user_id}` | Real | Computes minutes, words, safety flags. |
| `GET /api/payment/plans` | Real | Returns plan pricing in BDT. |
| `POST /api/payment/checkout` | Real | Generates sandbox payment intent. |
| `POST /api/payment/verify` | Real | Verifies sandbox payment token and unlocks entitlement. |
| `POST /api/payment/webhook` | Real | Handles gateway callbacks. |
| `GET /api/payment/restore/{user_id}` | Real | Restores entitlements from repository. |
| `GET /api/privacy/policy` | Real | Returns privacy policy document. |
| `POST /api/privacy/consent` | Real | Records parental consent. |
| `DELETE /api/privacy/user/{user_id}` | Real | Purges user data from DB. |

---

## Phases Checklist

### Phase 0: Make it run on a real phone with real AI
- [ ] Fix defect A (backend URL, `adb reverse` docs, manifest permissions, dev server-URL setting)
- [ ] Fix defect B (models, voices, startup validation, `verify_providers.py`, fallback models)
- [ ] Backend refuses to start with missing real provider config in normal mode; `--test` or env flag only for pytest
- [ ] README: exact steps to run backend, connect a phone over USB, and run the app (Windows PowerShell commands)
- [ ] **GATE 0:** with a real Groq key, I can speak on my phone and hear a real reply. Record latency numbers.

### Phase 1: Backend truth and security
- [ ] Persistent users in the repository layer (no in-memory dicts); `POST /api/auth/device` returns a signed token; all `/api/*` user routes require the token and reject access to other users' data
- [ ] Profile model: display name, age band (kid / teen / adult), goal, level, daily goal minutes, reminder time, theme, parent PIN (hashed)
- [ ] Characters API as the single source of truth: list, detail, owned/locked status, price, personality traits, sample lines, preview audio
- [ ] Tight CORS, request size limits, rate limiting per user, input validation
- [ ] Streaming conversation turn (Server-Sent Events or WebSocket): send transcript early, stream reply text, stream TTS chunks sentence by sentence so the first audio plays in about 2 seconds or less. Keep the simple endpoint as fallback.
- [ ] Per-turn cost logging
- [ ] **GATE 1:** pytest green; token isolation tested; one streamed turn works end to end against real providers.

### Phase 2: App data layer
- [ ] Complete typed API client for every backend route; token storage in secure storage; automatic device auth on first launch; retries and offline handling
- [ ] State management, repositories, caching for lists so screens open instantly and refresh quietly
- [ ] Global error and "server not ready" handling
- [ ] **GATE 2:** app launches fresh, authenticates, loads characters and missions from the backend only.

### Phase 3: Wire EVERY screen (fix defect C)
- [ ] **Home/Talk:** real streak, daily goal ring, today's mission, big start button, current character, "continue where you left off"
- [ ] **Missions:** missions from backend with real progress; tapping a mission opens its detail and a "Start" button that launches the right activity; claim reward is a backend call that updates XP, level and streak display
- [ ] **Scenarios:** list, detail, role-play conversation with goal checklist and completion
- [ ] **Topics:** conversation topics (weather, environment, daily life, careers, current affairs with a neutral tone), chosen before a talk
- [ ] **Shadowing:** play original script with speed control, learner repeats, show accuracy and pace, retry
- [ ] **Vocabulary notebook:** full screen, search, filter by due/new/mastered, flashcard review with Leitner schedule, "say it" button that checks pronunciation attempt, add from corrections
- [ ] **Profile:** opens a full profile screen (edit name, age band, goal, daily goal, reminder time, theme, language), shows real stats, history of sessions, plan and usage
- [ ] **Parent dashboard:** own screen behind a parent PIN gate; weekly minutes chart, streak, words learned, accuracy trend, safety flags list, tips for parents; no fake text
- [ ] **Settings:** notifications, theme, privacy, delete my data, about, developer server URL
- [ ] **GATE 3:** the Reality Audit passes with zero violations, and the brand-new-user walkthrough covers every tap.

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
- *None yet in V2. Initialized state files and verified audit defects.*
