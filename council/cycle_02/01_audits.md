# Council Cycle 2: Audits (Step 0 Baseline & Step 2 Solo Audits)

**Date:** 2026-11-24  
**Cycle:** 02  
**Status:** In Progress  

---

## Step 0: Baseline Verification

| Tool / Check | Status | Evidence Tag |
|---|---|---|
| Backend Pytest | 157 passed | `[RAN]` |
| Flutter Analyze | 0 issues | `[RAN]` |
| Flutter Test | 39 passed | `[RAN]` |
| Reality Audit | 0 violations | `[RAN]` |

---

## Step 2: Solo Audits (Cycle 2 Focus)

### 1. Maya, Product Engineer
- **Code & Latency Audit:**
  - `[READ]` `app/lib/screens/talk_screen.dart#L200-L240`: When a learner selects a locked character (e.g. Detective Kabir), the server enforces a 120-second trial cap (`backend/routes/conversation.py#L152`), but the UI does not indicate how much time is left. An unexpected paywall bottom sheet without advance notice causes frustration. Adding a subtle remaining-time badge in `TalkScreen` is high value.
  - `[READ]` `app/lib/screens/scenarios_screen.dart#L80`: When a scenario is selected, the app immediately transitions to `TalkScreen`. Adding a structured pre-task sheet requires clean state hand-off so audio streaming starts only when the learner is ready.
- **Top Issues for Cycle 2 (Maya):**
  1. Add remaining-trial badge in `TalkScreen` for locked characters.
  2. Implement clean pre-task planning sheet in `ScenariosScreen` with non-blocking start button.
  3. Ensure Parent Dashboard WhatsApp sharing uses standard URL encoding without native package bloat.

### 2. Dr. Rahman, English Speaking Coach
- **SLA Evidence & Pedagogy Audit:**
  - `[RESEARCH]` Ellis (2005), Skehan & Foster (1997): Pre-task planning (30–60 seconds) produces higher fluency, lexical variety, and grammatical accuracy in L2 speech. Currently, when learners tap "Job Interview", they are immediately dropped into the hot seat without time to organize thoughts.
  - `[READ]` `app/lib/screens/profile_screen.dart#L120`: The profile displays "Level: Beginner" or "Intermediate", but does not show what skills or speaking minutes are needed to advance to the next CEFR band.
- **Top Issues for Cycle 2 (Dr. Rahman):**
  1. 45-second guided planning sheet before roleplay scenarios (`EXP003`).
  2. Dual plain-language identity + formal CEFR badges ("Confident Everyday Speaker (CEFR B1)").
  3. Continuous motivation through micro-milestones.

### 3. Tanvir, Growth & Psychology Strategist
- **Parent Loop & Social Proof Audit:**
  - `[READ]` `app/lib/screens/parent_dashboard_screen.dart#L150`: Parents enter a 4-digit PIN to see their child's speaking minutes and active days, but have no way to share this progress with grandparents, tutors, or family on WhatsApp. In Bangladesh, parents love sharing educational achievements.
  - `[READ]` `app/lib/widgets/daily_cap_sheet.dart#L50`: Completing the daily speaking practice is the core habit lock-in moment. Enhancing it with visual celebration increases dopamine and retention.
- **Top Issues for Cycle 2 (Tanvir):**
  1. 1-tap WhatsApp summary share behind Parent PIN in `ParentDashboardScreen`.
  2. Visual progress bar to next fluency level in `ProfileScreen`.
  3. Celebration accent in `DailyCapSheet`.
