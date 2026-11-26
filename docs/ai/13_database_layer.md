# Spec 13: Database Layer (`backend/repositories/sqlite_repo.py`)

## Purpose
SQLite implementation of `BaseRepository` managing 16 tables with WAL mode, Asia/Dhaka date helpers, and full user purge.

## Rules & Invariants
1. `initialize()` enables `PRAGMA journal_mode=WAL`, creates all 16 tables + 15 indexes, and runs safe `ALTER TABLE` migrations.
2. `dhaka_today()`, `dhaka_date_add()`, `dhaka_date_diff()` operate in UTC+6 (`Asia/Dhaka`).
3. `record_activity()` updates XP, level, and streak (consecutive, freeze, or reset with repair tracking).
4. `delete_user_data(user_id)` purges all user-scoped rows across all 16 tables.
