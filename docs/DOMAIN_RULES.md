# Speakaboo — Domain Rules

1. **Pedagogy & Corrections:**
   - Replies stay brief (1-2 sentences, <=200 chars) to maximize learner talk time.
   - Accuracy mode picks at most ONE high-priority error (`tenses_and_verbs` > `subject_verb_agreement` > `prepositions` > `articles` > `word_choice`).
   - Fluency mode sets `correction: null` and recasts naturally in the reply.
2. **Safety & Privacy:**
   - Every user message and AI reply passes `check_content_safety()`. Unsafe AI replies raise `SafetyError` and are replaced with safe fallbacks.
   - Kid band (`age_band == "kid"`) additionally filters mild profanity (`inappropriate_language`).
   - Raw audio is NEVER stored; `DELETE /api/privacy/user/{user_id}` purges all 16 user-scoped tables.
3. **Entitlements & Caps:**
   - Daily limits (Asia/Dhaka UTC+6): `FREE` = 10 min, `BASIC` (or active `plan` entitlement) = 30 min, `PREMIUM` = 120 min.
   - Locked characters allow a 120-second (2-minute) free trial before requiring unlock.
4. **Gamification & SRS:**
   - Streaks roll over at midnight `Asia/Dhaka` (UTC+6); 1-day miss can be saved by `streak_freeze_count`, otherwise `previous_streak` is saved for streak repair.
   - Leitner SRS intervals: Box 1 = 1d, Box 2 = 3d, Box 3 = 7d, Box 4 = 14d, Box 5 = 30d.
5. **Payments:**
   - Verification is idempotent on `payments.status == "completed"`.
   - Manual TrxID verification enforces global uniqueness of `transaction_id`.
