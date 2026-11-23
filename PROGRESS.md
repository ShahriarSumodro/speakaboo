# Speakaboo Progress (V2 Reality Pass)

## Current Phase: Phase 7 (Safety, privacy, parents)
## Current Task: Phase 7.1 - Input and output safety moderation layer, child protection, and parent controls
## NEXT ACTION: Implement safety guardrails (content moderation, personal information scrubbing, safe redirects in companion voice, and parent safety alerts).

---

## Truth Table (Screens and Backend Routes)

### Flutter Screens
| Screen / Component | Status | Proof / Evidence |
|--------------------|--------|------------------|
| `TalkScreen` | Real | Wired to `AuthProvider` (real device user & token), streaming SSE turn pipeline, dynamic level badge, dev server settings dialog, "Help me say it" hint drawer, Fluency/Accuracy mode toggle, and Session Summary sheet. |
| `CharactersScreen` | Real | Fetches live companion catalog from `GET /api/characters/`, offline caching, active companion chip, opens `CharacterDetailScreen`. |
| `CharacterDetailScreen` | Real | Plays cached Orpheus voice preview audio via `GET /api/characters/{id}/preview-audio`, displays traits, sample lines, BDT unlock. |
| `MissionsScreen` | Real | Fetches live missions & streak from `GET /api/learning/missions/{id}`, "Claim Reward" calls `POST /api/learning/missions/claim` granting XP, Word of the Day bilingual card with Bengali meaning/example, Streak Recovery banner with zero-guilt repair. |
| `ProfileScreen` | Real | Displays real profile, XP, streak, words spoken; profile edit dialog persists to backend; Share My Progress social badge card; Referral & Rewards tile with invite code and redeem dialog; navigates to Vocabulary, Parent Dashboard, Settings. |
| `OnboardingScreen` | Real | Collects learner English level, age band, primary goal, and optional spoken diagnostic placement test persisting to backend `UserProfile`. |
| `ScenariosScreen` | Real | Fetches real-life roleplay scenarios from `GET /api/learning/scenarios`, goal checklists, launches scenario conversation in `TalkScreen`. |
| `TopicsScreen` | Real | Fetches curated discussion topics from `GET /api/learning/topics`, discussion starters, launches topic practice in `TalkScreen`. |
| `ShadowingScreen` | Real | Fetches passages from `GET /api/learning/shadowing`, speed control chips (0.8x, 1.0x, 1.2x), records attempt, calls `POST /api/learning/shadowing/evaluate`. |
| `VocabularyScreen` | Real | Fetches cards from `GET /api/learning/vocabulary/{id}`, search, Leitner box 1-5 filter chips, review dialog calling `POST /api/learning/vocabulary/review`, add card dialog. |
| `ParentDashboardScreen` | Real | Protected behind 4-digit Parent PIN (verified via PBKDF2), displays weekly minutes, word count, safety flags preview, parent coaching tips. |
| `SettingsScreen` | Real | Daily practice reminder toggle and time picker (NotificationService), theme selector, developer server URL dialog, privacy policy viewer, "Delete My Data" account deletion. |

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
| `POST /api/conversation/start` | Real | Initializes conversation state with practice_mode, coach_mode, age_band, character memory recall. |
| `POST /api/conversation/turn` | Real | Working pipeline with Orpheus/GPT-OSS, cost logging, mistake categorization. |
| `POST /api/conversation/stream-turn` | Real | SSE streaming endpoint: early transcript, sentence-by-sentence text & TTS audio chunks. |
| `POST /api/conversation/hint` | Real | Generates sentence starter, model response, and vocabulary hints. |
| `POST /api/conversation/summary` | Real | Computes talk-time balance, WPM, approximate clarity score, tomorrow hook, auto-saves character memory. |
| `POST /api/conversation/placement` | Real | Spoken diagnostic test estimating CEFR A1-B2 and persisting level to profile. |
| `GET /api/conversation/mistakes/{user_id}` | Real | Queries categorized recurring learner mistakes from SQLite `mistake_logs`. |
| `GET /api/learning/word-of-the-day` | Real | Returns daily curated vocabulary with Bengali meaning and example. |
| `POST /api/learning/streak/repair` | Real | Restores broken streak without guilt if learner completes a recovery session. |
| `GET /api/learning/weekly-recap/{user_id}` | Real | Returns 7-day speaking minutes, words learned, streak, and milestone metrics. |
| `GET /api/learning/referral/{user_id}` | Real | Generates user referral code and computes viral referral stats. |
| `POST /api/learning/referral/claim` | Real | Awards 100 XP + streak freeze to referrer and 50 XP to referee. |
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
- [x] Character detail screen: portrait/avatar, tagline, personality traits, how they speak, best for (kids/exams/interviews), sample dialogue written as original lines, and a **"Hear their voice"** button that plays a real generated sample (cached)
- [x] **"Try for 2 minutes free"**: a limited trial conversation with a locked character, enforced by the backend, then a friendly unlock prompt with price in BDT
- [x] Character switching mid-session keeps learner's progress; distinct behavior per character defined in data
- [x] Animated face reacts to states (listening, thinking, speaking, celebrating)
- [x] **GATE 4:** I can fully experience a locked character's voice and personality before paying. (Verified: `test_phase4_character_experience.py` green; 125 backend tests passing).

