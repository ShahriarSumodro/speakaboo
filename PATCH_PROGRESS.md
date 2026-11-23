# Speakaboo Patch Loop Progress

## Current Phase: Phase 2 (Payments and distribution)
## Current Task: Phase 2.1 - BillingProvider abstraction, build flavors (play vs direct), and unified entitlement syncing
## NEXT ACTION: Build BillingProvider abstraction with Google Play Billing, direct bKash/Nagad, and web checkout, supporting 'play' and 'direct' flavors with shared backend entitlements.

---

## Phases Checklist

### Phase 0: Baseline check (never trust "done")
- [x] Run the full backend tests, `flutter analyze`, `flutter test`, `verify_providers.py` and the Reality Audit. Walk through every screen as a new user in both themes. Record the true status in `PATCH_PROGRESS.md`.
- [x] Fix every regression and any item V2 marked done but that is not. If V2 left unfinished phases, finish them first.
- **GATE 0:** everything is green and the truth table shows every screen and route as `real`. (Verified: flutter analyze 0 issues, 34 flutter tests pass, 146 pytest tests pass, reality audit 0 violations).

### Phase 1: Measurement foundation (before teaching features)
- [x] Experiments service: feature flag per user, stable bucketing, variants stored in the database, config-driven.
- [x] Event logging for: session length, next-day return, correction type and whether the learner self-fixed, task attempt metrics, review results, speaking check scores, cost per turn.
- [x] `experiments_report.py`: results per variant with sample sizes and a plain-language warning when samples are too small to trust.
- [x] `retention_report.py` check: D1, D7, D30, sessions per week, minutes per active day.
- **GATE 1:** a simulated 14-day cohort produces correct numbers in both reports. (Verified: `test_phase1_measurements.py` green; 150 backend tests, 34 Flutter tests, 0 reality violations).

### Phase 2: Payments and distribution (changes architecture, so do early)
- [ ] `BillingProvider` abstraction with implementations: (1) Google Play Billing, (2) bKash/Nagad via aggregator or direct merchant for a DIRECT build, (3) web checkout.
- [ ] Two build flavors: `play` (only policy-compliant purchase flows) and `direct` (bKash/Nagad, for distribution outside Play). Never expose bKash/Nagad in-app checkout in the `play` flavor until I confirm the policy answer in writing.
- [ ] Entitlements stay in the backend and are shared across flavors; a payment in one place unlocks everywhere. Handle idempotency, receipts, restore, expiry and refunds.
- [ ] Sandbox mode for each provider switchable by config only and OFF in release builds.
- [ ] NEEDS FROM USER entries: confirm Play merchant registration from Bangladesh and whether Bangladeshi users can buy in-app on Play; check the current Payments policy for Bangladesh; choose bKash direct merchant (needs Bangladesh Bank approval) vs a licensed aggregator such as SSLCommerz or AamarPay; Nagad credentials.
- **GATE 2:** purchase, restore and expiry work end to end in sandbox in both flavors.

### Phase 3: Core speaking methods (highest learning value)
- [ ] **3a. Correction style, prompts first:** Order: clarification request or hint, learner retry, recast, then written "better" sentence. One focus error per turn. Configurable and A/B tested (prompts-first vs recast-first). Log correction type and self-fix result.
- [ ] **3b. Task repetition, "Again, faster":** Attempt 1, short feedback, attempt 2 with shorter time limit, attempt 3. Show WPM, pauses, filler words and lexical variety per attempt.
- [ ] **3c. Pre-task planning:** 30 to 60 seconds of planning with 3 guiding prompts and optional key phrases before scenario and story tasks. Planning time adjustable and measured.
- [ ] **3d. Interaction quality:** Follow-ups, clarification requests, pushed output for longer answers. Automated check on logs for learner-to-bot talk ratio.
- **GATE 3:** A/B assignment works; a test learner completes a prompts-first correction, a 3-attempt repetition task, and a planned scenario; metrics appear in the reports.

### Phase 4: Memory, rhythm and pronunciation
- [ ] **4a. Spaced retrieval:** Expanding schedule (1, 3, 7, 14, 30 days). Review is RECALL: gap sentence or meaning, learner says it aloud, backend checks transcript. Due words fed to character to steer conversations.
- [ ] **4b. Shadowing for rhythm and fluency:** Original scripts; speed control (0.75x, 1x, 1.25x), short chunks, sentence loop. Score word match, pace, pauses. Approximate clarity label. UI: "rhythm and fluency practice".
- [ ] **4c. Perception-first pronunciation drills:** "Listen and choose" minimal-pair games using multiple TTS voices (Orpheus 6 voices), instant feedback, followed by speaking step and re-test. Target sounds from learner's logged errors.
- **GATE 4:** review cards, shadowing and pronunciation drills work end to end and feed the reports.

