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
- **Status:** In Progress

### CD-002: Visual Target-Word Alignment in Shadowing
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Maya & Dr. Rahman
- **Decision:** Change (`app/lib/screens/shadowing_screen.dart`)
- **Context & Evidence:** `[READ]` `shadowing_screen.dart`. Word-level color coding (green/amber/gray) for target sentence alignment.
- **Vote:** 3-0
- **Expected Impact:** High on Usability and Learning Value.
- **Status:** In Progress

### CD-003: Low-Anxiety Quick Icebreaker Diagnostic & Skip Option
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Dr. Rahman & Tanvir
- **Decision:** Change (`app/lib/screens/onboarding_screen.dart`)
- **Context & Evidence:** `[RESEARCH]` MacIntyre (1999). 10-second friendly icebreaker with skip button.
- **Vote:** 3-0
- **Expected Impact:** High on Day-1 First-Minute Win.
- **Status:** In Progress

### CD-004: Direct Distribution USSD TrxID Verification in UnlockSheet
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Tanvir
- **Decision:** Add (`app/lib/widgets/unlock_sheet.dart` & `backend/routes/payment.py`)
- **Context & Evidence:** `[DATA]` 40%+ Bangladeshi MFS users use USSD. Adds manual TrxID verification in direct flavor.
- **Vote:** 3-0
- **Expected Impact:** High on Direct Distribution Monetization.
- **Status:** In Progress

### CD-005: Native Audio Pronunciation & Speaking Task Hook for Word of the Day
- **Date:** 2026-11-24
- **Cycle:** Cycle 01
- **Proposer:** Tanvir & Dr. Rahman
- **Decision:** Change (`app/lib/screens/missions_screen.dart`)
- **Context & Evidence:** `[READ]` `missions_screen.dart`. Audio pronunciation button + 1-tap "Practice with Reggie" action.
- **Vote:** 3-0
- **Expected Impact:** Medium on Daily Return Pull.
- **Status:** In Progress
