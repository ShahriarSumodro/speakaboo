# Spec 06: Entitlements & Daily Caps (`backend/routes/conversation.py`, `backend/routes/usage.py`)

## Purpose
Enforces free/paid daily speaking minute limits and locked character 2-minute free trials.

## Rules & Invariants
1. Daily limits by plan (`Plan` enum): `FREE` = 10 min/day, `BASIC` = 30 min/day, `PREMIUM` = 120 min/day (in Asia/Dhaka date).
2. Locked characters (`character.locked == True`):
   - Allowed if user has an unexpired `Entitlement(type="character", value=character.id)` (or active plan entitlement, check `_check_caps`).
   - Otherwise, user gets a 120-second (2-minute) free trial per locked character tracked in `character_trials`.
   - Once `seconds_used >= 120.0`, `POST /api/conversation/start` and turns raise HTTP 403.
3. Usage route `GET /api/usage/{user_id}/daily` enforces `verify_user_access` and returns remaining minutes `max(0.0, daily_limit - minutes_spoken)`.