### Phase 5: Confidence, timing and honest claims
- [ ] **Lower anxiety by design:** Weekly speaking promise with kind progress display; private by default; 1-tap confidence rating before and after sessions.
- [ ] **Feedback timing configurable:** Interim (1 light prompt during talk, report at end) vs Delayed (no interruption, report at end). A/B test and record continuation and self-fix rates.
- [ ] **Speaking check as source of truth:** Day 0, Day 7, Day 14 speaking check with stored scores and before/after chart. Claims restricted to measured oral results.
- [ ] **Coach Mode (constructive criticism, opt-in):** Gentle, Balanced, Strict; off by default for kids.
- **GATE 5:** speaking check, promise, timing modes and Coach Mode work, and results appear in `experiments_report.py`.

### Phase 6: Market readiness
- [ ] **Pricing:** Remote-configurable plans, caps and trial length; A/B test 200 BDT/month vs weekly vs 3-month; BDT only. Unit-cost guard computes cost per user-minute from real logs and tightens caps when losing money.
- [ ] **Trust and parents:** Parent PIN, plain-language weekly report, content safety tests, bilingual privacy policy and terms, data export/deletion, no ads/dark patterns. Play Data Safety and children's-app checklist.
- [ ] **Performance:** Test on low-end Android profile (2 to 3 GB RAM): cold start under 4s, no jank, compressed audio upload, resumable sessions, offline cached home.
- [ ] **Acquisition kit:** Shareable progress cards, referral code, store listing copy in English and Bangla, screenshot checklist, landing page spec, WhatsApp/Facebook share messages.
- [ ] **Operations:** Deploy guide with HTTPS, monitoring, daily backups, rate limits, read-only admin view for usage/errors/costs/safety; release signing documented.
- **GATE 6:** Reality Audit clean in both themes and both flavors; fresh-install walkthrough passes.

### Phase 7: Pilot tooling and launch gate
- [ ] `pilot_report.py`: 2-week pilot of 10 to 20 learners (D1, D7, sessions in week 1, first-conversation completion, speaking check change, cost per user vs revenue, drop-off screens).
- [ ] Simulated-cohort test of the report.
- [ ] `LAUNCH_CHECKLIST.md` verified and complete.
- **GATE M (market-ready gate):** all gates passed, Reality Audit clean, every item in truth table `real`, and `LAUNCH_CHECKLIST.md` complete.

---

## Truth Table (Screens and Backend Routes)

### Flutter Screens
| Screen / Component | Status | Proof / Evidence |
|---|---|---|
| `TalkScreen` | real | Wired to `AuthProvider`, live SSE audio turns, level badge, "Help me say it" hint drawer, Fluency/Accuracy modes, Session Summary. |
| `CharactersScreen` | real | Fetches catalog from `GET /api/characters/`, offline cache, opens `CharacterDetailScreen`. |
| `CharacterDetailScreen` | real | Plays cached Orpheus voice previews via `GET /api/characters/{id}/preview-audio`, traits, 2-min trial. |
| `MissionsScreen` | real | Fetches live missions from `GET /api/learning/missions/{id}`, Word of the Day, zero-guilt streak recovery. |
| `ProfileScreen` | real | Real user profile, XP, streak, words spoken; edit dialog; Share My Progress card; Referral tile. |
| `OnboardingScreen` | real | Level, age band, primary goal, spoken placement test persisting to backend `UserProfile`. |
| `ScenariosScreen` | real | Roleplay scenarios from `GET /api/learning/scenarios`, goal checklists, launches into `TalkScreen`. |
| `TopicsScreen` | real | Curated discussion topics from `GET /api/learning/topics`, discussion starters. |
| `ShadowingScreen` | real | Passages from `GET /api/learning/shadowing`, speed chips (0.8x, 1.0x, 1.2x), audio evaluate. |
| `VocabularyScreen` | real | Leitner box cards from `GET /api/learning/vocabulary/{id}`, review dialog with spaced repetition. |
| `ParentDashboardScreen` | real | Protected behind PBKDF2 4-digit PIN, weekly speaking minutes, safety flags list. |
| `SettingsScreen` | real | Daily practice reminder time picker, theme selector, privacy policy viewer, delete account. |

