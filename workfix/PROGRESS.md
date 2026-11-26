# Speakaboo Make-It-Work Loop — Progress

## Current Phase
Phase 3: Build Diagnostics Screen (followed by Phase 4: Fix W1–W6 in order)

## NEXT ACTION
Commit Phase 0–2 observability & probes, then build Settings > Diagnostics screen (Phase 3).

## W1–W6 Symptom Tracker

| ID | Symptom | Status | Suspected/Proven Cause | Fix Commit |
|----|---------|--------|------------------------|------------|
| W1 | Talk: "I could not think of a reply. Tap to retry." / earlier text only, no voice | PROVEN (`[API]+[BACKEND]+[APP]`) | `gpt-oss-120b` hits `400 json_validate_failed` with `max_tokens=256` & 404 fallbacks; Orpheus `400 model_terms_required`; `playChunks` concats WAV headers; Retry calls `clearError()` | Pending Phase 4 |
| W2 | Characters: Farmer Reggie preview "Voice preview temporarily unavailable" | PROVEN (`[API]+[APP]`) | Orpheus `400 model_terms_required` -> 502; app needs real `flutter_tts` fallback when `audio_unavailable` | Pending Phase 4 |
| W3 | Settings: Test Connection says Connected, features still fail | PROVEN (`[APP]`) | Only tests `/api/health`; doesn't test device auth or authenticated API, and `Save & Apply` doesn't force fresh token check | Pending Phase 4 |
| W4 | Shadowing: nothing spoken, "I kill people" got 100% / 930 WPM | PROVEN (`[APP]+[BACKEND]`) | Screen sends `targetText` instead of recorded audio; no companion playback; backend lacks STT shadowing endpoint & WPM clamp | Pending Phase 4 |
| W5 | Topics & Scenarios: Refresh does nothing, Free Talk returns to Talk | PROVEN (`[APP]`) | `ApiService` indexes `data['topics']`/`data['scenarios']` on JSON List response -> `TypeError`; Free Talk doesn't reset/start clean session | Pending Phase 4 |
| W6 | Vocabulary notebook: typing & adding word does nothing | PROVEN (`[APP]`) | Route fixed in `b964a42`, but `VocabularyScreen` still swallows add/load errors silently without SnackBar/retry or ensuring auth | Pending Phase 4 |
