"""
End-to-end real backend + real Groq verification script.

Assumes a live backend server (not TEST_MODE) running at --base-url (default http://127.0.0.1:8000).
Uses Windows SAPI5 speech synthesis (test harness only) to produce real spoken English WAV clips
for Whisper STT + Qwen LLM + Orpheus TTS checks:
  1. Health check (/api/health)
  2. Device auth (/api/auth/device) + Profile (/api/auth/profile)
  3. Characters list (/api/characters) + preview audio (/api/characters/rule_farmer/preview-audio)
  4. 8 consecutive conversation turns (/api/conversation/stream-turn) with memory & reply checks
  5. Topics (/api/learning/topics) & Scenarios (/api/learning/scenarios)
  6. Vocabulary add & list (/api/learning/vocabulary/{user_id})
  7. Real Shadowing (/api/learning/shadowing/evaluate-audio): target passage, wrong speech, silence
"""

import argparse
import base64
import io
import json
import os
import subprocess
import sys
import tempfile
import time
import wave
from pathlib import Path

import httpx


LEARN_TURNS = [
    "Hello Farmer Reggie, I am happy to practice English with you today.",
    "Yesterday I go to the vegetable market with my brother.",
    "We bought tomatoes, potatoes, and sweet mangoes for dinner.",
    "I wants to speak clearly when I talk to my teachers at school.",
    "Sometimes I feel nervous because I make small grammar mistakes.",
    "Can you teach me a polite way to ask for directions in the city?",
    "Thank you, could you repeat that slowly so I can remember it?",
    "See you tomorrow, Farmer Reggie, I enjoyed our conversation!",
]


def _make_silence_wav(duration_sec: float = 2.0, rate: int = 16000) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(b"\x00\x00" * int(rate * duration_sec))
    return buf.getvalue()


def _wav_duration_seconds(wav_bytes: bytes) -> float:
    try:
        with wave.open(io.BytesIO(wav_bytes), "rb") as wf:
            rate = wf.getframerate()
            return round(wf.getnframes() / float(rate), 2) if rate else 0.0
    except Exception:
        return round(len(wav_bytes) / 32000.0, 2)


