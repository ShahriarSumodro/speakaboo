# Spec 03: Safety Filter (`backend/engine/safety.py`)

## Purpose
Protects learners (especially children) by filtering both user inputs and AI replies.
1. `check_content_safety(text, is_user_message, age_band)`:
   - Empty/None text -> `None`.
   - `age_band == "kid"` and `is_user_message`: checks mild profanity/bullying (`inappropriate_language`) -> returns `"inappropriate_language"`.
   - Checks `BLOCKED_PATTERNS` (`self_harm`, `violence`, `sexual`, `drugs`, `personal_info_request`).
   - If matched and `is_user_message=True` -> returns category string.
   - If matched and `is_user_message=False` -> raises `SafetyError(category=category)`.
2. `get_redirect_message(category, character_id=None)`:
   - Returns character-voiced redirect from `CHARACTER_REDIRECT_MESSAGES` if `character_id` and `category` exist; otherwise falls back to `REDIRECT_MESSAGES` or generic default.
3. `sanitize_for_child(text)`:
   - Replaces mild profanity with `***` case-insensitively.

## Invariants
- Unsafe AI output always raises `SafetyError` (never silently passes).
- Empty or benign English practice sentences return `None`.
