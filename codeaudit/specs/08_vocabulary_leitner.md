# Spec 08: Vocabulary & Spaced Repetition (`backend/engine/vocabulary.py`, `sqlite_repo.py`)

## Purpose
Captures newly learned words and corrections into a per-user notebook scheduled with a 5-box Leitner spaced repetition system.

## Rules & Invariants
1. `add_word` normalizes `word_or_phrase.strip().lower()` and deduplicates against existing items in the user's notebook.
2. `add_from_turn` captures words with length > 1 and formats corrections as `"{original} -> {better}"`.
3. Leitner box intervals: Box 1 = 1 day, Box 2 = 3 days, Box 3 = 7 days, Box 4 = 14 days, Box 5 = 30 days (using `dhaka_date_add`).
4. `review_vocabulary(item_id, remembered)`:
   - `remembered=True` -> `min(5, box + 1)`
   - `remembered=False` -> reset to Box 1
   - Increments `times_reviewed` and updates `next_review_date`.
5. `get_due_vocabulary(user_id, date)` returns items where `next_review_date <= today` ordered ascending.
