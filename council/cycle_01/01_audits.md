# Council Cycle 1: Audits (Step 0 Baseline & Step 2 Solo Audits)

**Date:** 2026-11-24  
**Cycle:** 01  
**Status:** In Progress  

---

## Step 0: Baseline Test Verification Results

| Test Suite / Tool | Command Executed | Result | Evidence Tag |
|---|---|---|---|
| **Backend Unit & API Tests** | `pytest backend/tests -v` | **155 passed** in 2.58s | `[RAN]` |
| **Flutter Lints & Static Analysis** | `flutter analyze` | **No issues found** (0 errors, 0 warnings, 0 infos) | `[RAN]` |
| **Flutter Unit & Widget Tests** | `flutter test` | **39 passed** in 3s | `[RAN]` |
| **Automated Reality Audit** | `python tools/reality_audit.py` | **0 violations detected** | `[RAN]` |
| **Provider Verification** | `backend/scripts/verify_providers.py` | Checked: requires production `GROQ_API_KEY` (logged in `DECISIONS.md`) | `[RAN]` |
| **Telemetry & Habit Reports** | `retention_report.py`, `revenue_report.py`, `experiments_report.py` | Ran cleanly; confirmed schema and report generators | `[RAN]` |

---

## Step 2: Solo Audits

### 1. Maya, Product Engineer (10+ years shipping mobile apps)
*Focus: Code quality, security, performance on cheap Android phones, offline handling, dark/light themes, test coverage.*

#### System Audits & Findings
- **First 60 Seconds Experience:**
  - `[READ]` `app/lib/screens/onboarding_screen.dart#L90-L160`: Onboarding starts quickly, but if a learner elects to take the placement test, a 20-second recording window is initiated. On low-end devices (e.g. 2GB RAM Android Go), recording 20s of uncompressed WAV can cause memory spikes and noticeable UI latency.
  - `[READ]` `app/lib/screens/talk_screen.dart#L120-L180`: Audio recording uses 16kHz mono 16-bit PCM. Safe and bandwidth-efficient. SSE audio chunking works smoothly.
- **Returning User (Day 3, 7, 30) Experience:**
  - `[READ]` `app/lib/services/api_service.dart#L240`: Character memory recall is properly fetched from `POST /api/conversation/start` and displayed in `TalkScreen`. The character greets the user by name and references their last practice topic.
  - `[READ]` `app/lib/widgets/daily_cap_sheet.dart`: Light and dark theme tokens are fully respected with `SpeakabooTheme.surface` and `SpeakabooTheme.textPrimary`. Contrast ratios exceed 11:1 on dark mode (`#1B1613` background, `#F5EDE6` text).
- **Payment & Security Architecture:**
  - `[READ]` `app/lib/widgets/unlock_sheet.dart`: Now cleanly supports `AppConfig.isPlayFlavor` vs `AppConfig.isDirectFlavor`. Google Play Billing is strictly shown on Play builds; bKash/Nagad are shown only on direct builds.
  - `[READ]` `backend/routes/payment.py#L290-L330`: Refund endpoint `POST /api/payment/refund` properly revokes entitlements and marks ledger status as `refunded`. Idempotency is enforced.
- **Top 5 Things Missing (Maya):**
  1. Countdown timer for locked character trial (currently 120s server-enforced, but learner has no visual remaining clock).
  2. Visual word-level alignment highlighting in `ShadowingScreen` for mismatch detection.
  3. Strict LLM error extraction fallback in `backend/engine/correction.py` ensuring max 1 focus error even if the model outputs a list.
  4. Auto-stop microphone recording on silence in `VocabularyScreen` spoken recall dialog.
  5. Cache TTL and invalidation for character voice preview audio files.
- **Top 5 Things to Remove / Simplify (Maya):**
  1. Remove redundant mock payment branches now that `BillingProvider` abstraction is unified.
  2. Simplify `DropdownButtonFormField` values in onboarding to use pure initializers.
  3. Remove unused Bluetooth pairing background scanner stubs from startup lifecycle to conserve battery.
  4. Streamline duplicate analytics logging calls in `talk_screen.dart`.
  5. Eliminate unused legacy icon definitions in `app/lib/config/theme.dart`.

---

### 2. Dr. Rahman, English Speaking Coach (20+ years teaching Bangla learners)
*Focus: Talk time maximization, anxiety reduction, recast vs explicit correction, cognitive load, honest progress metrics.*

#### Pedagogical Audits & Findings
- **Learner Talk-Time & Conversational Dynamics:**
  - `[READ]` `backend/engine/characters.py#L95`: Character prompts instruct the model: "Keep your response under 2 sentences and end with a natural conversational question." This enforces high learner talk-time ratio (>60% learner speech).
  - `[READ]` `backend/routes/conversation.py#L250`: `SessionSummary` explicitly calculates `learner_to_bot_talk_ratio` and WPM.
