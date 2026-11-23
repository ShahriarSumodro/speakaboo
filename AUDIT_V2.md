# Speakaboo Audit V2: Defect Verification and Reality Log

Date: 2026-11-24
Status: REPRODUCED & CONFIRMED

---

## 1. Verified Defect A: App Cannot Reach Backend on Real Phone

### Proof / Findings
1. **Default Backend URL:**
   - File: `app/lib/config/app_config.dart:10-13`
   - Found: `defaultValue: 'http://10.0.2.2:8000'`
   - Problem: `10.0.2.2` is only routed by the Android emulator host loopback. On a physical Android device connected via USB with `adb reverse tcp:8000 tcp:8000`, or over Wi-Fi, the app fails to connect.
2. **Missing Android Permissions in Release Manifest:**
   - File: `app/android/app/src/main/AndroidManifest.xml`
   - Found: No `<uses-permission android:name="android.permission.INTERNET"/>` and no `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`.
   - Problem: Without these permissions in `main/AndroidManifest.xml`, release builds cannot access the network or record microphone audio.
3. **Missing Network Security Config:**
   - No `network_security_config.xml` configured to permit cleartext `http://localhost:8000` or local subnet IP addresses for development on physical Android devices.
4. **No Runtime Developer Settings:**
   - No UI exists to view or modify the backend URL at runtime without recompiling.

