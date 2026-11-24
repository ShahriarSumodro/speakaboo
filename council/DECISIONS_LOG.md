# Speakaboo Council Decisions Log

Running log of Council Decisions (ADR style).

---

## Log Template
### CD-NNN: [Title]
- **Date:** YYYY-MM-DD
- **Cycle:** Cycle NN
- **Proposer:** [Maya / Dr. Rahman / Tanvir]
- **Decision:** [Add / Change / Remove / Defer / Run Experiment]
- **Context & Evidence:**
- **Debate & Dissent:**
  - Maya: [Position]
  - Dr. Rahman: [Position]
  - Tanvir: [Position]
- **Vote:** [X-Y]
- **Expected Impact:** [Small / Medium / Large] on [Metric / Scorecard Dimension]
- **Risks & Rollback Plan:**
- **Tests Required:**
- **Status:** [Proposed / In Progress / Implemented / Rolled Back / Verified]

---

### CD-001: Strict Single-Focus Error Extraction Guard
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Maya & Dr. Rahman
- **Decision:** Change (`backend/engine/correction.py`)
- **Context & Evidence:** `[RESEARCH]` Ellis (2006). Enforces max 1 error per turn prioritizing `tenses_and_verbs` > `subject_verb_agreement` > `prepositions` > `articles`.
- **Vote:** 3-0
- **Expected Impact:** Medium on Learning Value and Retention.
- **Status:** Verified `[RAN]`

### CD-002: Visual Target-Word Alignment in Shadowing
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Maya & Dr. Rahman
- **Decision:** Change (`app/lib/screens/shadowing_screen.dart`)
- **Context & Evidence:** `[READ]` `shadowing_screen.dart`. Word-level color coding (green/amber/gray) for target sentence alignment.
- **Vote:** 3-0
- **Expected Impact:** High on Usability and Learning Value.
- **Status:** Verified `[RAN]`

### CD-003: Low-Anxiety Quick Icebreaker Diagnostic & Skip Option
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Dr. Rahman & Tanvir
- **Decision:** Change (`app/lib/screens/onboarding_screen.dart`)
- **Context & Evidence:** `[RESEARCH]` MacIntyre (1999). 10-second friendly icebreaker with skip button.
- **Vote:** 3-0
- **Expected Impact:** High on Day-1 First-Minute Win.
- **Status:** Verified `[RAN]`

### CD-004: Direct Distribution USSD TrxID Verification in UnlockSheet
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Tanvir
- **Decision:** Add (`app/lib/widgets/unlock_sheet.dart` & `backend/routes/payment.py`)
- **Context & Evidence:** `[DATA]` 40%+ Bangladeshi MFS users use USSD. Adds manual TrxID verification in direct flavor.
- **Vote:** 3-0
- **Expected Impact:** High on Direct Distribution Monetization.
- **Status:** Verified `[RAN]`

### CD-005: Native Audio Pronunciation & Speaking Task Hook for Word of the Day
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Tanvir & Dr. Rahman
- **Decision:** Change (`app/lib/screens/missions_screen.dart`)
- **Context & Evidence:** `[READ]` `missions_screen.dart`. Audio pronunciation button + 1-tap "Practice with Reggie" action.
- **Vote:** 3-0
- **Expected Impact:** Medium on Daily Return Pull.
- **Status:** Verified `[RAN]`

---

### CD-006: Pre-Task Planning Scaffold Sheet before Roleplays
- **Date:** 2026-11-24
- **Cycle:** Cycle 02
- **Proposer:** Dr. Rahman
- **Decision:** Add (`app/lib/screens/scenarios_screen.dart`)
- **Context & Evidence:** `[RESEARCH]` Ellis (2005). 45s timer + 3 guiding prompts.
- **Vote:** 3-0
- **Expected Impact:** High on Roleplay Fluency.
- **Status:** Verified `[RAN]`

### CD-007: 1-Tap WhatsApp Learning Report for Parents
- **Date:** 2026-11-24
- **Cycle:** Cycle 02
- **Proposer:** Tanvir
- **Decision:** Add (`app/lib/screens/parent_dashboard_screen.dart`)
- **Context & Evidence:** `[DATA]` WhatsApp sharing behind Parent PIN without PII.
- **Vote:** 3-0
- **Expected Impact:** High on Parent Retention.
- **Status:** Verified `[RAN]`

### CD-008: Active Character Trial Remaining Badge in TalkScreen
- **Date:** 2026-11-24
- **Cycle:** Cycle 02
- **Proposer:** Maya
- **Decision:** Add (`app/lib/screens/talk_screen.dart`)
- **Context & Evidence:** `[READ]` In-session trial time indicator prevents unexpected paywall drop.
- **Vote:** 3-0
- **Expected Impact:** Medium on Usability.
- **Status:** Verified `[RAN]`

### CD-009: Dual Plain-Language Identity & Formal CEFR Progress Bar
- **Date:** 2026-11-24
- **Cycle:** Cycle 02
- **Proposer:** Tanvir & Dr. Rahman
- **Decision:** Change (`app/lib/screens/profile_screen.dart`)
- **Context & Evidence:** `[RESEARCH]` Identity framing ("Confident Everyday Speaker (CEFR B1)").
- **Vote:** 3-0
- **Expected Impact:** Medium on Retention.
- **Status:** Verified `[RAN]`

### CD-010: Visual Celebration Accent on Daily Practice Completion
- **Date:** 2026-11-24
- **Cycle:** Cycle 02
- **Proposer:** Tanvir
- **Decision:** Change (`app/lib/widgets/daily_cap_sheet.dart`)
- **Context & Evidence:** `[RESEARCH]` Fogg Behavior Model. Lightweight celebratory accent on daily streak lock-in.
- **Vote:** 3-0
- **Expected Impact:** Low-Medium on Habit Lock-In.
- **Status:** Verified `[RAN]`

---

### CD-011: Vocabulary Spoken Recall Micro-Timeout and Stop Button
- **Date:** 2026-11-24
- **Cycle:** Cycle 03
- **Proposer:** Maya & Dr. Rahman
- **Decision:** Change (`app/lib/screens/vocabulary_screen.dart`)
- **Context & Evidence:** `[RESEARCH]` Nation (2001). 10s auto-stop safeguard and explicit tap-to-stop for spoken flashcard review.
- **Vote:** 3-0
- **Expected Impact:** Small on UX and Battery.
- **Status:** In Progress

### CD-012: Teaching Engine Experiment Variant Debug Badge in Settings
- **Date:** 2026-11-24
- **Cycle:** Cycle 03
- **Proposer:** Maya
- **Decision:** Add (`app/lib/screens/settings_screen.dart`)
- **Context & Evidence:** `[READ]` Diagnostic visibility for pedagogical A/B experiment variants in Settings.
- **Vote:** 3-0
- **Expected Impact:** Small on Pedagogical Verification.
- **Status:** In Progress