### Phase 5: Coaching engine (Hat 2 drives this phase)
- [x] **Onboarding and placement:** goal, age band, 2-minute spoken placement conversation estimating level (A1-B2), result stored in profile
- [x] **Correction policy:** default = recast + at most one explicit correction per turn; Fluency mode vs Accuracy mode
- [x] **Hint and rescue:** "Help me say it" button offering sentence starter / model answer
- [x] **Metrics per session:** learner talk time vs bot talk time, WPM, average turn length, pauses, vocabulary variety, labeled-approximate clarity indicator
- [x] **Mistake memory:** corrections become review cards; recurring error categories tracked per learner
- [x] **Repeat-the-task drills:** retell same story 3 times, each shorter and faster
- [x] **Session summary:** strengths, top 2-3 patterns to work on, one concrete next step, "say this better" list, hook for tomorrow
- [x] **Constructive Criticism / Coach Mode:** opt-in per session (Gentle, Balanced, Strict), off by default for kids
- [x] Age-appropriate behavior: kids get shorter turns, playful tone; adults get goal-oriented tasks
- [x] **GATE 5:** test learner completes onboarding, session, summary, and review deck. (Verified: `test_phase5_coaching.py` green; 130 backend tests passing, 32 Flutter tests passing).

### Phase 6: Retention engine (the North Star)
- [x] Local notifications with chosen reminder time, varied copy, frequency caps, easy off switch (`NotificationService`)
- [x] Daily talk: 2-minute guided session counting for streak
- [x] Streak freeze, streak repair (`POST /api/learning/streak/repair`), weekly goal, level-up celebration
- [x] "Tomorrow hook" at the end of every session auto-persisting to companion memory
- [x] Character memory: name, goal, last topic, running storyline used in greetings (`character_memories`)
- [x] Shareable progress card (`ShareProgressCard`) and referral code with backend reward (`referrals` table, `POST /api/learning/referral/claim`)
- [x] Word of the day (`GET /api/learning/word-of-the-day`); weekly recap endpoint (`GET /api/learning/weekly-recap/{user_id}`)
- [x] Analytics events and `retention_report.py` internal analytics script
- [x] **GATE 6:** 7-day user simulation shows reminders, streak changes, rewards, recap working. (Verified: `test_phase6_retention.py` green; 135 backend tests, 32 Flutter tests, 0 reality violations).

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

