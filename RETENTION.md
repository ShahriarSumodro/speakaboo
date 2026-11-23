# Speakaboo Retention Architecture (North Star)

## 1. Core Principle: Build For Coming Back
Speakaboo succeeds only if learners in Bangladesh form a durable daily speaking habit. Every feature, screen, notification, and response is optimized to make the learner or parent return tomorrow.

---

## 2. Retention Mechanisms

### 1. Fast First Win
- **Target:** New user speaks and receives a warm, spoken AI reply within 60 seconds of initial launch.
- **Implementation:** Streamlined initial onboarding flow that allows a quick 1-tap start with Farmer Reggie. Zero complex setup before the first conversation.

### 2. Daily Habit Loop
- **Trigger:** Friendly local notification at user's configured preferred time (e.g., 8:00 PM).
- **Tiny Action:** 2-minute "Daily Talk" session designed to be completed easily.
- **Reward:** XP burst, streak increment animation, character celebration ("Harvest well done!").
- **Investment:** Saved vocabulary cards added to the Leitner box, progress reflected on the weekly ring.

### 3. Streak That Forgives
- **Timezone:** Calculated strictly in `Asia/Dhaka` (UTC+6).
- **Streak Freeze:** 1 free freeze earned per 7-day streak milestone; automatic activation on missed day.
- **Streak Repair:** Missed day can be restored by completing 2 practice sessions the following day.
- **Tone:** Encouraging and empathetic ("Life happens! Let's get right back into it") rather than guilt-inducing.

### 4. Unfinished Business (Tomorrow Hook)
- At the end of every practice session, the character leaves an engaging cliffhanger or teaser for tomorrow:
  - *Farmer Reggie:* "Tomorrow, we're inspecting the watermelon patch — I'll teach you how to describe flavors!"
  - *Detective Kabir:* "A new clue just arrived from Lalbagh Fort. Meet me tomorrow to inspect it!"
  - *Professor Anika:* "Tomorrow we'll observe Mars. Think of 3 questions to ask me!"

### 5. Visible Progress
- Weekly spoken minutes counter against a clear goal.
- Spaced-repetition mastery curve (Box 1 through Box 5).
- Level-up celebration with animated badges.
- "You said X before, now you say Y" before/after comparison chips.

### 6. Character Relationship & Memory
- Characters remember:
  - Learner's display name
  - Age band / goal (e.g., IELTS, job interview, school exams)
  - Last conversation topic and unresolved storylines
- Greetings vary based on time of day, streak status, and recent accomplishments.

### 7. Social Proof & Referral
- Generate a shareable, beautifully formatted progress card (Streak days, Spoken Minutes, Level, Favorite Character).
- Ready for 1-tap sharing to WhatsApp and Facebook.
- Referral reward system granting streak freezes or premium character trial minutes.

### 8. Parent Loop
- Weekly parent digest (viewable in Parent Dashboard or exported) showing:
  - Total minutes spoken
  - New words acquired
  - Accuracy and fluency improvement trends
  - Safety filter confirmation (100% safe, 0 harmful flags)
- Clearly proves value for bKash/Nagad monthly subscription renewal.

### 9. Return Triggers Beyond Notifications
- Daily "Word of the Day" with interactive pronunciation practice.
- Android quick-start app shortcuts directly into "Daily Talk".

### 10. Analytics & Retention Reporting
- Event schema:
  - `user_registered`, `session_started`, `session_completed`
  - `turn_completed`, `mission_completed`, `streak_extended`, `streak_frozen`
  - `word_reviewed`, `share_card_generated`, `paywall_viewed`, `payment_completed`
- Metric tracking:
  - Day 1, Day 7, Day 30 retention cohorts
  - Average daily spoken minutes
  - Mission completion rate
  - Drop-off points by screen
- Automated internal CLI report: `backend/scripts/retention_report.py`.

### 11. User Respect & Ethics
- No deceptive countdown timers or dark patterns.
- Child-safe design: no external advertising, no personal data harvesting.
- Daily notifications capped to 1 per day, easily toggled off in Settings.
