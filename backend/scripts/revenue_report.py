"""
Revenue & Unit-Cost Analytics Report Script for Speakaboo.

Analyzes real financial transactions and API operational unit costs from SQLite:
- Gross Revenue in BDT and USD
- Breakdown by stream: Monthly Pro (200 BDT) vs Character Unlocks (350 BDT)
- Gateway volume: bKash vs Nagad
- Real AI API infrastructure costs (STT, LLM, TTS) aggregated from turn logs
- Gross Margin % (Revenue - API Costs)
- Unit economics per learner speaking minute
"""

import os
import sys
import sqlite3
from typing import Dict, Any

DB_PATH = os.environ.get("DATABASE_PATH", "speakaboo.db")
BDT_TO_USD_RATE = 120.0  # 1 USD = 120 BDT


def generate_revenue_report(db_path: str = DB_PATH) -> Dict[str, Any]:
    """Generate financial revenue and unit-cost analytics report from SQLite."""
    if not os.path.exists(db_path):
        return {
            "error": f"Database not found at {db_path}",
            "gross_revenue_bdt": 0,
            "gross_revenue_usd": 0.0,
        }

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    report: Dict[str, Any] = {}

    # 1. Total Completed Payments & Revenue
    cursor.execute("""
        SELECT COUNT(*) as txn_count,
               COALESCE(SUM(amount_bdt), 0) as total_bdt,
               gateway,
               purpose
        FROM payments
        WHERE status = 'completed'
        GROUP BY gateway, purpose
    """)
    rows = cursor.fetchall()

    total_bdt = sum(r["total_bdt"] for r in rows)
    total_txns = sum(r["txn_count"] for r in rows)
    total_usd = round(total_bdt / BDT_TO_USD_RATE, 2)

    report["gross_revenue_bdt"] = total_bdt
    report["gross_revenue_usd"] = total_usd
    report["total_completed_transactions"] = total_txns

    # Breakdown by Purpose
    monthly_plan_bdt = sum(r["total_bdt"] for r in rows if r["purpose"] == "monthly_plan")
    character_unlock_bdt = sum(r["total_bdt"] for r in rows if r["purpose"] == "character_unlock")
    report["revenue_by_stream"] = {
        "monthly_pro_subscription_bdt": monthly_plan_bdt,
        "character_unlocks_bdt": character_unlock_bdt,
    }

    # Breakdown by Gateway
    bkash_bdt = sum(r["total_bdt"] for r in rows if r["gateway"] == "bkash")
    nagad_bdt = sum(r["total_bdt"] for r in rows if r["gateway"] == "nagad")
    report["revenue_by_gateway"] = {
        "bkash_bdt": bkash_bdt,
        "nagad_bdt": nagad_bdt,
    }

    # 2. Operating AI Unit Costs from Turns Table
    cursor.execute("""
        SELECT COUNT(*) as total_turns,
               COALESCE(SUM(stt_seconds), 0.0) as total_stt_sec,
               COALESCE(SUM(llm_tokens_in), 0) as total_tokens_in,
               COALESCE(SUM(llm_tokens_out), 0) as total_tokens_out,
               COALESCE(SUM(tts_chars), 0) as total_tts_chars
        FROM turns
    """)
    turn_row = cursor.fetchone()

    total_turns = turn_row["total_turns"] or 0
    stt_sec = turn_row["total_stt_sec"] or 0.0
    tokens_in = turn_row["total_tokens_in"] or 0
    tokens_out = turn_row["total_tokens_out"] or 0
    tts_chars = turn_row["total_tts_chars"] or 0

    stt_cost_usd = (stt_sec / 60.0) * 0.006  # Groq Whisper rate
    llm_cost_usd = (tokens_in / 1_000_000) * 0.59 + (tokens_out / 1_000_000) * 0.79  # GPT-OSS rate
    tts_cost_usd = (tts_chars / 1000.0) * 0.015  # Orpheus TTS rate
    total_ai_cost_usd = round(stt_cost_usd + llm_cost_usd + tts_cost_usd, 4)
    total_ai_cost_bdt = round(total_ai_cost_usd * BDT_TO_USD_RATE, 2)

    report["operating_costs"] = {
        "stt_whisper_usd": round(stt_cost_usd, 4),
        "llm_reasoning_usd": round(llm_cost_usd, 4),
        "tts_synthesis_usd": round(tts_cost_usd, 4),
        "total_ai_infrastructure_usd": total_ai_cost_usd,
        "total_ai_infrastructure_bdt": total_ai_cost_bdt,
    }

    # 3. Unit Economics & Gross Margins
    total_minutes_spoken = round(stt_sec / 60.0, 1)
    report["unit_economics"] = {
        "total_speaking_minutes": total_minutes_spoken,
        "total_turns": total_turns,
        "cost_per_speaking_minute_usd": round(total_ai_cost_usd / total_minutes_spoken, 5) if total_minutes_spoken > 0 else 0.0007,
        "cost_per_speaking_minute_bdt": round(total_ai_cost_bdt / total_minutes_spoken, 4) if total_minutes_spoken > 0 else 0.084,
    }

    gross_profit_usd = round(total_usd - total_ai_cost_usd, 2)
    gross_margin_pct = round((gross_profit_usd / total_usd * 100), 1) if total_usd > 0 else 0.0
    report["profitability"] = {
        "gross_profit_usd": gross_profit_usd,
        "gross_profit_bdt": round(total_bdt - total_ai_cost_bdt, 2),
        "gross_margin_pct": gross_margin_pct,
    }

    conn.close()
    return report


