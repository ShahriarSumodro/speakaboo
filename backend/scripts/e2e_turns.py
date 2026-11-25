"""
End-to-end multi-turn reproduction script using real Groq credentials.

Tests:
1. Direct TTS verification across all 6 Orpheus voices.
2. 8 consecutive conversation turns through ConversationEngine with real STT, LLM, and TTS.
"""

import os
import io
import sys
import wave
import struct
import math
import time
import asyncio
import logging
from pathlib import Path

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import httpx
from dotenv import load_dotenv

# Load repo root .env
load_dotenv(Path(__file__).parent.parent.parent / ".env")

from backend.config import load_settings
from backend.providers.groq_stt import GroqSttProvider
from backend.providers.groq_llm import GroqLlmProvider
from backend.providers.groq_tts import GroqTtsProvider
from backend.engine.characters import load_character
from backend.engine.conversation import ConversationEngine, get_last_turns

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("speakaboo.e2e_turns")


def create_pcm_wav(duration_s: float = 1.5, freq: float = 440.0, sample_rate: int = 16000) -> bytes:
    """Generate valid PCM 16-bit mono 16kHz WAV bytes."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        n_samples = int(duration_s * sample_rate)
        for i in range(n_samples):
            val = int(32767.0 * 0.2 * math.sin(2.0 * math.pi * freq * i / sample_rate))
            wf.writeframes(struct.pack("<h", val))
    return buf.getvalue()


def create_silent_wav(duration_s: float = 1.0, sample_rate: int = 16000) -> bytes:
    """Generate silent PCM WAV bytes."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        n_samples = int(duration_s * sample_rate)
        wf.writeframes(b"\x00\x00" * n_samples)
    return buf.getvalue()


async def check_direct_groq_tts(api_key: str):
    """Directly test Groq /audio/speech for all 6 Orpheus voices."""
    print("\n" + "=" * 60)
    print("STAGE 1: Direct Groq TTS Voice Probing (/audio/speech)")
    print("=" * 60)

    voices = ["autumn", "diana", "hannah", "austin", "daniel", "troy"]
    results = {}

    for voice in voices:
        print(f"\n[TTS Probe] Testing voice '{voice}'...")
        payload = {
            "model": "canopylabs/orpheus-v1-english",
            "input": f"Hello, I am testing voice {voice} for Speakaboo.",
            "voice": voice,
            "response_format": "wav",
        }
        try:
            async with httpx.AsyncClient(timeout=20.0) as client:
                res = await client.post(
                    "https://api.groq.com/openai/v1/audio/speech",
                    headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                    json=payload,
                )
            status = res.status_code
            print(f"  Status: {status}")
            if status == 200:
                audio_len = len(res.content)
                est_duration = max(0.1, audio_len / 32000.0)
                print(f"  SUCCESS: {audio_len} bytes, estimated duration: {est_duration:.2f}s")
                results[voice] = {"status": 200, "bytes": audio_len, "duration": est_duration}
            else:
                body = res.text[:300]
                print(f"  FAILURE: {body}")
                results[voice] = {"status": status, "error": body}
        except Exception as e:
            print(f"  EXCEPTION: {e}")
            results[voice] = {"status": "error", "error": str(e)}

    return results


async def run_8_consecutive_turns(api_key: str):
    """Run 8 consecutive turns through ConversationEngine with real Groq providers."""
    print("\n" + "=" * 60)
    print("STAGE 2: Running 8 Consecutive Turns Through ConversationEngine")
    print("=" * 60)

    settings = load_settings()

    stt = GroqSttProvider(api_key=api_key, model=settings.stt.model)
    llm = GroqLlmProvider(api_key=api_key, model=settings.llm.model)
    tts = GroqTtsProvider(api_key=api_key, model=settings.tts.model, default_voice="austin")

    engine = ConversationEngine(stt=stt, llm=llm, tts=tts)
    character = load_character("rule_farmer")

    state = engine.start_conversation(
        conversation_id="e2e-turns-session-1",
        character_id="rule_farmer",
        user_id="user_e2e_tester",
    )
    print(f"Initialized conversation cid={state.id} with character '{character.name}'")

    audio_samples = [
        ("tone_1.5s", create_pcm_wav(1.5, 440.0)),
        ("silent_1.0s", create_silent_wav(1.0)),
        ("short_tone_0.5s", create_pcm_wav(0.5, 880.0)),
        ("tone_2.0s", create_pcm_wav(2.0, 523.25)),
        ("tone_1.0s", create_pcm_wav(1.0, 329.63)),
        ("silent_0.8s", create_silent_wav(0.8)),
        ("tone_1.2s", create_pcm_wav(1.2, 659.25)),
        ("tone_1.8s", create_pcm_wav(1.8, 440.0)),
    ]

    turn_results = []

    for turn_idx, (label, audio_bytes) in enumerate(audio_samples, start=1):
        print(f"\n--- Running Turn {turn_idx}/8 (Input: {label}, {len(audio_bytes)} bytes) ---")
        t0 = time.time()
        try:
            result = await asyncio.wait_for(
                engine.process_turn(
                    conversation_id=state.id,
                    audio=audio_bytes,
                    character=character,
                    audio_format="wav",
                ),
                timeout=30.0,
            )
            elapsed = (time.time() - t0) * 1000
            print(f"  Turn {turn_idx} Completed in {elapsed:.0f}ms")
            print(f"  User Transcript: '{result.user_transcript}'")
            print(f"  AI Reply: '{result.response.reply}'")
            print(f"  Audio Chunks: {len(result.audio_chunks)}")
            if result.tts_error:
                print(f"  TTS Stage Note: {result.tts_error}")
            turn_results.append({
                "turn": turn_idx,
                "label": label,
                "elapsed_ms": elapsed,
                "transcript": result.user_transcript,
                "reply": result.response.reply,
                "audio_chunks": len(result.audio_chunks),
                "tts_error": result.tts_error,
                "status": "ok",
            })
        except asyncio.TimeoutError:
            print(f"  Turn {turn_idx} TIMED OUT after 30s")
            turn_results.append({"turn": turn_idx, "status": "timeout"})
        except Exception as e:
            print(f"  Turn {turn_idx} EXCEPTION: {e}")
            turn_results.append({"turn": turn_idx, "status": "error", "error": str(e)})

    return turn_results


async def main():
    api_key = os.getenv("GROQ_API_KEY", "")
    if not api_key:
        print("ERROR: GROQ_API_KEY not found in environment or .env file.")
        return

    print(f"Groq API Key detected (prefix: {api_key[:8]}..., length: {len(api_key)})")

    # 1. Probing direct TTS
    tts_results = await check_direct_groq_tts(api_key)

    # 2. Running 8 consecutive turns
    turn_results = await run_8_consecutive_turns(api_key)

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print("TTS Results:")
    for v, r in tts_results.items():
        print(f"  {v}: status {r.get('status')}")

    print("\nTurn Results:")
    for r in turn_results:
        print(f"  Turn {r.get('turn')}: status={r.get('status')}, audio_chunks={r.get('audio_chunks')}, reply='{r.get('reply', '')[:50]}'")


if __name__ == "__main__":
    asyncio.run(main())
