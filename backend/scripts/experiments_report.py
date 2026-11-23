"""
Speakaboo A/B Testing & Experiments Analytics Report Script.

Analyzes pedagogical and business experiments from SQLite:
- Results per variant for active experiments (EXP001 - EXP006)
- Sample sizes (N participants and N events)
- Plain-language warnings when sample sizes are too small to trust (< 30)
- Conversion, self-repair rates, fluency WPM, and retention comparisons
"""

import os
import sys
import sqlite3
import json
from typing import Dict, Any, List

DB_PATH = os.environ.get("DATABASE_PATH", "speakaboo.db")
MIN_RELIABLE_SAMPLE_SIZE = 30  # Standard threshold for central limit theorem validity


def generate_experiments_report(db_path: str = DB_PATH) -> Dict[str, Any]:
    """Generate comprehensive A/B experiment evaluation report from SQLite."""
    if not os.path.exists(db_path):
        return {
            "error": f"Database not found at {db_path}",
            "experiments": {},
        }

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    report: Dict[str, Any] = {"experiments": {}}

    # 1. Query unique assignments per experiment and variant
    cursor.execute("""
        SELECT experiment_id, variant, COUNT(DISTINCT user_id) as participant_count
        FROM experiment_assignments
        GROUP BY experiment_id, variant
    """)
    assignment_rows = cursor.fetchall()
    assignments: Dict[str, Dict[str, int]] = {}
    for r in assignment_rows:
        exp_id = r["experiment_id"]
        variant = r["variant"]
        if exp_id not in assignments:
            assignments[exp_id] = {}
        assignments[exp_id][variant] = r["participant_count"]

    # 2. Query event metrics per experiment and variant
    cursor.execute("""
        SELECT experiment_id,
               variant,
               event_name,
               COUNT(*) as event_count,
               AVG(metric_value) as avg_metric,
               SUM(metric_value) as sum_metric,
               MIN(metric_value) as min_metric,
               MAX(metric_value) as max_metric
        FROM analytics_events
        WHERE experiment_id != ''
        GROUP BY experiment_id, variant, event_name
    """)
    event_rows = cursor.fetchall()

    for r in event_rows:
        exp_id = r["experiment_id"]
        variant = r["variant"]
        event_name = r["event_name"]

        if exp_id not in report["experiments"]:
            report["experiments"][exp_id] = {
                "experiment_id": exp_id,
                "variants": {},
            }

        exp_data = report["experiments"][exp_id]
        if variant not in exp_data["variants"]:
            sample_size = assignments.get(exp_id, {}).get(variant, 0)
            exp_data["variants"][variant] = {
                "variant": variant,
                "sample_size": sample_size,
                "is_sample_reliable": sample_size >= MIN_RELIABLE_SAMPLE_SIZE,
                "sample_warning": (
                    f"Sample size too small (N={sample_size} < {MIN_RELIABLE_SAMPLE_SIZE}). "
                    "Findings are directional hypotheses only and cannot be statistically trusted yet."
                    if sample_size < MIN_RELIABLE_SAMPLE_SIZE
                    else "Statistically adequate sample size."
                ),
                "metrics": {},
            }

        var_data = exp_data["variants"][variant]
        var_data["metrics"][event_name] = {
            "events_count": r["event_count"],
            "avg_value": round(r["avg_metric"] or 0.0, 3),
            "sum_value": round(r["sum_metric"] or 0.0, 3),
            "min_value": round(r["min_metric"] or 0.0, 3),
            "max_value": round(r["max_metric"] or 0.0, 3),
        }

    conn.close()
    return report


def print_report(report: Dict[str, Any]):
    """Print human-readable ASCII experiments summary."""
    print("=" * 70)
    print("         SPEAKABOO PEDAGOGICAL & BUSINESS EXPERIMENTS REPORT")
    print("=" * 70)

    if "error" in report:
        print(f"[ERROR] {report['error']}")
        return

    exps = report.get("experiments", {})
    if not exps:
        print("No active experiment data recorded yet.")
        print("=" * 70)
        return

    for exp_id, exp_info in sorted(exps.items()):
        print(f"\n▶ EXPERIMENT: {exp_id}")
        print("-" * 70)
        for var_name, var_info in exp_info.get("variants", {}).items():
            status_indicator = "✓ RELIABLE" if var_info["is_sample_reliable"] else "⚠ UNDERPOWERED"
            print(f"  • Variant '{var_name}' [{status_indicator}] (N = {var_info['sample_size']} learners):")
            if not var_info["is_sample_reliable"]:
                print(f"    [WARNING] {var_info['sample_warning']}")
            for metric_name, m_data in var_info.get("metrics", {}).items():
                print(f"    - {metric_name}: avg={m_data['avg_value']}, count={m_data['events_count']}")

    print("\n" + "=" * 70)


if __name__ == "__main__":
    rep = generate_experiments_report()
    print_report(rep)
