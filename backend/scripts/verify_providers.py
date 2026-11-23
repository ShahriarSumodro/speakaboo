"""
Speakaboo Provider Verification Script

Makes real calls to STT (Whisper), LLM (GPT-OSS/LLaMA), and TTS (Orpheus)
to verify active Groq API keys, model availability, and latency.

Usage:
    python -m backend.scripts.verify_providers
"""

import sys
import os
import time
import json
import wave
import io
import struct
import math
import asyncio
import httpx

# Ensure backend can be imported
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from backend.config import load_settings
from backend.providers.groq_stt import GroqSttProvider
from backend.providers.groq_llm import GroqLlmProvider
from backend.providers.groq_tts import GroqTtsProvider
from backend.providers.base import Message


def generate_test_wav(duration_s: float = 1.0, sample_rate: int = 16000) -> bytes:
    """Generate a clean synthetic 16kHz mono 440Hz sine wave WAV file in memory."""
    num_samples = int(sample_rate * duration_s)
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav:
        wav.setnchannels(1)        # Mono
        wav.setsampwidth(2)       # 16-bit
        wav.setframerate(sample_rate)
        # 440Hz tone with gentle fade in/out
        for i in range(num_samples):
            t = i / sample_rate
            amplitude = 8000 * math.sin(2 * math.pi * 440 * t)
            wav.writeframesraw(struct.pack("<h", int(amplitude)))
    return buffer.getvalue()


async def check_groq_models(api_key: str) -> list[str]:
    """Query Groq API models endpoint to list active models."""
    url = "https://api.groq.com/openai/v1/models"
    async with httpx.AsyncClient(timeout=10.0) as client:
        res = await client.get(url, headers={"Authorization": f"Bearer {api_key}"})
        if res.status_code != 200:
            raise RuntimeError(f"Groq API error listing models: {res.status_code} {res.text[:200]}")
        data = res.json()
        return [m["id"] for m in data.get("data", [])]


async def run_verification():
    settings = load_settings()
    api_key = settings.stt.api_key or os.environ.get("GROQ_API_KEY", "")

    print("\n" + "=" * 60)
    print("  SPEAKABOO PROVIDER VERIFICATION (REAL AI PASS)")
    print("=" * 60)

    if not api_key or api_key.startswith("your_"):
        print("\n[FAIL] No valid GROQ_API_KEY detected in environment or backend/.env.")
        print("To run real provider verification:")
        print("  1. Add GROQ_API_KEY=gsk_... to your backend/.env")
        print("  2. Re-run: python -m backend.scripts.verify_providers\n")
        sys.exit(1)

    print(f"Key detected: {api_key[:6]}...{api_key[-4:]}")
    results = {}

    # 1. Models Check
    print("\n[1/4] Checking Groq API models list...")
    try:
        t0 = time.time()
        available_models = await check_groq_models(api_key)
        dur = (time.time() - t0) * 1000
        print(f"      Available models ({len(available_models)}):")
        for m in sorted(available_models)[:6]:
            print(f"        - {m}")
        if len(available_models) > 6:
            print(f"        ... and {len(available_models) - 6} more")
        results["models_list"] = ("PASS", f"{dur:.0f}ms", f"{len(available_models)} models found")
    except Exception as e:
        results["models_list"] = ("FAIL", "---", str(e))
        print(f"      [ERROR] {e}")

    # 2. STT Verification
    print(f"\n[2/4] Verifying STT: {settings.stt.model}...")
    try:
        stt = GroqSttProvider(api_key=api_key, model=settings.stt.model)
        test_wav = generate_test_wav(1.0)
        t0 = time.time()
        res = await stt.transcribe(test_wav)
        dur = (time.time() - t0) * 1000
        print(f"      STT Transcribe Success! Latency: {dur:.0f}ms")
        print(f"      Transcript: '{res.text}' (lang={res.language})")
        results["STT"] = ("PASS", f"{dur:.0f}ms", f"{settings.stt.model}")
    except Exception as e:
        results["STT"] = ("FAIL", "---", str(e))
        print(f"      [ERROR] STT failed: {e}")

    # 3. LLM Verification
    print(f"\n[3/4] Verifying LLM: {settings.llm.model} (Fallbacks: {settings.llm.fallback_models})...")
    try:
        llm = GroqLlmProvider(
            api_key=api_key,
            model=settings.llm.model,
            fallback_models=list(settings.llm.fallback_models),
        )
        messages = [
            Message(role="system", content="You are a conversational speaking coach. Output JSON."),
            Message(role="user", content='Say hello in valid JSON format: {"reply": "Hello"}'),
        ]
        t0 = time.time()
        res = await llm.chat(messages, max_tokens=100, json_mode=True)
        dur = (time.time() - t0) * 1000
        parsed = json.loads(res.content)
        print(f"      LLM Chat Success! Latency: {dur:.0f}ms (model={res.model})")
        print(f"      Output: {parsed}")
        print(f"      Tokens: in={res.tokens_in}, out={res.tokens_out}")
        results["LLM"] = ("PASS", f"{dur:.0f}ms", f"{res.model}")
    except Exception as e:
        results["LLM"] = ("FAIL", "---", str(e))
        print(f"      [ERROR] LLM failed: {e}")

    # 4. TTS Verification
    print(f"\n[4/4] Verifying TTS: {settings.tts.model} (voice={settings.tts.voice})...")
    try:
        tts = GroqTtsProvider(
            api_key=api_key,
            model=settings.tts.model,
            default_voice=settings.tts.voice,
        )
        sample_text = "Welcome to Speakaboo! Let us plant the seeds of great English."
        t0 = time.time()
        res = await tts.synthesize(sample_text, voice_id=settings.tts.voice)
        dur = (time.time() - t0) * 1000
        print(f"      TTS Synthesize Success! Latency: {dur:.0f}ms")
        print(f"      Synthesized audio: {len(res.audio)} bytes (est. {res.duration_seconds:.2f}s)")
        results["TTS"] = ("PASS", f"{dur:.0f}ms", f"{settings.tts.model}:{settings.tts.voice} ({len(res.audio)} bytes)")
    except Exception as e:
        results["TTS"] = ("FAIL", "---", str(e))
        print(f"      [ERROR] TTS failed: {e}")

    # Summary Table
    print("\n" + "=" * 60)
    print("  PROVIDER VERIFICATION SUMMARY")
    print("=" * 60)
    all_passed = True
    for component, (status, latency, detail) in results.items():
        if status != "PASS":
            all_passed = False
        print(f"  {component:<12} | {status:<6} | {latency:<8} | {detail}")
    print("=" * 60)

    if all_passed:
        print("\n>>> ALL REAL PROVIDERS OPERATIONAL AND RESPONDING! <<<\n")
        sys.exit(0)
    else:
        print("\n>>> ONE OR MORE REAL PROVIDERS FAILED <<<")
        print("Check error messages above.\n")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(run_verification())
