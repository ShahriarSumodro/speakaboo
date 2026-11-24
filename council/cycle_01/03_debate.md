# Council Cycle 1: Debate of Top Issues (Step 4)

**Date:** 2026-11-24  
**Cycle:** 01  
**Status:** Complete  

---

## Issue 1: Low-Anxiety Onboarding Icebreaker vs Heavy 20-Second Diagnostic (P1)

### Proposal (Dr. Rahman)
Replace the mandatory 20-second placement speech test in `OnboardingScreen` with a welcoming, low-anxiety 10-second icebreaker ("Say hello to Reggie and tell him your favorite food or hobby") with an explicit 1-tap "Skip for Now" button.
- `[RESEARCH]` MacIntyre (1999) Foreign Language Classroom Anxiety: First encounters are the peak drop-off vulnerability point for self-conscious learners.
- `[READ]` `app/lib/screens/onboarding_screen.dart#L130`: Current UI shows a 20s recording block with technical wording that causes immediate stage fright.

### Forced Dissent & Objections
- **Maya's 3 Concrete Objections:**
  1. A 10-second audio clip has insufficient token sample size for Whisper STT to reliably measure pause distribution or lexical diversity.
  2. If the user skips the test, the database `UserProfile.level` is uncalibrated and requires a fallback value.
  3. If speech recording fails or is granted no microphone permission, skipping must be gracefully handled without app crashes.
- **Tanvir's 3 Concrete Objections:**
  1. If the icebreaker feels too lightweight, serious adult learners or IELTS candidates might feel the app is a toy.
  2. Skipping reduces the "sunk cost" commitment effect that secures Day-1 return.
  3. We might lose an opportunity to showcase our AI's diagnostic sophistication in the very first minute.

### Steelmans
- **Dr. Rahman steelmans Maya & Tanvir:** "You worry that a casual 10-second icebreaker sacrifices diagnostic precision and lowers perceived educational authority for ambitious IELTS test-takers."
- **Maya steelmans Dr. Rahman:** "Dr. Rahman is right that a nervous Bangladeshi student who freezes during a 20-second test uninstalls the app immediately, making diagnostic precision moot."

### Rebuttal & Compromise
- **Consensus Resolution:** 
  1. The onboarding diagnostic offers two clear options: (A) "Quick 10s Voice Hello" (Recommended for beginners/teens) and (B) "Take Full 20s Placement Diagnostic" (Recommended for IELTS/Job preparation), plus a "Skip to Practice" link.
  2. If skipped, default level is set from the user's self-assessed choice (Beginner/Intermediate/Advanced) and updated automatically on turn 1.
  3. Microphone permission denial is handled gracefully with an informative snackbar and seamless progression to home.

---

## Issue 2: Visual Target-Word Alignment in Shadowing vs Opaque Aggregate Scores (P1)

### Proposal (Maya)
Enhance `ShadowingScreen` to align the student's spoken transcript against the target sentence word-by-word. Render matched words in vivid green, near matches in amber, and missing words in muted gray. Maintain strict adherence to truthfulness by explicitly labeling it: "Target Word Match & Pacing (Approximate)".
- `[READ]` `app/lib/screens/shadowing_screen.dart#L150`: Currently only displays an opaque overall pace percentage.

### Forced Dissent & Objections
- **Dr. Rahman's 3 Concrete Objections:**
  1. Word matching based on Whisper STT transcripts can penalize students with non-standard regional accents even when their rhythm and fluency are acceptable.
  2. If a student inserts a natural pause or filler word ("um", "uh"), string alignment algorithms can offset all subsequent words.
  3. Visual red highlights on single words can induce hyper-focus on individual phonemes rather than sentence prosody.
- **Tanvir's 3 Concrete Objections:**
  1. Complex word-by-word UI can look cluttered on small 5-inch low-end phone displays.
  2. If the alignment calculation is heavy, it can lag older Android processors during render.
  3. Learners may get frustrated if an accent misrecognition gives them an amber word despite speaking clearly.

### Steelmans
- **Maya steelmans Dr. Rahman & Tanvir:** "You worry that crude string alignment will punish legitimate Bengali English accents and create visual noise that distracts from sentence rhythm."
- **Dr. Rahman steelmans Maya:** "Maya recognizes that without visual feedback on which specific words were spoken or missed, shadowing feels like a black box where the user doesn't know what to improve."

### Rebuttal & Compromise
- **Consensus Resolution:**
  1. Use tokenized Levenshtein alignment with a relaxed match threshold (Levenshtein distance <= 1 counts as a match, distance 2 counts as near match).
  2. Clean, high-contrast visual display: chips wrap gracefully on mobile screens.
  3. Add an encouraging headline: "Great rhythm! 5 of 6 target words clearly matched."
  4. Label: "Rhythm and Fluency Practice (Approximate alignment)".

---

## Issue 3: Direct Distribution Manual TrxID Input & USSD Guidance in UnlockSheet (P1)

### Proposal (Tanvir)
In the `direct` build flavor of `UnlockSheet`, add a collapsible "Paid via bKash/Nagad USSD or App? Enter TrxID" section with a 10-character transaction ID input field and step-by-step USSD instructions (`*247#` / `*167#`).
- `[READ]` `app/lib/widgets/unlock_sheet.dart#L110`: Currently assumes all payments go through browser redirect. In Bangladesh, over 40% of MFS transactions occur via USSD or manual Send Money.