### Backend Routes
| Route | Status | Proof / Evidence |
|---|---|---|
| `GET /api/health` | real | Component health, database metrics, uptime, provider diagnostics. |
| `POST /api/auth/device` | real | Issues HMAC-SHA256 signed token; SQLite user persistence. |
| `GET /api/auth/profile` | real | Returns UserProfile with age band, goals, reminder time. |
| `PUT /api/auth/profile` | real | Updates UserProfile in SQLite. |
| `POST /api/auth/set-parent-pin` | real | Hashes 4-digit PIN with PBKDF2 salt. |
| `POST /api/auth/verify-parent-pin` | real | Validates 4-digit PIN securely. |
| `GET /api/characters/` | real | External character catalog JSONs with traits, sample lines, tagline. |
| `GET /api/characters/{id}/preview-audio` | real | Cached voice preview synthesized with Orpheus TTS. |
| `POST /api/conversation/start` | real | Initializes conversation with character memory recall greeting. |
| `POST /api/conversation/turn` | real | Full STT -> LLM -> TTS pipeline with error categorization. |
| `POST /api/conversation/stream-turn` | real | SSE streaming: early transcript + incremental TTS audio. |
| `POST /api/conversation/hint` | real | Contextual sentence starters and model responses. |
| `POST /api/conversation/summary` | real | Talk-time ratio, WPM, approximate clarity score, tomorrow hook. |
| `POST /api/conversation/placement` | real | Spoken diagnostic test estimating CEFR A1-B2. |
| `GET /api/conversation/mistakes/{user_id}` | real | Recurring categorized learner mistakes from `mistake_logs`. |
| `GET /api/learning/word-of-the-day` | real | Curated daily bilingual vocabulary card. |
| `POST /api/learning/streak/repair` | real | Zero-guilt streak recovery. |
| `GET /api/learning/weekly-recap/{user_id}` | real | 7-day speaking minutes and milestones recap. |
| `GET /api/learning/referral/{user_id}` | real | Referral code generator and viral stats. |
| `POST /api/learning/referral/claim` | real | Referral reward attribution (+100 XP & streak freeze). |
| `GET /api/usage/{user_id}` | real | Evaluates speaking minutes against tier limits. |
| `GET /api/learning/streak/{user_id}` | real | Evaluates streak in `Asia/Dhaka` timezone. |
| `GET /api/learning/missions/{user_id}` | real | Learning missions list and progress. |
| `POST /api/learning/missions/claim` | real | Claims mission XP in database. |
| `GET /api/learning/scenarios` | real | Roleplay scenario packs. |
| `GET /api/learning/topics` | real | Guided discussion topics. |
| `GET /api/learning/shadowing` | real | Audio shadowing passages. |
| `GET /api/learning/vocabulary/{user_id}` | real | Leitner box vocabulary cards. |
| `POST /api/learning/vocabulary/review` | real | Updates Leitner box based on review outcome. |
| `GET /api/parent/summary/{user_id}` | real | Weekly speaking minutes, words, safety flags. |
| `GET /api/payment/plans` | real | Active pricing plans in BDT. |
| `POST /api/payment/checkout` | real | Records pending payment in SQLite `payments` ledger. |
| `POST /api/payment/verify` | real | Idempotent verification granting entitlements. |
| `POST /api/payment/webhook` | real | Idempotent gateway webhook handler. |
| `GET /api/payment/entitlements/{user_id}` | real | Lists active entitlements, filtering out expired plans. |
| `POST /api/payment/restore/{user_id}` | real | Restores entitlements from database. |
| `GET /api/privacy/policy` | real | Privacy policy text. |
| `GET /api/privacy/export/{user_id}` | real | Complete learner archive without raw audio. |
| `DELETE /api/privacy/user/{user_id}` | real | Purges user data across all 13 database tables. |

---

## Log of Completed Tasks (Patch Loop)

### Phase 1 - Measurement Foundation & A/B Testing Instrumentation
- **Engineer Hat:** Built `backend/engine/experiments.py` with deterministic SHA-256 hash bucketing across 6 active pedagogical/business experiments; added SQLite persistence for `experiment_assignments` and `analytics_events` with indexed queries; instrumented SLA metric loggers (session length, D1 return, correction self-fixes, task attempt metrics, review recall, speaking checks, per-turn costs); built `backend/scripts/experiments_report.py` with sample size counts and plain-language warnings for underpowered cohorts (N < 30); updated `retention_report.py` to compute `minutes_per_active_day` and `sessions_per_week`; verified simulated 14-day cohort test. 150 backend tests and 34 Flutter tests pass with 0 reality audit violations.
- **Coach Hat:** Every teaching feature is now measurable rather than dogmatic: we track whether prompts-first actually pushes learner self-correction compared to recasts, and whether 3-retell drills increase WPM over time; plain-language sample size warnings prevent premature educational conclusions based on noisy small-sample data.
- **Market Hat:** Enables data-driven optimization of the onboarding funnel and pricing elasticity (200 BDT/mo vs 60 BDT/week) without guessing; granular cost-per-turn tracking guarantees unit-economic safety before spending on learner acquisition.
- **Retention Question ("Why will a user return tomorrow because of this?"):** Rigorous measurement allows us to detect exactly where learners drop off and optimize the habit loop with statistical proof. Features that demonstrably increase day-1 and day-7 returns are promoted while ineffective ones are pruned.

### Phase 0 - Baseline Verification & Analyzer Polish
- **Engineer Hat:** Eliminated all 26 `flutter analyze` lints and warnings across the app (unused variables, context mounted checks across async gaps, initializing formals, deprecated dropdown properties), added widget test for `ShadowingScreen`, and verified full baseline test suite (146 backend pytest tests, 34 Flutter tests, 0 reality audit violations).
- **Coach Hat:** Clean codebase and tested screens ensure zero runtime crashes during spoken interactions; robust error handling in `ShadowingScreen` gracefully recovers when offline without leaving infinite loading spinners.
- **Market Hat:** Strict baseline verification guarantees that no regression from V2 slipped through; reliable app initialization on budget Android phones creates an immediate positive first impression.
- **Retention Question ("Why will a user return tomorrow because of this?"):** A rock-solid, crash-free app builds trust from the very first tap. When animations are fluid and screens never freeze or drop state, users feel confident making Speakaboo their daily speaking companion.
