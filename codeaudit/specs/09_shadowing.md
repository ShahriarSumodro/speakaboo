# Spec 09: Shadowing Scoring (`backend/engine/shadowing.py`)

## Purpose
Evaluates learner shadowing attempts against curated practice scripts.

## Rules & Invariants
1. `_clean_words` extracts lowercase `[a-zA-Z0-9']+` tokens.
2. Accuracy score: multiset word-count overlap (`matched_words = sum(min(user[w], target[w]))`), F1 of precision & recall scaled to `0..100`.
3. Pace (WPM): `(len(user_words) / duration_seconds) * 60.0` (0 if `duration_seconds <= 0`).
4. Pace score: `max(0.0, 100.0 - abs(pace_wpm - target_wpm) / target_wpm * 100.0)` (50.0 if `pace_wpm == 0` or `target_wpm <= 0`).
5. Overall score: `round(0.7 * accuracy_score + 0.3 * pace_score, 1)`.
6. Returns up to 5 unique `missed_words` and `added_words`.