- **Error Correction & Recast Design:**
  - `[RESEARCH]` Lyster & Ranta (1997), Ellis (2006): Corrective recasts inside conversational context maintain communicative flow, whereas heavy explicit interruptions spike foreign language anxiety.
  - `[READ]` `backend/engine/characters.py`: The model recasts the student's mistake naturally in its reply sentence, while isolating at most ONE focus mistake per turn in `CorrectionChip`.
  - `[READ]` `backend/engine/correction.py`: Bengali error categories (`articles`, `tenses_and_verbs`, `prepositions`, `subject_verb_agreement`) accurately target known L1 transfer interference from Bengali to English.
- **Placement & Diagnostic Anxiety:**
  - `[READ]` `app/lib/screens/onboarding_screen.dart#L135`: The current spoken diagnostic requires speaking for up to 20 seconds on a complex prompt. For an anxious beginner in Bangladesh who has never spoken English aloud to an AI, this produces freeze/anxiety and drop-off!
- **Top 5 Things Missing (Dr. Rahman):**
  1. A low-anxiety 1-sentence diagnostic icebreaker option in onboarding (e.g. "Say hello and your favorite food").
  2. Audio pronunciation playback for Word of the Day on `MissionsScreen` so learners hear correct word stress before trying to use it.
  3. Explicit 45-second pre-task planning countdown sheet with 3 guiding questions before roleplay scenarios (`EXP003`).
  4. Visual phonetic word breakdown in `ShadowingScreen` showing which specific word was rushed or omitted.
  5. Spoken recall test in `VocabularyScreen` that evaluates student's pronunciation of the target word using STT text matching.
- **Top 5 Things to Remove / Simplify (Dr. Rahman):**
  1. Remove complex multi-sentence diagnostic prompt for beginner age bands in onboarding.
  2. Remove multiple error display cards in `TalkScreen`—strict adherence to 1 error per turn.
  3. Simplify CEFR technical jargon on student profile screen (replace "CEFR B1 Threshold" with actionable "Confident Everyday Speaker").
  4. Remove arbitrary "clarity percentage" numbers from session recap and replace with descriptive band: "Clear & Natural" / "Approaching Target" with honest approximate note.
  5. Eliminate unnecessary grammatical theory explanations in `CorrectionDetailSheet` in favor of 1 example sentence.

---

### 3. Tanvir, Growth & Human-Psychology Strategist (10+ years consumer apps in Bangladesh)
*Focus: First-minute wow, habit triggers, forgiving streaks, Bangladeshi payment reality, parent trust, cost sustainability.*

#### Growth & Psychology Audits & Findings
- **First-Minute Wow:**
  - `[READ]` `app/lib/screens/talk_screen.dart`: A new user can open the app, tap Farmer Reggie, and receive a welcoming voice turn within 60 seconds. However, if they get bogged down in the 20-second placement test, that first-minute win is broken.
- **Daily Habit Loop & Streaks:**
  - `[READ]` `app/lib/services/notification_service.dart`: Daily practice reminders are scheduled for the user's custom chosen time (default 8:00 PM) in `Asia/Dhaka` timezone.
  - `[READ]` `backend/routes/learning.py#L110`: Zero-guilt streak recovery allows users to use a streak freeze or repair a broken streak with 1 tap.
  - `[READ]` `app/lib/widgets/daily_cap_sheet.dart`: Reaching the 10-minute daily cap feels like an achievement ("Daily Practice Completed! 🌟 Streak Saved") rather than a hostile roadblock.
- **Bangladeshi Monetization & Payment Reality:**
  - `[READ]` `app/lib/widgets/unlock_sheet.dart`: Direct flavor supports bKash and Nagad. However, in Bangladesh, a high percentage of users pay via USSD (*247#) or direct merchant send-money, and expect to input their 10-character TrxID (Transaction ID) directly if the web gateway fails.
  - `[DATA]` `revenue_report.py`: Gross revenue 1500 BDT across 6 transactions with $0.0007 cost per speaking minute confirms strong unit economics (>80% gross margin).
- **Top 5 Things Missing (Tanvir):**
  1. Manual TrxID verification entry option in `UnlockSheet` for direct bKash/Nagad payers who prefer USSD transfer.
  2. WhatsApp 1-tap summary export in `ParentDashboardScreen` so parents can show relatives/friends their child's speaking minutes.
  3. Native audio preview button for Word of the Day on `MissionsScreen` to increase daily return engagement.
  4. Visual progress milestones in `ProfileScreen` showing exactly how many more speaking minutes are needed to reach the next fluency badge.
  5. Confetti celebration animation on `DailyCapSheet` when the daily streak is locked in.
- **Top 5 Things to Remove / Simplify (Tanvir):**
  1. Remove intimidating 20-second placement test requirement on first launch.
  2. Remove character count displays on talk screens—unnecessary distraction for learners.
  3. Remove redundant payment buttons in `ProfileScreen` (keep purchase flows centralized in `UnlockSheet` and `DailyCapSheet`).
  4. Simplify referral code sharing dialog to 1-tap WhatsApp deep link with pre-filled Bangla/English message.
  5. Remove unused settings toggles that confuse non-technical users.
