# Council Cycle 2: Debate of Top Issues (Step 4)

**Date:** 2026-11-24  
**Cycle:** 02  
**Status:** Complete  

---

## 1. Pre-Task Planning Scaffold before Roleplay Scenarios (B005)

### Proposal (Dr. Rahman)
Before transitioning into `TalkScreen` for any roleplay scenario in `ScenariosScreen`, display a guided bottom sheet:
- Recommended 45s countdown timer.
- 3 scaffold prompts: (1) Main Goal, (2) 2-3 Power Phrases, (3) Anticipate the Partner's Question.
- A prominent "Start Speaking Now" button for instant bypass.

### Objections & Forced Dissent
- **Maya's 3 Concrete Objections:**
  1. An extra intermediate sheet adds one more tap before the user can speak.
  2. If the user presses hardware back during the timer, audio service or state could get confused.
  3. The timer could cause battery drain if not disposed on unmount.
- **Tanvir's 3 Concrete Objections:**
  1. Casual learners might feel like they are doing homework before they even start talking.
  2. If the guiding phrases are too complex, beginner confidence will plummet.
  3. Tapping "Start Speaking Now" must be effortless with zero animation lag.

### Steelmans & Compromise
- **Dr. Rahman steelmans Maya & Tanvir:** "You worry that an extra screen introduces friction and homework vibes that break casual speaking momentum."
- **Maya steelmans Dr. Rahman:** "Dr. Rahman has 20 years of empirical evidence that without 30 seconds of cognitive preparation, learners freeze on turn 1 of an unfamiliar roleplay."
- **Consensus:** Approved. The sheet has a clean 45-second circular progress indicator, 3 friendly bullet tips, and a prominent primary button: "Ready! Start Roleplay".

---

## 2. 1-Tap WhatsApp Learning Report for Parents (B008)

### Proposal (Tanvir)
In `ParentDashboardScreen` (protected by 4-digit PIN), add an "Export Weekly Achievement to WhatsApp" button that formats a positive, proud parent summary message and opens the Android share sheet.

### Objections & Forced Dissent
- **Maya's 3 Concrete Objections:**
  1. Hardcoding WhatsApp URI can fail if WhatsApp is not installed.
  2. Formatting must handle Bengali and English characters cleanly.
  3. Parent PIN verification must not be bypassed by deep links.
- **Dr. Rahman's 3 Concrete Objections:**
  1. Must not display grammar mistake counts or negative feedback that could lead parents to criticize the child.
  2. Must highlight speaking effort and consistency (minutes and streak), not test scores.
  3. The copy must feel authentic and warm, not like a corporate advertisement.

### Steelmans & Compromise
- **Tanvir steelmans Maya & Dr. Rahman:** "You want to protect kid emotional safety and avoid share intent crashes."
- **Dr. Rahman steelmans Tanvir:** "Tanvir recognizes that when parents share progress with family, they become deeply invested in maintaining the subscription."
- **Consensus:** Approved. Generates positive, non-judgmental summary: `"🌟 Proud moment! [Child] spoke English for [X] minutes this week across [Y] days with Speakaboo! Keep shining! 🚀"`. Uses system share sheet with clipboard fallback.

---

## 3. Active Character Trial Countdown Badge in TalkScreen (B006)

### Proposal (Maya)
When a learner is using a locked character (e.g. Detective Kabir or Prof. Anika) on the 2-minute free trial, display a compact top-bar chip: an hourglass icon with remaining trial time (e.g. "1:45 trial").

### Objections & Forced Dissent
- **Dr. Rahman's 3 Concrete Objections:**
  1. A ticking clock can create speech anxiety and rushed cadence.
  2. If the trial ends mid-sentence, cutting off the student breaks flow.
  3. The color must not be red (stress-inducing).
- **Tanvir's 3 Concrete Objections:**
  1. A trial badge might make the character feel commercial rather than like a friend.
  2. We must ensure the unlock bottom sheet only appears *after* the character finishes their final spoken response.
  3. The badge must not crowd out the character's name or level badge.

### Steelmans & Compromise
- **Maya steelmans Dr. Rahman & Tanvir:** "You want to protect conversational immersion and prevent time-pressure anxiety."
- **Tanvir steelmans Maya:** "Maya understands that hitting a paywall unexpectedly with zero advance knowledge feels like a bait-and-switch trap."
- **Consensus:** Approved. The chip uses neutral amber styling (`SpeakabooTheme.warning.withValues(alpha: 0.15)`), displays remaining time, never cuts off a turn in progress, and Kabir/Anika delivers a spoken farewell before the unlock sheet opens.

---

## 4. Dual Plain-Language Identity & Formal CEFR Progress Bar (B007)

### Proposal (Tanvir & Dr. Rahman)
In `ProfileScreen`, upgrade the level card to show:
- Emotional Identity: e.g. **"Confident Everyday Speaker"**
- Formal Certification: e.g. **"(CEFR B1 Milestone)"**
- Progress bar: "Practice minutes toward next milestone (e.g. 15 / 30 mins to Bronze Speaker)".

### Objections & Forced Dissent
- **Maya's 3 Concrete Objections:**
  1. If milestone minutes are hardcoded without backend syncing, it could get out of sync with real database totals.
  2. Text wrapping on small phone screens could clip long strings.
  3. Must handle all three levels (`beginner`, `intermediate`, `advanced`) with zero null errors.
- **Dr. Rahman's 3 Concrete Objections:**
  1. Must explicitly state that milestones represent practice output, not an accredited exam certificate.
  2. The gap between milestones must feel attainable (e.g. 15-30 min increments), not 100 hours.
  3. Color coding must align with Speakaboo's warm theme.

### Steelmans & Compromise
- **Consensus:** Approved. Uses `UserProfile.level` and `total_words_spoken` / `weekly_minutes`, displaying dual badges and a clean progress indicator towards the next level milestone.

---

## 5. Visual Celebration Accent on Daily Practice Completion (B009)

### Proposal (Tanvir)
Enhance `DailyCapSheet` with a celebratory visual accent (warm starburst banner and animated celebration face) when the daily practice goal is achieved.

### Objections & Forced Dissent
- **Maya's 3 Concrete Objections:**
  1. Heavy animation libraries (e.g. Lottie) add 5MB to APK size.
  2. Must not cause frame drops on low-end 2GB RAM phones.
  3. Must render cleanly in both light and dark themes.
- **Dr. Rahman's 3 Concrete Objections:**
  1. Celebration should feel sincere, not hollow.
  2. The message must reaffirm the learner's identity: "You showed up and spoke today!"
  3. Reaffirm that their streak is safely locked in.

### Steelmans & Compromise
- **Consensus:** Approved. Implemented using pure Flutter lightweight procedural widgets and icons (`Icons.stars_rounded`, animated pulse container) without any heavy third-party assets, ensuring 0KB APK overhead and 60fps performance on all devices.

---

## Voting on Cycle 2 Decisions
- Maya: **YES** on all 5.
- Dr. Rahman: **YES** on all 5.
- Tanvir: **YES** on all 5.
- Unanimous 3-0. Zero safety vetoes. Proceeding to Decision Records (Step 5).
