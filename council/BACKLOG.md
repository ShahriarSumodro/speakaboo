# Speakaboo Council Backlog

Ranked list of ideas and improvements evaluated by Maya, Dr. Rahman, and Tanvir, prioritized by learning value, retention pull, and feasibility.

---

## Ranked Backlog

| Rank | ID | Title | Proposer | Target Component | Expected Impact | Feasibility | Reason / Status |
|---|---|---|---|---|---|---|---|
| 1 | B001 | Low-Anxiety Beginner Diagnostic: 10s Friendly Icebreaker | Dr. Rahman & Tanvir | `OnboardingScreen` | High | High | A 20s test causes first-minute drop-off for shy learners. Replace with a 1-sentence friendly greeting test. |
| 2 | B002 | Visual Word-by-Word Alignment in Shadowing | Maya & Dr. Rahman | `ShadowingScreen` | High | Medium | Current shadowing gives an aggregate pace score; highlighting matching vs lagging words gives real phonetic practice. |
| 3 | B003 | Direct Distribution USSD / Manual Transaction ID Field | Tanvir | `UnlockSheet` | High | High | Many bKash/Nagad users pay via USSD (*247#) rather than web checkout. Allowing manual TrxID entry boosts conversion in Bangladesh. |
| 4 | B004 | Native Audio Pronunciation for Word of the Day | Tanvir & Dr. Rahman | `MissionsScreen` | Medium | High | Learners see the word and Bengali meaning, but cannot hear it spoken aloud without starting a conversation. |
| 5 | B005 | Guided Pre-Task Planning 45-Second Countdown | Dr. Rahman | `ScenariosScreen` / `TalkScreen` | Medium | High | SLA research (Ellis 2005) shows pre-task planning increases fluency and complexity; add visual timer and guiding questions. |
| 6 | B006 | Active Character Trial Countdown in TalkScreen | Maya | `TalkScreen` | Medium | High | When a learner uses a locked character on trial, show seconds remaining (e.g. "1:45 remaining") to avoid abrupt paywall shock. |
| 7 | B007 | One-Tap CEFR Milestones & Level Progress Bar | Tanvir | `ProfileScreen` | Medium | Medium | Map speaking minutes and vocabulary mastery to next CEFR level (A1 -> A2 -> B1) for visible progress. |
| 8 | B008 | WhatsApp Weekly Learning Report for Parents | Tanvir | `ParentDashboardScreen` | High | Medium | Parents in Bangladesh share achievements via WhatsApp. Enable 1-tap WhatsApp summary share. |
| 9 | B009 | Confetti Celebration on Daily Streak Save | Tanvir | `DailyCapSheet` | Low | High | Visual delight and dopamine reward when the daily habit is locked in. |
| 10 | B010 | Strict LLM Single-Focus Error Extraction Guard | Maya & Dr. Rahman | `backend/engine/correction.py` | Medium | High | If LLM mistakenly returns multiple grammar issues, enforce only the highest severity error is shown to the learner. |
