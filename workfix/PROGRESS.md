# Speakaboo Make-It-Work Loop — Progress

## Current Phase
COMPLETE — All Phases (0–6) Done & Verified

## NEXT ACTION
User action (optional, for server AI voices): accept Groq Orpheus terms in `workfix/NEEDS_FROM_USER.md`, then run the 10-minute checklist in `workfix/PHONE_TEST.md`.

## W1–W6 Symptom Tracker

| ID | Symptom | Status | Suspected/Proven Cause | Fix Commit |
|----|---------|--------|------------------------|------------|
| W1 | Talk: "I could not think of a reply. Tap to retry." / earlier text only, no voice | FIXED | `qwen/qwen3.8-27b` + `max_tokens=512`; sequential WAV + `flutter_tts` fallback; `retryLastTurn()` resends stored audio | `da0070e`, `59668ec` |
| W2 | Characters: Farmer Reggie preview "Voice preview temporarily unavailable" | FIXED | Orpheus terms noted in `NEEDS_FROM_USER.md`; `CharacterDetailScreen` falls back to `flutter_tts` | `fe723ce` |
| W3 | Settings: Test Connection says Connected, features still fail | FIXED | `DevServerDialog` now tests `/api/health` -> `/api/auth/device` -> `/api/auth/profile` before showing Connected, and `Save & Apply` awaits `AuthProvider.reauthenticate()` | `e35bb7f` |
| W4 | Shadowing: nothing spoken, "I kill people" got 100% / 930 WPM | FIXED | `POST /api/learning/shadowing/evaluate-audio` transcribes real audio via STT, scores matched words & clamps pace WPM; `ShadowingScreen` adds `flutter_tts` Listen & uploads audio | `d1bc362` |
| W5 | Topics & Scenarios: Refresh does nothing, Free Talk returns to Talk | FIXED | List parsing fixed in `3c98132`; `TopicsScreen`/`ScenariosScreen` surface real error + `RefreshIndicator` + Retry; `startFreeTalk()` clears scenario/topic/error on Free Talk tap | `c3f34cc` |
| W6 | Vocabulary notebook: typing & adding word does nothing | FIXED | Awaits auth init + save before closing dialog/reloading; surfaces SnackBar & dialog error on failure; load error shows Retry | `d0ed38c` |