### Forced Dissent & Objections
- **Maya's 3 Concrete Objections:**
  1. Users might submit random 10-character gibberish to unlock subscriptions for free.
  2. Manual TrxID reconciliation requires backend verification logic and rate limiting.
  3. If we offer manual entry, users may abandon the automated web checkout flow.
- **Dr. Rahman's 3 Concrete Objections:**
  1. A transaction input screen can look commercial and intimidating to students seeking an educational app.
  2. Confusion around payment instructions might distract learners from their daily habit.
  3. If verification is delayed, students will become anxious and complain in reviews.

### Steelmans
- **Tanvir steelmans Maya & Dr. Rahman:** "You fear fraudulent TrxIDs and payment clutter compromising the clean, trustworthy educational atmosphere."
- **Maya steelmans Tanvir:** "Tanvir understands that in Bangladesh, if you don't support how real people actually pay (USSD *247#), you have zero conversion regardless of how good the app is."

### Rebuttal & Compromise
- **Consensus Resolution:**
  1. Web checkout remains the primary prominent 1-tap option in `direct` flavor.
  2. Underneath, an expandable secondary tile: "Paid via bKash/Nagad USSD? Verify TrxID".
  3. The backend validates TrxID format (10-char alphanumeric), checks for duplicates in SQLite `payments`, and grants access idempotently.
  4. In `play` flavor, this entire section is strictly hidden (Play Policy compliance).

---

## Issue 4: Native Audio Pronunciation + Speaking Hook for Word of the Day (P2)

### Proposal (Tanvir)
Add a speaker button to the Word of the Day card in `MissionsScreen` that plays native Orpheus audio pronunciation, followed by an immediate action chip: "Say it in a sentence with Reggie! (+20 XP)".
- `[READ]` `app/lib/screens/missions_screen.dart#L170`: Word of the Day currently shows word and Bengali definition, but has no audio playback.

### Forced Dissent & Objections
- **Dr. Rahman's 3 Concrete Objections:**
  1. Listening without an immediate speaking task is passive rote learning.
  2. TTS synthesis for arbitrary words could mispronounce specialized vocabulary if phonetic stress isn't annotated.
  3. Word of the day might distract the learner from their main daily conversation mission.
- **Maya's 3 Concrete Objections:**
  1. Generating audio on the fly for the word of the day increases backend TTS API turn cost.
  2. Audio playback requires network requests if audio is not cached on disk.
  3. Audio player state (playing/stopped) must be managed to prevent audio overlapping with background sounds.

### Steelmans
- **Tanvir steelmans Dr. Rahman & Maya:** "You want to protect learner talk time and prevent unnecessary TTS API costs on passive listening."
- **Dr. Rahman steelmans Tanvir:** "Tanvir sees that hearing the word spoken aloud is the essential bridge that empowers a student to actually speak it."

### Rebuttal & Compromise
- **Consensus Resolution:**
  1. Audio files for the curated Word of the Day catalog are synthesized once using Orpheus TTS and cached permanently on the backend / app assets. Zero dynamic cost.
  2. Tapping the speaker icon plays the clear audio pronunciation.
  3. Immediately upon playback completion, an action button activates: "Practice Saying It with Reggie", opening `TalkScreen` with the word pre-selected.

---

## Issue 5: Strict LLM Single-Focus Error Extraction Guard (P2)

### Proposal (Maya & Dr. Rahman)
In `backend/engine/correction.py`, add a deterministic pedagogical priority filter that guarantees at most ONE single focus error is returned, strictly prioritizing high-communicative-impact errors (`tenses_and_verbs` > `subject_verb_agreement` > `prepositions` > `articles`).
- `[READ]` `backend/engine/correction.py#L90`: Currently parses the LLM JSON, but if the LLM hallucinated multiple mistakes in the JSON array, multiple chips could be rendered, overwhelming the student.

### Forced Dissent & Objections
- **Tanvir's 3 Concrete Objections:**
  1. If we drop secondary errors, the student might repeat that secondary mistake in subsequent turns.
  2. The learner might wonder why a glaring article error wasn't corrected if a minor verb error was flagged.
  3. If the backend drops errors silently, telemetry on total learner mistake frequency is skewed.
- **Maya's 3 Concrete Objections (internal devil's advocate):**
  1. What if the primary error detected by the LLM is a false positive? We lose the chance to surface a legitimate secondary error.
  2. Adding sorting and filtering logic adds minor per-turn processing overhead.
  3. Tests must be updated across all correction test suites.

### Steelmans
- **Dr. Rahman steelmans Tanvir:** "Tanvir wants maximum pedagogical thoroughness so learners don't miss learning opportunities."
- **Tanvir steelmans Dr. Rahman:** "Dr. Rahman has seen 20 years of classrooms freeze up when a teacher corrects three things at once. One clear win per turn builds unstoppable speaking momentum."

### Rebuttal & Compromise
- **Consensus Resolution:**
  1. All detected errors are logged in SQLite `mistake_logs` for background analytics and long-term spaced repetition.
  2. But in the immediate conversational turn UI, the backend extracts and displays ONLY the single highest-priority error.
  3. The learner never receives more than one correction chip per turn.

---

## Voting on Top Decisions
All 3 experts vote **YES** on the compromises reached for Issues 1, 2, 3, 4, and 5.
- Zero safety vetoes.
- Gate criteria verified. Ready for Step 5 (Decide) and Step 6 (Implement).