### Solution Requirements (Phase 0)
- Set default URL to `http://localhost:8000` (ready for `adb reverse tcp:8000 tcp:8000`).
- Support `--dart-define=BACKEND_URL=...`.
- Add runtime hidden developer settings screen / modal to change backend URL dynamically with persistent storage.
- Add `INTERNET`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS` to `main/AndroidManifest.xml`.
- Add Android network security configuration for cleartext traffic on localhost and local subnets in debug/profile builds.
- Document USB debugging and run commands in `README.md`.

---

## 2. Verified Defect B: Groq Models and Voices Retired / Non-functional

### Proof / Findings
1. **Retired TTS Model & Voice:**
   - Files: `backend/config.py:62-63`, `backend/providers/groq_tts.py:27`, `.env.example:25-26`
   - Found: `model: str = "playai-tts"`, `voice: str = "Arista-PlayAI"`
   - Problem: Groq retired `playai-tts` and `Arista-PlayAI`. Current Groq TTS model is `canopylabs/orpheus-v1-english` with official voices: `autumn`, `diana`, `hannah`, `austin`, `daniel`, `troy`. Chunk size limit is 200 characters per request.
2. **Shut-down Groq LLM Model:**
   - Files: `backend/config.py:53`, `backend/providers/groq_llm.py:28`, `.env.example:19`
   - Found: `model: str = "meta-llama/llama-4-scout-17b-16e-instruct"`
   - Problem: `llama-4-scout-17b-16e-instruct` is defunct/retired on Groq. Up-to-date replacement models include `openai/gpt-oss-120b`, `llama-3.3-70b-versatile`, and `llama-3.1-8b-instant`.
3. **Fictitious Voice IDs in Character JSONs and UI:**
   - Files: `backend/characters/*.json`, `app/lib/screens/characters_screen.dart:23,33,43`
   - Found: `Arista-PlayAI`, `Kabir-Voice`, `Anika-Voice`.
   - Problem: None of these are valid Groq voices. Valid voices for `canopylabs/orpheus-v1-english` are:
     - `austin` (warm male, ideal for Farmer Reggie)
     - `daniel` (sharp male, ideal for Detective Kabir)
     - `diana` (warm female, ideal for Professor Anika)
     - `autumn`, `hannah`, `troy`
4. **Missing Startup Validation and Provider Verification:**
   - The backend previously had no startup check verifying configured models against `GET https://api.groq.com/openai/v1/models`.
   - No `backend/scripts/verify_providers.py` existed to run real calls to STT, LLM, and TTS.
   - Normal mode allowed silent mock fallback instead of failing loudly if keys were missing.

### Solution Requirements (Phase 0)
- Update default TTS to `canopylabs/orpheus-v1-english` with valid character voices (`austin`, `daniel`, `diana`).
- Update default LLM to `openai/gpt-oss-120b` (fallback: `llama-3.3-70b-versatile`, `llama-3.1-8b-instant`).
- Add startup model and voice validation.
- Enforce strict refusal to start in normal mode when real keys are missing (`--test` / `TEST_MODE=1` only for automated test suites).
- Create `backend/scripts/verify_providers.py`.

---

## 3. Verified Defect C: Hardcoded Prototype Screens in Flutter

### Proof / Findings
1. **`MissionsScreen` (`app/lib/screens/missions_screen.dart`):**
   - Contains `final List<Map<String, dynamic>> _missions = [...]` with static data.
   - Claim Reward only updates local state in memory.
   - Tapping mission cards does nothing except show local state.
2. **`ProfileScreen` (`app/lib/screens/profile_screen.dart`):**
   - Hardcoded user name "Nabil Rahman", Level 3, 340 XP, 3 days streak.
   - Vocabulary Notebook card does not navigate to a notebook screen.
   - Parent Dashboard card only displays a SnackBar with fake text (`"Parent Dashboard: 45 mins spoken this week..."`).
3. **`CharactersScreen` (`app/lib/screens/characters_screen.dart`):**
   - Contains `static const List<Map<String, dynamic>> _characters = [...]`.
   - Character ID mismatch: lists `eco_scholar` instead of backend `professor_anika`.
   - Active character is hardcoded.
   - Unlock button shows `"Mock bKash payment initiated for..."` in a SnackBar.
4. **Missing Screens:**
   - No screens exist for Scenarios, Topics, Shadowing, Vocabulary Notebook, Parent Dashboard, or Settings.
5. **`ApiService` (`app/lib/services/api_service.dart`):**
   - Only implements `turn()` and `healthCheck()`.
   - Zero methods for `/characters`, `/missions`, `/progress`, `/vocabulary`, `/scenarios`, `/topics`, `/shadowing`, `/parent`, `/auth`.
6. **Hardcoded User:**
   - `app/lib/providers/conversation_provider.dart` hardcodes `user_id = 'device-user'`.
   - The app never calls `/api/auth/device`.

### Solution Requirements (Phases 1-3)
- Wire every screen to backend endpoints.
- Build real screens for Scenarios, Topics, Shadowing, Vocabulary, Parent Dashboard, Settings.
- Implement full typed API client in `ApiService`.
- Persist real device token with `flutter_secure_storage` or persistent store and authenticate automatically.

---

## 4. Verified Defect D: Backend Security and Architectural Gaps

### Proof / Findings
1. **In-Memory User Storage & Broken Auth:**
   - `backend/routes/auth.py` maintains `_users: dict` and `_device_to_user: dict`.
   - Restarting server wipes all users.
   - No authentication tokens (JWT or signed token) issued.
   - Any client can query or alter arbitrary user data by providing any `user_id`.
2. **Overly Permissive CORS:**
   - `backend/main.py:53` uses `allow_origins=["*"]`.
3. **Blocking Turn Execution:**
   - `/api/conversation/turn` processes STT, LLM, and full TTS synchronously before returning, causing 3-5+ second latency before any learner audio can play.

### Solution Requirements (Phase 1)
- Persistent SQLite repository for users, profiles, and tokens.
- Signed bearer auth tokens issued by `/api/auth/device`.
- Dependency injection / middleware requiring valid token on `/api/*` user endpoints.
- Restrict CORS and add rate limiting per user.
- Stream conversation turns via Server-Sent Events (SSE) or WebSocket (transcript early -> LLM tokens -> sentence TTS chunks).

---

## 5. Verified Defect E: Missing Product & Visual Architecture Pieces

### Proof / Findings
1. **No Dark Theme:**
   - `app/lib/config/theme.dart` defines hardcoded constants (`background = Color(0xFFFBF8F5)`).
   - No `ThemeData.dark()`, no design tokens for warm dark palette.
2. **No Character Audio Preview:**
   - No audio playback of voice sample before buying.
3. **Missing Placement, Onboarding & Parent Gate:**
   - No diagnostic spoken placement test.
   - No PIN protection for parent dashboard.
   - No retention hooks or notifications.

---

## Conclusion
All defects in Section 4 are verified by direct code inspection and runtime checks. V2 Build Loop will now proceed systematically through Phases 0 to 10.
