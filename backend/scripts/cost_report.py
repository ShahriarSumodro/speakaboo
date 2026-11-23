"""
Cost Estimation and Unit Economics Report for Speakaboo.

Estimates the AI cost per user-minute of spoken English practice
and analyzes unit economics against subscription plans (200 BDT/month ≈ $1.65 USD).

Usage:
    python -m backend.scripts.cost_report
"""

from typing import Dict, Any


def calculate_cost_per_minute(
    turns_per_minute: float = 4.0,
    stt_seconds_per_turn: float = 6.0,
    llm_tokens_in_per_turn: int = 240,
    llm_tokens_out_per_turn: int = 50,
    tts_chars_per_turn: int = 120,
) -> Dict[str, Any]:
    """
    Calculate unit economics per spoken user-minute.

    Industry Benchmark Pricing (Groq Free / Tier 1 Paid Rates):
    - STT (Groq Whisper Large v3 Turbo): $0.0001 per audio second ($0.006 per audio min)
    - LLM (Groq LLaMA 3.3 70B / Scout 17B):
        - Input: $0.05 per 1,000,000 tokens ($0.00000005 per token)
        - Output: $0.08 per 1,000,000 tokens ($0.00000008 per token)
    - TTS (PlayAI / Generic voice): $0.000010 per character ($10 per 1M characters)
    """

    # Rates (Groq Whisper, LLaMA Scout, cached PlayAI/generic TTS)
    RATE_STT_PER_SEC = 0.0001
    RATE_LLM_IN_PER_TOKEN = 0.00000005
    RATE_LLM_OUT_PER_TOKEN = 0.00000008
    RATE_TTS_PER_CHAR = 0.000003  # Groq/generic TTS with Speakaboo TTS caching
    USD_TO_BDT = 121.50

    # Cost per turn
    stt_cost_turn = stt_seconds_per_turn * RATE_STT_PER_SEC
    llm_cost_turn = (llm_tokens_in_per_turn * RATE_LLM_IN_PER_TOKEN) + (llm_tokens_out_per_turn * RATE_LLM_OUT_PER_TOKEN)
    tts_cost_turn = tts_chars_per_turn * RATE_TTS_PER_CHAR
    total_cost_per_turn = stt_cost_turn + llm_cost_turn + tts_cost_turn

    # Cost per minute (4 turns of child speaking + character replying)
    stt_cost_min = stt_cost_turn * turns_per_minute
    llm_cost_min = llm_cost_turn * turns_per_minute
    tts_cost_min = tts_cost_turn * turns_per_minute
    total_cost_per_minute_usd = total_cost_per_turn * turns_per_minute
    total_cost_per_minute_bdt = total_cost_per_minute_usd * USD_TO_BDT

    # Monthly Scenarios
    # Scenario A: Free Plan User (Average 4 minutes/day, 15 active days = 60 minutes/month)
    free_mins_month = 60
    free_cost_usd = free_mins_month * total_cost_per_minute_usd
    free_cost_bdt = free_cost_usd * USD_TO_BDT

    # Scenario B: Pro Subscriber (Average 10 minutes/day, 15 active days = 150 minutes/month)
    pro_mins_month = 150
    pro_cost_usd = pro_mins_month * total_cost_per_minute_usd
    pro_cost_bdt = pro_cost_usd * USD_TO_BDT
    subscription_revenue_bdt = 200.0
    subscription_revenue_usd = subscription_revenue_bdt / USD_TO_BDT
    pro_gross_profit_bdt = subscription_revenue_bdt - pro_cost_bdt
    pro_margin_pct = (pro_gross_profit_bdt / subscription_revenue_bdt) * 100

    report = {
        "cost_per_turn": {
            "stt_usd": round(stt_cost_turn, 6),
            "llm_usd": round(llm_cost_turn, 6),
            "tts_usd": round(tts_cost_turn, 6),
            "total_usd": round(total_cost_per_turn, 5),
        },
        "cost_per_user_minute": {
            "usd": round(total_cost_per_minute_usd, 5),
            "bdt": round(total_cost_per_minute_bdt, 4),
        },
        "free_plan_monthly_active": {
            "active_minutes": free_mins_month,
            "cost_usd": round(free_cost_usd, 3),
            "cost_bdt": round(free_cost_bdt, 2),
        },
        "pro_subscription_monthly": {
            "active_minutes": pro_mins_month,
            "cost_usd": round(pro_cost_usd, 3),
            "cost_bdt": round(pro_cost_bdt, 2),
            "revenue_bdt": subscription_revenue_bdt,
            "gross_profit_bdt": round(pro_gross_profit_bdt, 2),
            "margin_percentage": round(pro_margin_pct, 1),
        },
    }

    return report


def print_report():
    rep = calculate_cost_per_minute()
    print("=====================================================")
    print("         SPEAKABOO AI UNIT ECONOMICS REPORT          ")
    print("=====================================================")
    print(f"Cost Per Spoken Turn:    ${rep['cost_per_turn']['total_usd']:.5f} USD")
    print(f"  - STT (Whisper):       ${rep['cost_per_turn']['stt_usd']:.6f}")
    print(f"  - LLM (Llama Scout):   ${rep['cost_per_turn']['llm_usd']:.6f}")
    print(f"  - TTS (Speech Synt):   ${rep['cost_per_turn']['tts_usd']:.6f}")
    print("-----------------------------------------------------")
    print(f"Cost Per User-Minute:    ${rep['cost_per_user_minute']['usd']:.5f} USD ({rep['cost_per_user_minute']['bdt']:.3f} BDT)")
    print("-----------------------------------------------------")
    print("Free Active User (120 min/mo):")
    print(f"  - Cost to Serve:       ${rep['free_plan_monthly_active']['cost_usd']:.2f} USD ({rep['free_plan_monthly_active']['cost_bdt']:.1f} BDT)")
    print("-----------------------------------------------------")
    print("Pro Subscriber (500 min/mo):")
    print(f"  - Subscription Price:  200 BDT (${rep['pro_subscription_monthly']['revenue_bdt']/121.5:.2f} USD)")
    print(f"  - Delivery Cost:       {rep['pro_subscription_monthly']['cost_bdt']:.1f} BDT (${rep['pro_subscription_monthly']['cost_usd']:.2f} USD)")
    print(f"  - Gross Profit:        +{rep['pro_subscription_monthly']['gross_profit_bdt']:.1f} BDT")
    print(f"  - Gross Margin:        {rep['pro_subscription_monthly']['margin_percentage']:.1f}%")
    print("=====================================================")


if __name__ == "__main__":
    print_report()
