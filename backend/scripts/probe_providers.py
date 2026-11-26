"""
Direct provider probe script (no app/engine abstractions).

Loads GROQ_API_KEY and configured models from .env / backend/.env and tests:
1. GET /openai/v1/models (key validity + available model IDs)
2. POST /openai/v1/audio/speech (TTS for all 6 Orpheus voices)
3. POST /openai/v1/audio/transcriptions (STT using TTS wav or synthesized speech wav)
4. POST /openai/v1/chat/completions (plain prompt + exact Speakaboo JSON prompt)
5. Rate-limit headers from responses
"""

import io
import math
import os
import struct
import sys
import time
import wave
from pathlib import Path

import httpx

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

from backend.config import load_settings  # noqa: E402
from backend.engine.characters import load_character, build_system_prompt  # noqa: E402

GROQ_BASE = "https://api.groq.com/openai/v1"
VOICES = ("autumn", "diana", "hannah", "austin", "daniel", "troy")


def _extract_ratelimit(headers: httpx.Headers) -> str:
    rl = {k: v for k, v in headers.items() if "ratelimit" in k.lower() or "retry-after" in k.lower()}
    if not rl:
        return "none"
    return ", ".join(f"{k}={v}" for k, v in sorted(rl.items()))


def _wav_duration_seconds(wav_bytes: bytes) -> float:
    try:
        with wave.open(io.BytesIO(wav_bytes), "rb") as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            return round(frames / float(rate), 2) if rate else 0.0
    except Exception:
        return round(len(wav_bytes) / 32000.0, 2)


def _fallback_tone_wav() -> bytes:
    """Short spoken-like multi-formant WAV only if TTS fails and no speech sample exists."""
    rate = 16000
    duration = 1.0
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        frames = bytearray()
        for i in range(int(rate * duration)):
            t = i / rate
            val = int(8000 * (math.sin(2 * math.pi * 220 * t) + 0.5 * math.sin(2 * math.pi * 440 * t)))
            frames += struct.pack("<h", max(-32768, min(32767, val)))
        wf.writeframes(bytes(frames))
    return buf.getvalue()