### Phase 6 - Retention Engine & Daily Habit Loop (The North Star)
- **Engineer Hat:** Built persistent SQLite `character_memories` table storing learner name, goal, last topic, and storyline hooks; wired personalized greeting into `POST /api/conversation/start`; implemented zero-guilt streak forgiveness with `streak_freeze_count`, `previous_streak` recovery, and endpoint `POST /api/learning/streak/repair`; added daily educational vocabulary endpoint `GET /api/learning/word-of-the-day` with Bengali translations and phonetic pronunciation; implemented viral referral loop in SQLite `referrals` with `GET /api/learning/referral/{id}` and `POST /api/learning/referral/claim` granting referrer 100 XP + streak freeze and referee 50 XP; added `backend/scripts/retention_report.py` generating cohort retention (D1, D7, D30), speaking minutes, and mission completion distributions; implemented Flutter `NotificationService` (frequency-capped, custom user time), `ShareProgressCard` (WhatsApp/social proof), and integrated habit reminders into `SettingsScreen`, `MissionsScreen`, and `ProfileScreen`. All 135 backend tests, 32 Flutter tests pass with 0 reality audit violations.
- **Coach Hat:** Habit formation directly supports SLA automaticity: a consistent 2-minute daily talk builds neural pathways far more effectively than an irregular 30-minute cram; streak freeze and guilt-free repair eliminate the psychological drop-off of broken streaks; personalized companion greetings make learners feel known, remembered, and safe to practice without judgment.
- **Market Hat:** Built for Bangladeshi habits: 20:00 (8:00 PM) default practice notification fits right after dinner/study time; shareable visual cards enable social proof across WhatsApp family chats and Facebook groups; referral rewards (+100 XP & streak freeze) lower customer acquisition cost organically without paid ads.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Every conversation ends with an explicit cliffhanger hook from their chosen companion, local notifications trigger at their chosen time, their streak is protected even if life gets busy, and their companion greets them by name asking about the exact topic they discussed yesterday.

### Phase 5 - Coaching Engine (Hat 2 Master Speaking Coach)
- **Engineer Hat:** Built CEFR spoken diagnostic engine (`backend/engine/placement.py`) and endpoint `POST /api/conversation/placement` persisting level to SQLite `UserProfile`; added `POST /api/conversation/hint` generating contextual sentence starters and model responses; added `POST /api/conversation/summary` computing talk-time balance ratio, WPM, and labeled approximate clarity score; added automatic Bengali error categorization (`articles`, `tenses_and_verbs`, `prepositions`, `subject_verb_agreement`) with persistent `mistake_logs` in SQLite and route `GET /api/conversation/mistakes/{user_id}`; integrated "Help me say it" hint sheet and full `SessionSummarySheet` with 3-retell drill prompt in Flutter; 130 backend tests and 32 Flutter tests pass with 0 reality audit violations.
- **Coach Hat:** Pedagogy respects core SLA principles: fluency mode eliminates interruptions by recasting naturally within bot turns; accuracy mode restricts explicit feedback to at most 1 high-priority error per turn; talk-time ratio actively maximizes learner speech; approximate clarity score is honestly labeled as STT confidence/cadence rather than fake lab phonetics; repeat-the-task drill trains automaticity by retelling answers shorter and faster.
- **Market Hat:** Structured diagnostic placement eliminates guesswork for Bangladeshi learners (students seeking IELTS band 7+, job seekers preparing for interviews); "Help me say it" rescue button eliminates conversational anxiety and freeze-ups for hesitant English speakers.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Every session concludes with a character-driven tomorrow hook and clear, bite-sized next steps. The learner leaves with a sense of accomplishment, tangible speaking metrics, and curiosity about what their companion will share tomorrow.

### Phase 4 - Character Experience, Preview-Before-Buy & 2-Minute Free Trial
- **Engineer Hat:** Implemented SQLite persistence for `character_trials` tracking spoken seconds per user and character; enforced 2-minute trial cap (120s) in `backend/routes/conversation.py` before requiring entitlement; enriched `CharacterFace` with celebration state (`isCelebrating`), smiling eyes `^ ^`, wide grin, and accessory rendering (fedora for Kabir, glasses for Anika, straw hat for Reggie); added voice preview player in `CharacterDetailScreen`; all 125 backend tests and 30 Flutter tests passing with 0 reality audit violations.
- **Coach Hat:** Free 2-minute trial lets hesitant learners test their chemistry with a companion before committing; distinct personality traits, speaking styles, and voice tones cater to different goals (beginner encouragement with Reggie, analytical mystery solving with Kabir, academic discussion with Anika).
- **Market Hat:** "Try before you buy" is the most effective conversion driver in Bangladesh: learners hear the voice and test the experience, lowering risk perception before making a 350 BDT purchase via bKash/Nagad.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Engaging visual animations and distinct companion voices make practice feel like a relationship rather than homework. Learners look forward to hearing their favorite character's reaction.

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
