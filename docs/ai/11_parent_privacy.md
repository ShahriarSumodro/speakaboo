# Spec 11: Parent Dashboard & Privacy (`backend/routes/parent.py`, `backend/routes/privacy.py`)

## Purpose
Provides parent-gated weekly summaries, safety incident logs, GDPR/COPPA data export, and full user data purge.

## Rules & Invariants
1. All `/api/parent/{user_id}/*` and `/api/privacy/export/{user_id}`, `DELETE /api/privacy/user/{user_id}` routes require `get_current_user_id` AND `verify_user_access(current_user_id, user_id)`.
2. `get_parent_summary` aggregates last 7 days of `daily_usage` (Asia/Dhaka), streak/XP/level, vocabulary count, and last 30 days of `safety_flags` grouped by category.
3. `export_user_data` explicitly sets `raw_audio_stored: False` and exports user, profile, progress, vocabulary, summary, and safety flags.
4. `delete_user_account_and_data` purges all 16 user-scoped tables via `repo.delete_user_data(user_id)`.