def main() -> int:
    settings = load_settings()
    key = settings.llm.api_key or os.environ.get("GROQ_API_KEY", "")
    if not key:
        print("FATAL: GROQ_API_KEY not found in .env or environment")
        return 1

    print(f"Key loaded: len={len(key)}, prefix={key[:6]}...")
    print(f"Configured models: STT={settings.stt.model}, LLM={settings.llm.model}, TTS={settings.tts.model}")
    print("=" * 80)

    headers = {"Authorization": f"Bearer {key}"}
    results = []
    available_models: list[str] = []

    with httpx.Client(timeout=30.0) as client:
        # 1. Key validity + model list
        t0 = time.time()
        try:
            r = client.get(f"{GROQ_BASE}/models", headers=headers)
            ms = round((time.time() - t0) * 1000, 1)
            if r.status_code == 200:
                available_models = sorted(m["id"] for m in r.json().get("data", []))
                results.append(("models_list", r.status_code, ms, f"{len(available_models)} models", _extract_ratelimit(r.headers)))
                print(f"[1] /models: {r.status_code} ({ms}ms) -> {len(available_models)} models")
                print("    Available models:", ", ".join(available_models))
            else:
                results.append(("models_list", r.status_code, ms, r.text[:250], _extract_ratelimit(r.headers)))
                print(f"[1] /models FAILED: {r.status_code} ({ms}ms) -> {r.text[:250]}")
        except Exception as e:
            results.append(("models_list", "EXC", 0, str(e), ""))
            print(f"[1] /models EXCEPTION: {e}")

        # 4 (run before 2 so we can feed real speech WAV to STT): TTS for all 6 voices
        speech_wav: bytes | None = None
        for voice in VOICES:
            t0 = time.time()
            try:
                r = client.post(
                    f"{GROQ_BASE}/audio/speech",
                    headers={**headers, "Content-Type": "application/json"},
                    json={
                        "model": settings.tts.model,
                        "input": "Hello! I am practicing English speaking today.",
                        "voice": voice,
                        "response_format": "wav",
                        "speed": 1.0,
                    },
                )
                ms = round((time.time() - t0) * 1000, 1)
                if r.status_code == 200:
                    dur = _wav_duration_seconds(r.content)
                    if speech_wav is None:
                        speech_wav = r.content
                    detail = f"{len(r.content)} bytes, {dur}s"
                else:
                    detail = r.text[:300]
                results.append((f"tts:{voice}", r.status_code, ms, detail, _extract_ratelimit(r.headers)))
                print(f"[4] TTS ({voice}): {r.status_code} ({ms}ms) -> {detail} | RL: {_extract_ratelimit(r.headers)}")
            except Exception as e:
                results.append((f"tts:{voice}", "EXC", 0, str(e), ""))
                print(f"[4] TTS ({voice}) EXCEPTION: {e}")

        # 2. STT with real speech WAV (from TTS or repo sample or fallback)
        if speech_wav is None:
            speech_wav = _fallback_tone_wav()
            stt_source = "synthetic_tone_fallback (TTS failed)"
        else:
            stt_source = "real_tts_speech_wav"

        t0 = time.time()
        try:
            r = client.post(
                f"{GROQ_BASE}/audio/transcriptions",
                headers=headers,
                files={"file": ("probe.wav", speech_wav, "audio/wav")},
                data={"model": settings.stt.model, "language": "en", "response_format": "verbose_json"},
            )
            ms = round((time.time() - t0) * 1000, 1)
            if r.status_code == 200:
                text = r.json().get("text", "").strip()
                detail = f"src={stt_source} | transcript='{text}'"
            else:
                detail = f"src={stt_source} | {r.text[:300]}"
            results.append((f"stt:{settings.stt.model}", r.status_code, ms, detail, _extract_ratelimit(r.headers)))
            print(f"[2] STT ({settings.stt.model}): {r.status_code} ({ms}ms) -> {detail} | RL: {_extract_ratelimit(r.headers)}")
        except Exception as e:
            results.append((f"stt:{settings.stt.model}", "EXC", 0, str(e), ""))
            print(f"[2] STT EXCEPTION: {e}")

        # 3. LLM: test configured model + available account models + fallback models in plain, json, and full Speakaboo prompt
        extra_models = [m for m in ("openai/gpt-oss-20b", "qwen/qwen3.8-27b") if not available_models or m in available_models or True]
        llm_candidates = list(dict.fromkeys([settings.llm.model, *extra_models, *settings.llm.fallback_models]))
        real_char = load_character("rule_farmer")
        real_sys_prompt = build_system_prompt(real_char, level="beginner", practice_mode="accuracy", coach_mode="balanced", age_band="teen")

        for model in llm_candidates:
            for mode_name in ("plain", "json", "speakaboo_prompt"):
                label = f"llm:{model}:{mode_name}"
                if mode_name == "plain":
                    msgs = [{"role": "system", "content": "Reply briefly."}, {"role": "user", "content": "Hello, I want to practice English."}]
                elif mode_name == "json":
                    msgs = [{"role": "system", "content": 'Respond with valid JSON only: {"version":1,"reply":"Hi!","correction":null,"new_words":[]}'}, {"role": "user", "content": "Hello, I want to practice English."}]
                else:
                    msgs = [{"role": "system", "content": real_sys_prompt}, {"role": "user", "content": "Yesterday I goed to school and play football."}]
                payload = {
                    "model": model,
                    "messages": msgs,
                    "max_tokens": settings.llm.max_tokens,
                    "temperature": settings.llm.temperature,
                }
                if mode_name != "plain":
                    payload["response_format"] = {"type": "json_object"}
                t0 = time.time()
                try:
                    r = client.post(
                        f"{GROQ_BASE}/chat/completions",
                        headers={**headers, "Content-Type": "application/json"},
                        json=payload,
                    )
                    ms = round((time.time() - t0) * 1000, 1)
                    if r.status_code == 200:
                        data = r.json()
                        msg = data["choices"][0]["message"]
                        content = msg.get("content")
                        finish_reason = data["choices"][0].get("finish_reason")
                        usage = data.get("usage", {})
                        detail = f"finish={finish_reason} tok={usage.get('prompt_tokens')}+{usage.get('completion_tokens')} content={repr(content)[:110]}"
                    else:
                        detail = r.text[:300]
                    results.append((label, r.status_code, ms, detail, _extract_ratelimit(r.headers)))
                    print(f"[3] {label}: {r.status_code} ({ms}ms) -> {detail} | RL: {_extract_ratelimit(r.headers)}")
                except Exception as e:
                    results.append((label, "EXC", 0, str(e), ""))
                    print(f"[3] {label} EXCEPTION: {e}")

    print("\n" + "=" * 80)
    print("SUMMARY TABLE:")
    for name, status, ms, detail, rl in results:
        print(f"  {name:40s} | {str(status):4s} | {str(ms):7s}ms | {detail[:100]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
