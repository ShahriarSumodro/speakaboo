# Speakaboo — 10-Minute Phone Verification Checklist (`W1`–`W6`)

Use this checklist on your Android phone over USB (`adb reverse tcp:8000 tcp:8000`).

## Pre-Flight (1 minute)
1. Start the backend from `F:\Speakaboo` (do NOT enable `TEST_MODE`):
   ```powershell
   C:\Users\User\AppData\Local\Python\bin\python.exe -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
   ```
2. Connect USB & forward port:
   ```powershell
   adb reverse tcp:8000 tcp:8000
   ```
3. Launch the updated Flutter app on the phone (`http://localhost:8000`).

## Step 1: Settings & Diagnostics (`W3`) — 2 minutes
- Open **Settings > Server Connection (Dev)**.
- Tap **Test Connection**.
  - Expected: `"Connected! (...) - health + auth + profile ok (ok)"`.
  - If `/health` is ok but device auth/profile fails, it now fails loudly instead of faking Connected.
- Tap **Save & Apply** -> fresh token/profile refresh runs automatically and the red `"Server not ready"` banner clears.
- Open **Settings > Diagnostics** and verify all 7 live checks:
  1. **Server reachable (/health)** -> Green
  2. **Device auth + profile** -> Green
  3. **Speech-to-text (Groq Whisper)** -> Green
  4. **Reply generation (Groq Qwen LLM)** -> Green
  5. **Companion voice (Groq Orpheus TTS)** -> Green *(if Orpheus terms are accepted in Groq Console)* OR honest `audio_unavailable` notice *(until terms in `workfix/NEEDS_FROM_USER.md` are accepted; on-device `flutter_tts` fallback speaks replies)*.
  6. **Topics endpoint** -> Green
  7. **Vocabulary add + read** -> Green
- Tap **Copy report** if anything fails and inspect `/api/debug/last_turns` & `/api/debug/last_requests` (with `DEBUG=true`).

## Step 2: Talk 8+ Turns & Retry (`W1`) — 3 minutes
- Go to **Talk** tab, hold the mic and speak: `"Hello Farmer Reggie, yesterday I go to the market."`
- Expected:
  - Your spoken transcript appears cleanly.
  - Farmer Reggie answers with encouraging feedback across **at least 8 consecutive turns** (using `qwen/qwen3.8-27b`).
  - Voice plays via Orpheus WAV chunks (or via clear on-device Android TTS voice if Orpheus terms are not yet accepted on your key).
- Temporarily pause USB/backend, speak once to trigger the error banner, restore USB/backend, and tap **Retry**:
  - Expected: Retry actually re-sends your recorded speech and receives Farmer Reggie's reply (no longer a dead no-op!).

## Step 3: Character Voice Preview (`W2`) — 1 minute
- Open **Characters > Farmer Reggie** -> tap **Hear their voice**.
- Expected: Farmer Reggie speaks aloud (Groq Orpheus WAV when terms are accepted, or seamless Android on-device voice fallback — never stuck with `"Voice preview temporarily unavailable"`).

## Step 4: Shadowing (`W4`) — 2 minutes
- Open **Shadowing** (from Home > Shadowing):
  - Tap **Listen (1.0x)** (and try **0.8x**): Android voice reads the target passage aloud.
  - Tap the mic, speak the passage, and tap stop:
    - Shows real transcript `"You said: ..."`, realistic accuracy %, and realistic pace (`<= 300 WPM`, e.g., `~100-140 WPM`).
  - Tap the mic, say `"I kill people"` (wrong/unsafe words), and tap stop:
    - Shows **0% accuracy** and **0 WPM** (fake `100% / 930 WPM` is gone!).

## Step 5: Topics, Scenarios & Free Talk (`W5`) — 1 minute
- Open **Topics**: real topics load cleanly; pull down or tap Refresh -> refreshes list (if server is offline, shows real error + Retry instead of spinning silently).
- Open **Scenarios**: real scenarios load cleanly; Refresh works & surfaces errors honestly.
- After starting a Topic/Scenario or seeing a Talk error, go to **Home** and tap **Free Talk**:
  - Starts a clean Free Talk conversation with Farmer Reggie (`scenario_id = null`, `topic_id = null`, no stale error).

## Step 6: Vocabulary Notebook (`W6`) — 1 minute
- Open **Profile > Vocabulary Notebook** (or Vocabulary tab), tap **+**:
  - Add `"resilient"` with definition `"Able to recover quickly"`.
  - Tap **Save**: button shows progress while saving to backend, dialog closes only after save + reload succeed, and `"resilient"` stays visible after pulling to refresh (or shows real SnackBar error if backend is unreachable).
