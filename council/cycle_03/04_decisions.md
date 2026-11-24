# Council Cycle 3: Decisions (Step 5)

**Date:** 2026-11-24  
**Cycle:** 03  
**Status:** Approved for Implementation (Batch of 2 Small Polish Items)  

---

### CD-011: Vocabulary Spoken Recall Micro-Timeout and Stop Button
- **Decision:** Change
- **Target:** `app/lib/screens/vocabulary_screen.dart`
- **Why:** `[RESEARCH]` Nation (2001). Provides an explicit stop/finish tap target during spoken vocabulary flashcard review and an automatic 10-second safety timeout so learners are never trapped in recording state.
- **Vote:** 3-0
- **Expected Impact:** Small on UX fluidity and battery preservation.
- **Tests Required:** Widget test verifying recording stop and timeout UI.

---

### CD-012: Teaching Engine Experiment Variant Debug Badge in Settings
- **Decision:** Add
- **Target:** `app/lib/screens/settings_screen.dart`
- **Why:** `[READ]` `settings_screen.dart`. Adds a clean read-only tile displaying the active pedagogical model variant (e.g. `Teaching Mode: Balanced Recast (EXP001)`) for internal quality audits and research verification.
- **Vote:** 3-0
- **Expected Impact:** Small on developer transparency and pedagogical verification.
- **Tests Required:** Widget test verifying the diagnostic tile renders in `SettingsScreen`.