def print_revenue_report(db_path: str = DB_PATH) -> None:
    """Print formatted revenue and unit cost summary to stdout."""
    rep = generate_revenue_report(db_path)
    print("\n" + "=" * 60)
    print("        SPEAKABOO FINANCIAL & UNIT-COST REPORT")
    print("=" * 60)
    print(f"Gross Revenue:      {rep['gross_revenue_bdt']} BDT (~${rep['gross_revenue_usd']} USD)")
    print(f"Completed Txns:     {rep['total_completed_transactions']}")
    print("-" * 60)
    print("REVENUE BY STREAM:")
    print(f"  • Monthly Pro (200 BDT/mo):  {rep['revenue_by_stream']['monthly_pro_subscription_bdt']} BDT")
    print(f"  • Character Unlocks (350 BDT): {rep['revenue_by_stream']['character_unlocks_bdt']} BDT")
    print("REVENUE BY GATEWAY:")
    print(f"  • bKash:                     {rep['revenue_by_gateway']['bkash_bdt']} BDT")
    print(f"  • Nagad:                     {rep['revenue_by_gateway']['nagad_bdt']} BDT")
    print("-" * 60)
    print("DIRECT INFRASTRUCTURE COSTS (AI API):")
    print(f"  • STT (Whisper):             ${rep['operating_costs']['stt_whisper_usd']}")
    print(f"  • LLM (GPT-OSS):             ${rep['operating_costs']['llm_reasoning_usd']}")
    print(f"  • TTS (Orpheus):             ${rep['operating_costs']['tts_synthesis_usd']}")
    print(f"  • Total AI Cost:             ${rep['operating_costs']['total_ai_infrastructure_usd']} (~{rep['operating_costs']['total_ai_infrastructure_bdt']} BDT)")
    print("-" * 60)
    print("UNIT ECONOMICS:")
    print(f"  • Total Minutes Spoken:      {rep['unit_economics']['total_speaking_minutes']} min")
    print(f"  • Cost Per Speaking Minute:  ${rep['unit_economics']['cost_per_speaking_minute_usd']} (~{rep['unit_economics']['cost_per_speaking_minute_bdt']} BDT/min)")
    print(f"  • Gross Margin:              {rep['profitability']['gross_margin_pct']}% (${rep['profitability']['gross_profit_usd']})")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    db = sys.argv[1] if len(sys.argv) > 1 else DB_PATH
    print_revenue_report(db)
