"""
Load test script for Speakaboo conversation pipeline.

Simulates concurrent user turns through the turn pipeline using mock providers
to measure throughput (turns/second), latency distributions (p50, p95, p99),
and verify zero error rates under concurrency.

Usage:
    python -m backend.scripts.load_test [--turns 100] [--concurrency 10]
"""

import asyncio
import time
import statistics
import argparse
from typing import List, Dict, Any

from backend.engine.conversation import ConversationEngine
from backend.providers.mock import MockSttProvider, MockLlmProvider, MockTtsProvider
from backend.engine.characters import load_character


async def run_single_turn(
    engine: ConversationEngine,
    user_id: str,
    character_id: str,
    turn_index: int,
) -> Dict[str, Any]:
    """Execute one full simulated turn and measure elapsed time."""
    start = time.perf_counter()
    conv_id = f"load-conv-{user_id}"

    # Generate dummy WAV audio chunk (16kHz 16-bit mono 0.1s)
    fake_audio = b"RIFF" + b"\x00" * 3200

    try:
        # Start if first turn
        char = load_character(character_id)
        engine.start_conversation(character_id=character_id, user_id=user_id, conversation_id=conv_id)
        res = await engine.process_turn(conversation_id=conv_id, audio=fake_audio, character=char)
        duration_ms = (time.perf_counter() - start) * 1000

        return {
            "turn_index": turn_index,
            "success": True,
            "duration_ms": duration_ms,
            "error": None,
        }
    except Exception as e:
        duration_ms = (time.perf_counter() - start) * 1000
        return {
            "turn_index": turn_index,
            "success": False,
            "duration_ms": duration_ms,
            "error": str(e),
        }


async def run_load_test(total_turns: int = 50, concurrency: int = 10) -> Dict[str, Any]:
    """Run concurrent load test across multiple simulated users."""
    print(f"=== Starting Speakaboo Load Test ===")
    print(f"Total Turns: {total_turns} | Concurrency: {concurrency}")

    engine = ConversationEngine(
        stt=MockSttProvider(),
        llm=MockLlmProvider(),
        tts=MockTtsProvider(),
    )

    sem = asyncio.Semaphore(concurrency)

    async def worker(idx: int) -> Dict[str, Any]:
        async with sem:
            user_id = f"load-user-{idx % concurrency}"
            return await run_single_turn(engine, user_id, "rule_farmer", idx)

    wall_start = time.perf_counter()
    tasks = [worker(i) for i in range(total_turns)]
    results = await asyncio.gather(*tasks)
    total_time = time.perf_counter() - wall_start

    successful = [r for r in results if r["success"]]
    failed = [r for r in results if not r["success"]]
    durations = [r["duration_ms"] for r in successful]

    p50 = statistics.median(durations) if durations else 0.0
    p95 = statistics.quantiles(durations, n=20)[18] if len(durations) >= 20 else max(durations or [0.0])
    p99 = statistics.quantiles(durations, n=100)[98] if len(durations) >= 100 else max(durations or [0.0])
    throughput = len(successful) / total_time if total_time > 0 else 0.0

    report = {
        "total_turns": total_turns,
        "concurrency": concurrency,
        "successful_turns": len(successful),
        "failed_turns": len(failed),
        "total_wall_time_s": round(total_time, 2),
        "throughput_turns_per_sec": round(throughput, 1),
        "latency_ms_avg": round(statistics.mean(durations), 2) if durations else 0.0,
        "latency_ms_p50": round(p50, 2),
        "latency_ms_p95": round(p95, 2),
        "latency_ms_p99": round(p99, 2),
    }

    print("\n--- Load Test Results ---")
    print(f"Success Rate: {len(successful)}/{total_turns} ({(len(successful)/total_turns)*100:.1f}%)")
    print(f"Wall Time: {report['total_wall_time_s']}s")
    print(f"Throughput: {report['throughput_turns_per_sec']} turns/second")
    print(f"Latency P50: {report['latency_ms_p50']} ms")
    print(f"Latency P95: {report['latency_ms_p95']} ms")
    print(f"Latency P99: {report['latency_ms_p99']} ms")
    print("=========================\n")

    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Speakaboo Load Test")
    parser.add_argument("--turns", type=int, default=50, help="Total turns to simulate")
    parser.add_argument("--concurrency", type=int, default=10, help="Concurrent workers")
    args = parser.parse_args()

    asyncio.run(run_load_test(total_turns=args.turns, concurrency=args.concurrency))
