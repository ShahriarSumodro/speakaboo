# Council Cycle 2: Decisions (Step 5)

**Date:** 2026-11-24  
**Cycle:** 02  
**Status:** Approved for Implementation (Batch of 5)  

---

### CD-006: Pre-Task Planning Scaffold Sheet before Roleplay Scenarios
- **Decision:** Add
- **Target:** `app/lib/screens/scenarios_screen.dart`
- **Why:** `[RESEARCH]` Ellis (2005): Pre-task planning (30–60s) significantly improves fluency, vocabulary selection, and syntax in L2 speech. Provides 3 guiding prompts and an optional 45s countdown with an instant "Ready! Start Roleplay" button.
- **Vote:** 3-0
- **Expected Impact:** High on Roleplay Speaking Confidence and Fluency.
- **Tests Required:** Widget test verifying pre-task sheet renders guiding questions and launches talk screen.

---

### CD-007: 1-Tap WhatsApp Learning Report for Parents
- **Decision:** Add
- **Target:** `app/lib/screens/parent_dashboard_screen.dart`
- **Why:** `[DATA]` Parents in Bangladesh share accomplishments on WhatsApp. A 1-tap positive weekly report deepens parental investment and subscription retention without exposing child PII.
- **Vote:** 3-0
- **Expected Impact:** High on Parent Subscription Retention.
- **Tests Required:** Widget test verifying share button and text generation behind Parent PIN.

---

### CD-008: Active Character Trial Remaining Badge in TalkScreen
- **Decision:** Add
- **Target:** `app/lib/screens/talk_screen.dart`
- **Why:** `[READ]` `talk_screen.dart`. When using a locked character on 2-min trial, an unexpected paywall creates frustration. Display an unobtrusive remaining time badge ("1:45 trial") so users have full advance clarity.
- **Vote:** 3-0
- **Expected Impact:** Medium on Usability and Monetization Trust.
- **Tests Required:** Widget test verifying trial badge renders for locked companion.

---

### CD-009: Dual Plain-Language Identity & Formal CEFR Progress Bar
- **Decision:** Change
- **Target:** `app/lib/screens/profile_screen.dart`
- **Why:** `[RESEARCH]` Lock & Latham (2002). Pairs emotional identity ("Confident Everyday Speaker") with formal credential ("CEFR B1 Milestone") and tracks practice output toward the next level.
- **Vote:** 3-0
- **Expected Impact:** Medium on Long-Term Retention and Identity Formation.
- **Tests Required:** Widget test verifying dual badge and progress bar in `ProfileScreen`.

---

### CD-010: Visual Celebration Accent on Daily Practice Completion
- **Decision:** Change
- **Target:** `app/lib/widgets/daily_cap_sheet.dart`
- **Why:** `[RESEARCH]` Fogg Behavior Model. Locks in the daily habit with an authentic celebratory accent and streak affirmation without APK bloat.
- **Vote:** 3-0
- **Expected Impact:** Low-Medium on Daily Habit Re-engagement.
- **Tests Required:** Widget test verifying celebration accent renders in both themes.
