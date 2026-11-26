# Spec 07: Streaks, XP, Levels & Missions (`backend/engine/gamification.py`, `missions.py`, `level.py`, `sqlite_repo.py`)

## Purpose
Drives daily retention via XP, progressive leveling, Asia/Dhaka-safe streaks with freeze/repair, and daily missions.

## Rules & Invariants
1. Level calculation (`calculate_level(xp)`): `xp <= 0` -> Level 1; each level `lvl` requires `int(100 * (lvl ** 1.2))` XP cumulatively.
2. XP rewards: `XP_PER_TURN = 10` + `int(minutes_spoken * 20)`, `XP_SHADOWING_COMPLETED = 40` + `int((accuracy/100)*20)`, `XP_SCENARIO_COMPLETED = 60`.
3. Streaks (`record_activity` in Asia/Dhaka UTC+6):
   - First activity -> streak = 1.
   - Same day -> streak unchanged.
   - `diff == 1` -> `current_streak += 1`.
   - `diff == 2` and `streak_freeze_count > 0` -> consume 1 freeze, `current_streak += 1`.
   - `diff >= 2` without freeze -> save `previous_streak`, reset `current_streak = 1`, `streak_repaired = False`.
4. Daily missions (`DEFAULT_MISSIONS`): seeded per `(user_id, date)` on first fetch; `claim_mission_reward` is idempotent and awards `xp_reward` only once when `completed == True` and `reward_claimed == False`.
