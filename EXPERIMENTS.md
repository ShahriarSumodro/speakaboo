# Speakaboo Teaching & Product Experiments Log

This document tracks every teaching, pedagogical, and behavioral experiment conducted in Speakaboo. Every teaching feature must be backed by evidence or clearly labeled as an active experiment with hypotheses, variants, and metrics.

---

## Experiment Index

| ID | Feature / Hypothesis | Variants | Target Metric | Status |
|---|---|---|---|---|
| **EXP001** | **Correction Style (Prompts-First vs Recasts-First)**<br>*Hypothesis:* Prompts (hints/clarification) lead to higher learner self-correction than conversational recasts in free speech. | Variant A: Prompts-First (hint → retry → recast)<br>Variant B: Recast-First (natural recast in reply) | Self-repair rate (%), turn continuation rate, learner speech ratio | Active |
| **EXP002** | **Task Repetition ("Again, Faster")**<br>*Hypothesis:* Repeating the same short speaking task 3 times (with shorter time limits) improves WPM and reduces hesitation pauses. | Variant A: 3-Attempt Repetition Drill<br>Variant B: Single-Attempt Task | Words Per Minute (WPM), pause count, lexical variety, learner confidence rating | Active |
| **EXP003** | **Pre-Task Planning**<br>*Hypothesis:* Providing 30–60 seconds of guided planning with 3 structural prompts increases clause complexity and fluency. | Variant A: 45s Guided Pre-Task Planning<br>Variant B: Immediate Task Execution | Average turn length, vocabulary variety, perceived task difficulty | Active |
| **EXP004** | **Feedback Timing (Interim vs Delayed)**<br>*Hypothesis:* Delayed feedback preserves conversational immersion and reduces mid-session speaking anxiety. | Variant A: Interim (1 light prompt mid-session + full report)<br>Variant B: Delayed (zero interruption + detailed summary) | Session completion rate (%), next-day return rate, post-session confidence | Active |
| **EXP005** | **Pricing Model Elasticity**<br>*Hypothesis:* A low-commitment weekly pass yields higher initial paid conversion in Bangladesh than a flat monthly fee. | Variant A: 200 BDT / Month<br>Variant B: 60 BDT / Week<br>Variant C: 500 BDT / 3 Months | Paid conversion rate (%), gross revenue per learner, D30 subscriber retention | Active |
| **EXP006** | **High-Variability Phonetic Training (Perception-First)**<br>*Hypothesis:* Perception-first minimal-pair listening games across multiple TTS voices improve phonetic discrimination before speaking production. | Variant A: Multi-Voice Perception Drill → Speaking Check<br>Variant B: Production-Only Speaking Drill | Minimal pair discrimination score (%), target sound accuracy in free talk | Active |

---

## Detailed Experiment Specifications

### EXP001: Correction Style (Prompts-First vs Recasts-First)
- **Background / Evidence:** SLA research (Lyster & Ranta; Ellis et al.) suggests prompts push learners into "pushed output" and self-repair, while recasts maintain low-anxiety conversational flow.
- **Variant A (Prompts-First):** Companion detects high-priority error -> gives a gentle clarification prompt/hint -> allows 1 retry -> recasts if missed.
- **Variant B (Recast-First):** Companion embeds the corrected form naturally inside the spoken turn without explicit interruption.
- **Instrumentation:** Logged in `conversation_turns` with `correction_type` (`prompt`, `recast`) and `self_repaired` (boolean).

### EXP002: Task Repetition ("Again, Faster")
- **Background / Evidence:** Task-based language teaching (Bygate; Nation) indicates immediate task repetition develops automaticity and proceduralization.
- **Variant A:** Learner tells a 60s story -> gets brief feedback -> retells in 45s -> retells in 30s.
- **Variant B:** Standard single-turn conversation.
- **Instrumentation:** WPM, pause duration, filler word counts, and learner talk-time ratio logged per attempt.

### EXP003: Pre-Task Planning
- **Background / Evidence:** Skehan's cognitive model of task performance shows planning time reduces online processing load, freeing working memory for vocabulary and grammatical formulation.
- **Variant A:** Scenario screen displays 3 guiding prompts and key phrases with a 45-second timer before mic opens.
- **Variant B:** Scenario launches directly into the live conversation.
- **Instrumentation:** Syntactic complexity (turn length), hesitation pauses, and session completion rate.

### EXP004: Feedback Timing (Interim vs Delayed)
- **Background / Evidence:** Debated in SLA literature. Constant feedback can disrupt fluency and cause affective filter spikes; delayed feedback might lack contextual immediacy.
- **Variant A (Interim):** 1 soft prompt during the talk, detailed breakdown at end.
- **Variant B (Delayed):** 100% uninterrupted fluency practice, full feedback delivered in `SessionSummarySheet`.
- **Instrumentation:** Continuation rate, drop-off rate mid-session, learner anxiety rating (1-5 scale).

### EXP005: Pricing Model Elasticity
- **Background / Evidence:** In Bangladesh, mobile balance deduction and micro-transactions via bKash/Nagad favour smaller, frequent commitments over larger upfront payments.
- **Variants:**
  - A: 200 BDT/month (Standard)
  - B: 60 BDT/week (Micro-tier)
  - C: 500 BDT/3-months (Bundle)
- **Instrumentation:** Checkout intent creation, payment completion rate, customer acquisition cost vs LTV.

### EXP006: High-Variability Phonetic Training (Perception-First)
- **Background / Evidence:** Logan, Lively & Pisoni show robust phonetic learning requires hearing contrasting sounds produced by multiple distinct speakers.
- **Variant A:** Orpheus TTS plays minimal pairs using 3 different voices (`austin`, `daniel`, `diana`); learner chooses the correct sound, then repeats aloud.
- **Variant B:** Single-voice immediate imitation.
- **Instrumentation:** Listening accuracy (%), acoustic match confidence, pre- and post-test phoneme accuracy.
