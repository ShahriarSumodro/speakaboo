# Speakaboo Make-It-Work Loop — Progress

## Current Phase
Phase 4: Fix W1–W6 in order (Fix 6 Topics/Scenarios/Free Talk complete; next: Fix 7 Vocabulary)

## NEXT ACTION
Fix W6 (Vocabulary), then W3 (Settings), then Phase 5 (`e2e_real.py`, `PHONE_TEST.md`).

## W1–W6 Symptom Tracker

| ID | Symptom | Status | Suspected/Proven Cause | Fix Commit |
|----|---------|--------|------------------------|------------|
| W1 | Talk: "I could not think of a reply. Tap to retry." / earlier text only, no voice | FIXED | `qwen/qwen3.8-27b` + `max_tokens=512`; sequential WAV + `flutter_tts` fallback; `retryLastTurn()` resends stored audio | `da0070e`, `59668ec` |
| W2 | Characters: Farmer Reggie preview "Voice preview temporarily unavailable" | FIXED | Orpheus terms noted in `NEEDS_FROM_USER.md`; `CharacterDetailScreen` falls back to `flutter_tts` | `fe723ce` |
| W3 | Settings: Test Connection says Connected, features still fail | PROVEN (`[APP]`) | Only tests `/api/health`; doesn't test device auth or authenticated API, and `Save & Apply` doesn't force fresh token check | Pending Phase 4 |
| W4 | Shadowing: nothing spoken, "I kill people" got 100% / 930 WPM | FIXED | `POST /api/learning/shadowing/evaluate-audio` transcribes real audio via STT, scores matched words & clamps pace WPM; `ShadowingScreen` adds `flutter_tts` Listen & uploads audio | `d1bc362` |
| W5 | Topics & Scenarios: Refresh does nothing, Free Talk returns to Talk | FIXED | List parsing fixed in `3c98132`; `TopicsScreen`/`ScenariosScreen` surface real error + `RefreshIndicator` + Retry; `startFreeTalk()` clears scenario/topic/error on Free Talk tap | Pending commit (Fix 6) |
| W6 | Vocabulary notebook: typing & adding word does nothing | PROVEN (`[APP]`) | Route fixed in `b964a42`, but `VocabularyScreen` still swallows add/load errors silently without SnackBar/retry or ensuring auth | Pending Phase 4 |
