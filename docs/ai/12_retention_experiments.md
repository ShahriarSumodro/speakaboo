# Spec 12: Retention & Experiments (`backend/engine/experiments.py`)

## Purpose
Deterministic A/B experiment bucketing and granular pedagogical/retention event logging.

## Rules & Invariants
1. 6 configured experiments (`EXP001`..`EXP006`) in `EXPERIMENTS_REGISTRY`.
2. `get_variant(user_id, experiment_id)`:
   - Inactive or unknown experiment -> returns `default_variant` (or `"control"`).
   - Checks persisted assignment in `experiment_assignments` first.
   - Otherwise computes `int(sha256(f"{user_id}:{experiment_id}").hexdigest(), 16) % len(variants)` and persists it permanently.
3. `log_event(...)`: auto-resolves `variant` when `experiment_id` is given and `variant` is empty, then writes to `analytics_events`.
