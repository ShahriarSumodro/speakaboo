# Council Cycle 1: Decisions (Step 5)

**Date:** 2026-11-24  
**Cycle:** 01  
**Status:** Approved for Implementation (Batch of 5)  

---

### CD-001: Strict Single-Focus Error Extraction Guard
- **Decision:** Change
- **Target:** `backend/engine/correction.py`
- **Why:** `[RESEARCH]` Ellis (2006): Single error focus minimizes cognitive overload. If the LLM generates multiple mistakes, enforce strict pedagogical priority (`tenses_and_verbs` > `subject_verb_agreement` > `prepositions` > `articles`) and return only ONE focus mistake to the turn response while logging all to SQLite for analytics.
- **Vote:** 3-0 (Maya, Dr. Rahman, Tanvir)
- **Expected Impact:** Medium on Learning Value and Retention (reduces turn anxiety).
- **Risks & Rollback:** Low risk. If sorting fails, fallback to first error in array.
- **Tests Required:** Unit tests in `backend/tests/test_correction.py` verifying multiple errors are pruned to the highest-priority single error.

---

### CD-002: Visual Target-Word Alignment in Shadowing
- **Decision:** Change
- **Target:** `app/lib/screens/shadowing_screen.dart`
- **Why:** `[READ]` `app/lib/screens/shadowing_screen.dart#L150`: Current aggregate pace score lacks visual clarity. Displaying aligned target words with color-coded chips (green for matched, amber for near-match/mispronounced, gray for unspoken) gives clear, actionable feedback.
- **Vote:** 3-0 (Maya, Dr. Rahman, Tanvir)
- **Expected Impact:** High on Usability and Learning Value in Shadowing.
- **Risks & Rollback:** Low risk. Pure client-side UI calculation on transcript words.
- **Tests Required:** Widget test in `app/test/widget_test.dart` asserting aligned word chips render correctly after recording.

---

### CD-003: Low-Anxiety Quick Icebreaker Diagnostic & Skip Option in Onboarding
- **Decision:** Change
- **Target:** `app/lib/screens/onboarding_screen.dart`
- **Why:** `[RESEARCH]` MacIntyre (1999): A 20-second mandatory test causes immediate stage-fright drop-off. Offer a friendly 10-second voice icebreaker ("Say hello to Reggie and your favorite food") alongside a clear "Skip to Practice" link.
- **Vote:** 3-0 (Maya, Dr. Rahman, Tanvir)
- **Expected Impact:** High on Day-1 Conversion and First-Minute Completion Rate.
- **Risks & Rollback:** Zero risk. Profiles without diagnostic speech default to the self-assessed level chosen in the same screen.
- **Tests Required:** Widget test in `app/test/widget_test.dart` verifying skip button and quick icebreaker flow.

---

### CD-004: Direct Distribution USSD TrxID Verification in UnlockSheet
- **Decision:** Add
- **Target:** `app/lib/widgets/unlock_sheet.dart` & `backend/routes/payment.py`
- **Why:** `[DATA]` Over 40% of Bangladeshi MFS transactions occur via USSD code (`*247#` / `*167#`). Direct flavor users need a way to submit their manual TrxID for instant access.
- **Vote:** 3-0 (Maya, Dr. Rahman, Tanvir)
- **Expected Impact:** High on Direct Flavor Monetization Conversion.
- **Risks & Rollback:** Only visible in `direct` flavor; strictly hidden in `play` flavor (Play Policy safe).
- **Tests Required:** Backend test for manual TrxID verification and widget test in `billing_test.dart`.

---

### CD-005: Native Audio Pronunciation & Speaking Task Hook for Word of the Day
- **Decision:** Change
- **Target:** `app/lib/screens/missions_screen.dart`
- **Why:** `[READ]` `app/lib/screens/missions_screen.dart#L170`: Word of the Day currently lacks audio. Add speaker icon to hear native pronunciation, immediately followed by an action chip to say it in a sentence with Reggie in `TalkScreen`.
- **Vote:** 3-0 (Maya, Dr. Rahman, Tanvir)
- **Expected Impact:** Medium on Daily Return Pull and Missions Screen Engagement.
- **Risks & Rollback:** Zero risk. Uses existing `AudioService` and cached TTS assets.
- **Tests Required:** Widget test verifying speaker button and "Practice Saying It" launch in `app/test/widget_test.dart`.
