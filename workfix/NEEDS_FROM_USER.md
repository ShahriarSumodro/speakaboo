# Needs From User

## 1. Accept Groq Orpheus TTS Model Terms (Required for Server AI Voices)
Direct API probe (`probe_providers.py`) against your `GROQ_API_KEY` returned HTTP `400 model_terms_required` on all 6 voices (`autumn`, `diana`, `hannah`, `austin`, `daniel`, `troy`) for `canopylabs/orpheus-v1-english`.

**Steps to enable Groq Cloud TTS voices:**
1. Open https://console.groq.com/playground?model=canopylabs%2Forpheus-v1-english in your browser (logged in as the org admin for your Groq key).
2. Review and accept the Orpheus model terms.
3. Wait ~1 minute, then tap **Settings > Diagnostics** in Speakaboo (or re-run `python backend/scripts/probe_providers.py`) — TTS will immediately switch from the on-device English voice fallback to Groq Orpheus character voices.

*(Until you accept those terms, the app uses Android's real on-device `flutter_tts` English voice whenever the server returns `audio_unavailable: true`.)*