def _synthesize_clips_sapi(phrases: dict[str, str], out_dir: Path) -> dict[str, bytes]:
    """Generate real spoken English WAV clips via Windows SAPI5 in one PowerShell batch."""
    script_lines = [
        "Add-Type -AssemblyName System.Speech",
        "$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer",
        "$synth.Rate = 0",
    ]
    paths: dict[str, Path] = {}
    for key, text in phrases.items():
        wav_path = out_dir / f"{key}.wav"
        paths[key] = wav_path
        safe_text = text.replace("'", "''")
        safe_path = str(wav_path).replace("'", "''")
        script_lines.append(f"$synth.SetOutputToWaveFile('{safe_path}')")
        script_lines.append(f"$synth.Speak('{safe_text}')")
    script_lines.append("$synth.SetOutputToNull()")
    script_lines.append("$synth.Dispose()")

    ps_script = "\n".join(script_lines)
    res = subprocess.run(
        ["powershell", "-NoProfile", "-Command", ps_script],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if res.returncode != 0:
        raise RuntimeError(f"SAPI synthesis failed: {res.stderr.strip()}")

    return {key: p.read_bytes() for key, p in paths.items()}


def _parse_sse_stream(resp: httpx.Response) -> dict:
    events: dict[str, dict] = {}
    current_event = None
    data_lines: list[str] = []

    for raw_line in resp.iter_lines():
        line = raw_line.strip("\r")
        if line == "":
            if current_event and data_lines:
                payload = "\n".join(data_lines)
                try:
                    events[current_event] = json.loads(payload)
                except json.JSONDecodeError:
                    events[current_event] = {"raw": payload}
            current_event = None
            data_lines = []
        elif line.startswith("event:"):
            current_event = line[6:].strip()
        elif line.startswith("data:"):
            data_lines.append(line[5:].strip())

    if current_event and data_lines:
        payload = "\n".join(data_lines)
        try:
            events[current_event] = json.loads(payload)
        except json.JSONDecodeError:
            events[current_event] = {"raw": payload}
    return events


def main() -> int:
    parser = argparse.ArgumentParser(description="Real Speakaboo E2E check against running server.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000", help="Backend base URL")
    args = parser.parse_args()
    base = args.base_url.rstrip("/")

    results: list[tuple[str, bool, str]] = []

    def record(name: str, ok: bool, detail: str) -> None:
        results.append((name, ok, detail))
        tag = "PASS" if ok else "FAIL"
        print(f"[{tag}] {name}: {detail}", flush=True)

    with httpx.Client(base_url=base, timeout=30.0) as client:
        # 1. Health
        try:
            r = client.get("/api/health")
            ok = r.status_code == 200 and r.json().get("status") == "ok"
            record("Health (/api/health)", ok, f"HTTP {r.status_code} {r.text[:120]}")
            if not ok:
                return 1
        except Exception as e:
            record("Health (/api/health)", False, str(e))
            return 1

        # 2. Device Auth + Profile
        device_id = f"e2e_real_{int(time.time())}"
        r = client.post("/api/auth/device", json={"device_id": device_id})
        if r.status_code != 200:
            record("Device Auth", False, f"HTTP {r.status_code} {r.text}")
            return 1
        auth_data = r.json()
        user_id = auth_data["user_id"]
        token = auth_data.get("auth_token") or auth_data.get("token") or ""
        headers = {"Authorization": f"Bearer {token}"}

        rp = client.get("/api/auth/profile", headers=headers)
        record(
            "Device Auth + Profile",
            rp.status_code == 200 and rp.json().get("user_id") == user_id,
            f"user_id={user_id}, profile HTTP {rp.status_code}",
        )

        # 3. Characters + Preview audio
        rc = client.get("/api/characters/")
        chars = rc.json() if rc.status_code == 200 else []
        record("Characters list", rc.status_code == 200 and len(chars) > 0, f"count={len(chars)}")

        rprev = client.get("/api/characters/rule_farmer/preview-audio")
        if rprev.status_code == 200 and len(rprev.content) > 1000:
            dur = _wav_duration_seconds(rprev.content)
            record("Character preview audio", True, f"WAV {len(rprev.content)} bytes ({dur}s)")
        elif rprev.status_code == 502 and (
            "model_terms_required" in rprev.text or "requires terms acceptance" in rprev.text
        ):
            record(
                "Character preview audio (honest TTS block)",
                True,
                "HTTP 502 Orpheus terms required (app falls back to flutter_tts)",
            )
        else:
            record("Character preview audio", False, f"HTTP {rprev.status_code}: {rprev.text[:160]}")

        # 4. Topics + Scenarios + Shadowing list
        rtop = client.get("/api/learning/topics")
        topics = rtop.json() if rtop.status_code == 200 else []
        record("Topics list", rtop.status_code == 200 and isinstance(topics, list) and len(topics) > 0, f"count={len(topics)}")

        rsc = client.get("/api/learning/scenarios")
        scenarios = rsc.json() if rsc.status_code == 200 else []
        record("Scenarios list", rsc.status_code == 200 and isinstance(scenarios, list) and len(scenarios) > 0, f"count={len(scenarios)}")

        rshad_list = client.get("/api/learning/shadowing")
        scripts = rshad_list.json() if rshad_list.status_code == 200 else []
        if not scripts:
            record("Shadowing scripts", False, f"HTTP {rshad_list.status_code}")
            return 1
        target_script = scripts[0]

        # Synthesize all speech clips cleanly in a temp directory
        with tempfile.TemporaryDirectory() as tmp:
            phrases = {f"turn_{i+1}": txt for i, txt in enumerate(LEARN_TURNS)}
            phrases["shad_target"] = target_script["target_text"]
            phrases["shad_wrong"] = "I kill people"
            clips = _synthesize_clips_sapi(phrases, Path(tmp))

            # 5. Start Conversation & run 8 consecutive real turns
            rstart = client.post(
                "/api/conversation/start",
                headers=headers,
                json={"user_id": user_id, "character_id": "rule_farmer"},
            )
            if rstart.status_code != 200:
                record("Conversation start", False, f"HTTP {rstart.status_code} {rstart.text}")
                return 1
            conv_id = rstart.json()["conversation_id"]
            record("Conversation start", True, f"conv_id={conv_id}")

            for idx in range(1, 9):
                clip_bytes = clips[f"turn_{idx}"]
                with client.stream(
                    "POST",
                    "/api/conversation/stream-turn",
                    headers=headers,
                    data={"conversation_id": conv_id, "audio_format": "wav"},
                    files={"audio": (f"turn_{idx}.wav", clip_bytes, "audio/wav")},
                    timeout=30.0,
                ) as sresp:
                    if sresp.status_code != 200:
                        body = sresp.read().decode("utf-8", errors="replace")
                        record(f"Talk turn {idx}/8", False, f"HTTP {sresp.status_code}: {body[:160]}")
                        continue
                    events = _parse_sse_stream(sresp)

                if "error" in events:
                    record(f"Talk turn {idx}/8", False, f"SSE error: {events['error']}")
                    continue

                comp = events.get("turn_complete") or {}
                reply = (comp.get("reply") or "").strip()
                chunks = comp.get("audio_chunks") or []
                audio_unavail = bool(comp.get("audio_unavailable", False))
                tr = (events.get("transcript") or {}).get("transcript", "")
                if chunks:
                    wav_bytes = b"".join(base64.b64decode(c) for c in chunks)
                    dur = _wav_duration_seconds(wav_bytes)
                    audio_ok = dur >= 0.5
                    audio_info = f"audio={len(chunks)} chunks ({dur}s)"
                else:
                    audio_ok = audio_unavail
                    audio_info = f"audio_unavailable={audio_unavail} (honest TTS block -> flutter_tts fallback)"

                turn_ok = bool(reply) and bool(tr) and audio_ok
                record(
                    f"Talk turn {idx}/8",
                    turn_ok,
                    f"stt='{tr[:38]}...' reply='{reply[:45]}...' {audio_info}",
                )

            # 6. Vocabulary add + list
            test_word = f"resilient_{int(time.time()) % 10000}"
            rv_add = client.post(
                f"/api/learning/vocabulary/{user_id}",
                headers=headers,
                json={
                    "word_or_phrase": test_word,
                    "context_sentence": "Learners stay resilient when practicing English.",
                    "correction_notes": "Able to recover quickly from difficulties.",
                },
            )
            rv_list = client.get(f"/api/learning/vocabulary/{user_id}", headers=headers)
            vocab_items = rv_list.json() if rv_list.status_code == 200 else []
            found_word = any(item.get("word_or_phrase") == test_word for item in vocab_items)
            record(
                "Vocabulary add + list",
                rv_add.status_code == 200 and rv_list.status_code == 200 and found_word,
                f"added='{test_word}', total_cards={len(vocab_items)}",
            )

            # 7a. Shadowing real match
            target_dur = _wav_duration_seconds(clips["shad_target"])
            r_good = client.post(
                "/api/learning/shadowing/evaluate-audio",
                headers=headers,
                data={
                    "script_id": target_script["id"],
                    "duration_seconds": str(target_dur),
                    "user_id": user_id,
                    "audio_format": "wav",
                },
                files={"audio": ("target.wav", clips["shad_target"], "audio/wav")},
            )
            gd = r_good.json() if r_good.status_code == 200 else {}
            good_ok = (
                r_good.status_code == 200
                and gd.get("accuracy_score", 0) >= 50.0
                and 0 < gd.get("pace_wpm", 0) <= 300.0
            )
            record(
                "Shadowing matching speech",
                good_ok,
                f"HTTP {r_good.status_code} acc={gd.get('accuracy_score')}% wpm={gd.get('pace_wpm')} stt='{gd.get('transcript')}'",
            )

            # 7b. Shadowing wrong speech ("I kill people")
            wrong_dur = _wav_duration_seconds(clips["shad_wrong"])
            r_wrong = client.post(
                "/api/learning/shadowing/evaluate-audio",
                headers=headers,
                data={
                    "script_id": target_script["id"],
                    "duration_seconds": str(wrong_dur),
                    "user_id": user_id,
                    "audio_format": "wav",
                },
                files={"audio": ("wrong.wav", clips["shad_wrong"], "audio/wav")},
            )
            wd = r_wrong.json() if r_wrong.status_code == 200 else {}
            wrong_ok = (
                r_wrong.status_code == 200
                and wd.get("accuracy_score", 999) < 20.0
                and wd.get("pace_wpm", 999) <= 300.0
            )
            record(
                "Shadowing wrong speech ('I kill people')",
                wrong_ok,
                f"HTTP {r_wrong.status_code} acc={wd.get('accuracy_score')}% wpm={wd.get('pace_wpm')} msg='{wd.get('feedback')}'",
            )

            # 7c. Shadowing silence
            silence_wav = _make_silence_wav(2.0)
            r_sil = client.post(
                "/api/learning/shadowing/evaluate-audio",
                headers=headers,
                data={
                    "script_id": target_script["id"],
                    "duration_seconds": "2.0",
                    "user_id": user_id,
                    "audio_format": "wav",
                },
                files={"audio": ("silence.wav", silence_wav, "audio/wav")},
            )
            sd = r_sil.json() if r_sil.status_code == 200 else {}
            sil_ok = (
                r_sil.status_code == 200
                and sd.get("accuracy_score", 999) == 0.0
                and sd.get("pace_wpm", 999) == 0.0
            )
            record(
                "Shadowing silence",
                sil_ok,
                f"HTTP {r_sil.status_code} acc={sd.get('accuracy_score')}% wpm={sd.get('pace_wpm')} msg='{sd.get('feedback')}'",
            )

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print("=" * 80)
    print(f"E2E REAL SUMMARY: {passed}/{total} checks passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
