# Council Cycle 2: Cross-Examination (Step 3)

**Date:** 2026-11-24  
**Cycle:** 02  
**Status:** Complete  

---

## Cross-Examination Questions & Answers

### Q1 (Maya to Dr. Rahman): "Will the 45s planning sheet slow down a learner who wants to do multiple scenario runs in a row?"
- **Answer (Dr. Rahman):** `[RESEARCH]` SLA findings emphasize that planning is most impactful before the *first* attempt at a new communicative scenario. If a student is repeating the same scenario (e.g. attempt 2 or 3), planning is already internalized.
- **Design:** The pre-task planning sheet has a prominent, primary "Start Speaking Now" button that allows instant bypass at second 0. The 45-second timer is an optional countdown guide, not a barrier.

### Q2 (Maya to Tanvir): "Does the WhatsApp summary export expose the user ID, device token, or any child PII?"
- **Answer (Tanvir):** `[READ]` `app/lib/screens/parent_dashboard_screen.dart#L120`. Absolute zero PII. The exported text is formatted strictly as an inspirational accomplishment:
  `"🌟 Proud parent moment! My child practiced English speaking for 25 minutes this week on Speakaboo (3-day streak)! #Speakaboo #LearningEnglish"`
  No user IDs, tokens, IP addresses, or transcripts are included.

### Q3 (Maya to Dr. Rahman): "How do we calculate speaking minutes needed for the next CEFR level honestly without making false scientific claims?"
- **Answer (Dr. Rahman):** `[RESEARCH]` Cambridge English Language Assessment guidelines state that advancing one CEFR sub-band typically requires 50–100 hours of guided study, but in an AI speaking app, we track active speaking minutes towards milestone benchmarks.
- **Honesty Rule:** We label it: "Practice Minutes toward Next Level Milestone (e.g. 15 / 30 mins to Bronze Speaker)". We never claim an absolute linguistic guarantee; we track real cumulative oral output.

### Q4 (Dr. Rahman to Maya): "How will the trial countdown badge in TalkScreen update without triggering heavy, battery-draining setState rebuilds?"
- **Answer (Maya):** `[READ]` `app/lib/screens/talk_screen.dart`. Instead of a high-frequency millisecond timer that rebuilds the entire widget tree, we update a simple 1-second ticker only while the user is actively engaged with a trial character. The badge is an isolated compact widget, ensuring 60fps performance and negligible CPU/battery consumption on low-end Android devices.

### Q5 (Dr. Rahman to Tanvir): "Will the WhatsApp parent report encourage unhealthy parental comparison or guilt in Bangladesh?"
- **Answer (Tanvir):** `[RESEARCH]` Ryan & Deci (2000). The template copy is framed entirely around personal effort and habit consistency ("practiced for 15 minutes today!"), never ranking or percentile comparisons against other children. It fosters positive affirmation at home.

### Q6 (Dr. Rahman to Maya): "Does the pre-task planning sheet store user text notes, and if so, where?"
- **Answer (Maya):** `[READ]` `backend/engine/safety.py`. The planning sheet is designed for oral preparation (cognitive rehearsal), so it provides 3 scenario prompts and key vocabulary chips. If a learner types notes, they are held in ephemeral Flutter state for that session only and never sent or stored as raw text, preserving our privacy guarantees.

### Q7 (Tanvir to Maya): "Can the WhatsApp share work even if the user doesn't have WhatsApp installed?"
- **Answer (Maya):** `[READ]` `app/lib/widgets/share_progress_card.dart`. Yes, we use standard Android Intent sharing (`Share.share(...)`) or fallback to clipboard copy if the specific app package is unavailable, accompanied by a friendly "Copied to clipboard!" toast.

### Q8 (Tanvir to Dr. Rahman): "What are the 3 guiding questions for the pre-task planning sheet in roleplays?"
- **Answer (Dr. Rahman):** `[RESEARCH]` Ellis (2005) Task-Based Language Teaching (TBLT):
  1. **Goal:** "What is your main goal in this conversation?" (e.g. Order your favorite food)
  2. **Key Phrases:** "Which 2-3 power phrases will you use?" (e.g. *I'd like to have...*, *Could you recommend...?*)
  3. **Anticipation:** "What question might the other person ask you?" (e.g. *Would you like anything to drink?*)
  This 3-question scaffold completely unlocks confident fluency before the mic opens.

### Q9 (Tanvir to Maya): "What happens when the 2-minute trial reaches 0:00 during an active microphone turn?"
- **Answer (Maya):** `[READ]` `backend/routes/conversation.py#L160`. Good UX rule: we never abruptly cut off a student mid-sentence. If the user is currently speaking when time expires, the turn is allowed to finish and receive its AI reply. After the character responds, the warm completion dialog and `UnlockSheet` smoothly appear.
