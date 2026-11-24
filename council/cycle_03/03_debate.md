# Council Cycle 3: Debate & Forced Dissent (Step 3)

**Date:** 2026-11-24  
**Cycle:** 03  

---

## 1. Debate on B011: Vocabulary Spoken Recall Micro-Timeout

### Proposal (Maya & Dr. Rahman)
In `VocabularyScreen`, add a 10-second automatic safety timeout when recording a spoken recall test, plus an explicit "Stop & Check" button so the learner can complete their turn immediately.

### Objections & Forced Dissent
- **Tanvir's 3 Concrete Objections:**
  1. Extra buttons on flashcard UI could clutter an otherwise simple interface.
  2. If the user accidentally taps mic, 10s might feel too long to wait if they don't see the stop button.
  3. Expected impact is Small; does it justify maintenance surface area?
- **Maya steelmans Tanvir:** "Tanvir wants to keep the flashcard interface hyper-minimal and avoid visual clutter for casual learners."
- **Dr. Rahman steelmans Tanvir:** "Tanvir is right that flashcards must be fast; an immediate tap to stop ensures learner control, while the 10s auto-stop is purely a safety net."
- **Consensus:** Approved as CD-011. Clean, compact mic state with explicit tap-to-stop and 10s maximum timeout.

---

## 2. Debate on B012: Teaching Engine Experiment Variant Badge in Settings

### Proposal (Maya)
In `SettingsScreen`, add a read-only informational tile showing the active pedagogical variant (e.g. `Teaching Engine: Recast Priority (EXP001)`).

### Objections & Forced Dissent
- **Dr. Rahman's 3 Concrete Objections:**
  1. Technical experiment codes like `EXP001` mean nothing to learners or parents.
  2. It must not imply that one student is getting a substandard education compared to another.
  3. It must be strictly non-interactive to prevent users toggling pedagogical parameters accidentally.
- **Maya steelmans Dr. Rahman:** "Dr. Rahman is guarding learner confidence and ensuring pedagogy is not perceived as an unverified experiment."
- **Consensus:** Approved as CD-012. Placed in the dev/about section of `SettingsScreen` as a neutral, read-only diagnostic badge.
