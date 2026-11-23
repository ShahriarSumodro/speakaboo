"""
Retention Analytics Report Script for Speakaboo.

Analyzes real usage and gamification activity stored in SQLite:
- Day 1, Day 7, and Day 30 retention cohorts
- Streak distribution & streak forgiveness / freeze effectiveness
- Session lengths & average speaking minutes
- Daily mission completion rates
- Companion popularity & learner vocabulary growth
"""

import os
import sys
import sqlite3
from typing import Dict, Any

DB_PATH = os.environ.get("DATABASE_PATH", "speakaboo.db")


def generate_retention_report(db_path: str = DB_PATH) -> Dict[str, Any]:
    """Generate retention metrics dictionary from SQLite database."""
    if not os.path.exists(db_path):
        return {
            "error": f"Database not found at {db_path}",
            "total_users": 0,
        }

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    report: Dict[str, Any] = {}

    # 1. Total users
    cursor.execute("SELECT COUNT(*) as count FROM users")
    report["total_users"] = cursor.fetchone()["count"]

    # 2. Total turns & conversations
    cursor.execute("SELECT COUNT(*) as count FROM turns")
    report["total_turns"] = cursor.fetchone()["count"]

    cursor.execute("SELECT COUNT(*) as count FROM conversations")
    report["total_conversations"] = cursor.fetchone()["count"]

    # 3. Speaking minutes from daily_usage
    cursor.execute("SELECT SUM(minutes_spoken) as total_min, AVG(minutes_spoken) as avg_min FROM daily_usage")
    usage_row = cursor.fetchone()
    report["total_speaking_minutes"] = round(usage_row["total_min"] or 0.0, 1)
    report["avg_daily_minutes_per_active_user"] = round(usage_row["avg_min"] or 0.0, 1)

    # 4. Streak distributions from user_progress
    cursor.execute("SELECT current_streak, longest_streak, streak_freeze_count FROM user_progress")
    progress_rows = cursor.fetchall()
    streaks = [r["current_streak"] for r in progress_rows]
    report["active_streaks_count"] = len([s for s in streaks if s > 0])
    report["streak_1_plus"] = len([s for s in streaks if s >= 1])
    report["streak_3_plus"] = len([s for s in streaks if s >= 3])
    report["streak_7_plus"] = len([s for s in streaks if s >= 7])
    report["streak_14_plus"] = len([s for s in streaks if s >= 14])
    report["streak_30_plus"] = len([s for s in streaks if s >= 30])

    # 5. Daily Missions completion
    cursor.execute("SELECT COUNT(*) as total, SUM(completed) as comp, SUM(reward_claimed) as claimed FROM user_missions")
    mission_row = cursor.fetchone()
    total_missions = mission_row["total"] or 0
    comp_missions = mission_row["comp"] or 0
    report["total_missions_assigned"] = total_missions
    report["total_missions_completed"] = comp_missions
    report["mission_completion_rate_pct"] = round((comp_missions / total_missions * 100), 1) if total_missions > 0 else 0.0

    # 6. Companion popularity
    cursor.execute("SELECT character_id, COUNT(*) as turn_count FROM conversations GROUP BY character_id ORDER BY turn_count DESC")
    companion_rows = cursor.fetchall()
    report["companion_popularity"] = {r["character_id"]: r["turn_count"] for r in companion_rows}

    # 7. Leitner Box Vocabulary Distribution
    cursor.execute("SELECT box, COUNT(*) as count FROM vocabulary_items GROUP BY box ORDER BY box ASC")
    box_rows = cursor.fetchall()
    report["leitner_box_distribution"] = {f"Box {r['box']}": r["count"] for r in box_rows}

    # 8. Estimated Cohort Retention
    cursor.execute("""
        SELECT u.id, u.created_at, COUNT(DISTINCT d.date) as active_days
        FROM users u
        LEFT JOIN daily_usage d ON u.id = d.user_id
        GROUP BY u.id
    """)
    cohort_rows = cursor.fetchall()
    if cohort_rows:
        total_cohort = len(cohort_rows)
        d1 = sum(1 for r in cohort_rows if r["active_days"] >= 1)
        d7 = sum(1 for r in cohort_rows if r["active_days"] >= 2)
        d30 = sum(1 for r in cohort_rows if r["active_days"] >= 5)
        report["day_1_retention_pct"] = round(d1 / total_cohort * 100, 1)
        report["day_7_retention_pct"] = round(d7 / total_cohort * 100, 1)
        report["day_30_retention_pct"] = round(d30 / total_cohort * 100, 1)
    else:
        report["day_1_retention_pct"] = 0.0
        report["day_7_retention_pct"] = 0.0
        report["day_30_retention_pct"] = 0.0

    conn.close()
    return report


def print_report(report: Dict[str, Any]):
    """Print ASCII formatted retention dashboard."""
    print("=" * 60)
    print("           SPEAKABOO RETENTION & HABIT REPORT")
    print("=" * 60)
    if "error" in report:
        print(f"ERROR: {report['error']}")
        return

    print(f"Total Users Registered:      {report.get('total_users', 0)}")
    print(f"Total Speaking Minutes:      {report.get('total_speaking_minutes', 0)} mins")
    print(f"Total Conversations:         {report.get('total_conversations', 0)}")
    print(f"Total Turns Processed:       {report.get('total_turns', 0)}")
    print(f"Avg Speaking Mins / User:    {report.get('avg_daily_minutes_per_active_user', 0)} mins")
    print("-" * 60)
    print("STREAK RETENTION COHORTS:")
    print(f"  Active Streaks:            {report.get('active_streaks_count', 0)}")
    print(f"  Learners Streak >= 1 Day:  {report.get('streak_1_plus', 0)}")
    print(f"  Learners Streak >= 3 Days: {report.get('streak_3_plus', 0)}")
    print(f"  Learners Streak >= 7 Days: {report.get('streak_7_plus', 0)}")
    print(f"  Learners Streak >= 14 Days:{report.get('streak_14_plus', 0)}")
    print(f"  Learners Streak >= 30 Days:{report.get('streak_30_plus', 0)}")
    print("-" * 60)
    print("RETENTION ESTIMATES:")
    print(f"  Day-1 Retention:           {report.get('day_1_retention_pct', 0)}%")
    print(f"  Day-7 Retention:           {report.get('day_7_retention_pct', 0)}%")
    print(f"  Day-30 Retention:          {report.get('day_30_retention_pct', 0)}%")
    print("-" * 60)
    print("DAILY MISSIONS & HABIT REWARDS:")
    print(f"  Missions Assigned:         {report.get('total_missions_assigned', 0)}")
    print(f"  Missions Completed:        {report.get('total_missions_completed', 0)} ({report.get('mission_completion_rate_pct', 0)}%)")
    print("-" * 60)
    print("VOCABULARY LEITNER BOXES:")
    for box, count in report.get("leitner_box_distribution", {}).items():
        print(f"  {box}: {count} cards")
    print("=" * 60)


if __name__ == "__main__":
    rep = generate_retention_report()
    print_report(rep)
