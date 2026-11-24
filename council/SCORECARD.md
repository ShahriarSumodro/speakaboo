# Speakaboo Council Scorecard

Scoring key: 1 (Poor) to 5 (Excellent).  
Evidence tags: `[RAN]` Verified by test/command; `[READ]` Verified by code audit; `[DATA]` Verified by telemetry/reports; `[RESEARCH]` Cited SLA/pedagogy study; `[HYPOTHESIS]` Needs empirical confirmation.

---

## Cycle 1 Baseline Scores

| Component / Subsystem | Real (1-5) | Usable (1-5) | Learning Value (1-5) | Return Pull (1-5) | Trust & Safety (1-5) | Perf & Cost (1-5) | Market Fit (1-5) | Avg | Top Priority Issues |
|---|---|---|---|---|---|---|---|---|---|
| **`TalkScreen` & Conversation Loop** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 4 `[DATA]` | 4 `[READ]` | **4.29** | P2: Real-time latency under 2G edge networks. |
| **`CharactersScreen` & Voice Catalog** | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | **4.57** | P3: Add more local cultural backstories. |
| **`CharacterDetailScreen` & Previews** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | **4.29** | P2: 2-minute trial counter needs explicit countdown timer. |
| **`MissionsScreen` & Daily Habits** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 5 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.71** | P2: Word of the day audio button to hear native pronunciation. |
| **`ProfileScreen` & Social Sharing** | 5 `[RAN]` | 4 `[READ]` | 3 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.43** | P2: CEFR level progression milestones not visibly mapped to next level. |
| **`OnboardingScreen` & Diagnostic** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | **4.29** | P1: Spoken placement test is 20s long; can intimidate nervous beginners. |
| **`ScenariosScreen` & Roleplay** | 5 `[RAN]` | 4 `[READ]` | 5 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.71** | P2: Guided pre-task planning sheet needs explicit 45s timer countdown. |
| **`TopicsScreen` & Free Discussion** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | **4.43** | P3: Starter prompt audio previews. |
| **`ShadowingScreen` & Pacing** | 5 `[RAN]` | 3 `[READ]` | 4 `[READ]` | 3 `[READ]` | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | **4.00** | P1: Approximate clarity label lacks fine-grained visual word highlighting. |
| **`VocabularyScreen` & Leitner Deck** | 5 `[RAN]` | 4 `[READ]` | 5 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | **4.57** | P2: Spoken recall test needs microphone auto-stop on silence. |
| **`ParentDashboardScreen` & PIN** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.57** | P2: Weekly PDF / WhatsApp summary export for parents. |
| **`SettingsScreen` & Privacy** | 5 `[RAN]` | 5 `[RAN]` | 3 `[READ]` | 3 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | **4.29** | P3: Feedback submission tile. |
| **`UnlockSheet` & Payments (Dual Flavor)**| 5 `[RAN]` | 4 `[READ]` | 3 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.43** | P1: Need explicit bKash/Nagad USSD fallback instructions for direct flavor. |
| **`DailyCapSheet` (Practice Completed)** | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | 5 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.86** | P3: Confetti particle animation on daily streak save. |
| **Backend Turn Pipeline & Recasts** | 5 `[RAN]` | 4 `[READ]` | 5 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 4 `[DATA]` | 5 `[READ]` | **4.57** | P2: Single focus error extraction needs strict fallback if LLM returns multiple. |
| **Experiments & Metrics Foundation** | 5 `[RAN]` | 4 `[READ]` | 5 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 4 `[READ]` | **4.57** | P2: Expose current experiment variant debug overlay in settings for testers. |
| **Safety Engine & Data Deletion** | 5 `[RAN]` | 4 `[READ]` | 4 `[READ]` | 4 `[READ]` | 5 `[RAN]` | 5 `[RAN]` | 5 `[READ]` | **4.57** | P3: Periodic safety flag auto-archive. |
