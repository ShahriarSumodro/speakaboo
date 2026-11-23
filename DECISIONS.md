# Speakaboo Decisions Log

Every assumption made instead of asking the user, with reasoning.

---

## Architecture Decisions

### D001: LLM Model Choice (Updated V2)
**Decision:** Default to `openai/gpt-oss-120b` on Groq, backed by automatic runtime fallbacks (`llama-3.3-70b-versatile`, `llama-3.1-8b-instant`).
**Reason:** `meta-llama/llama-4-scout-17b-16e-instruct` was retired by Groq. `openai/gpt-oss-120b` provides fast, structured JSON output and strong conversational instruction following. The fallback list ensures zero downtime if a model is decommissioned.

### D002: TTS Provider (Updated V2)
**Decision:** Default to `canopylabs/orpheus-v1-english` on Groq with valid character-assigned voices: `austin` (Farmer Reggie), `daniel` (Detective Kabir), `diana` (Professor Anika).
**Reason:** `playai-tts` and `Arista-PlayAI` were retired by Groq. Orpheus provides high-quality conversational English speech under the 200-character chunk limit with official, distinct voices.

### D003: Database
**Decision:** SQLite for development, behind a repository abstraction layer.
**Reason:** Per the spec, SQLite for dev with Postgres swap capability. Using SQLAlchemy or raw async SQL with an abstract repository.

### D004: Auth Strategy
**Decision:** Device-based anonymous auth first (UUID generated on first launch, stored locally). Upgradeable to email/password later.
**Reason:** Spec says "device-based anonymous user first, upgradeable to login." Simplest path to get conversations working.

### D005: Timezone for Streaks
**Decision:** All streak day boundaries use `Asia/Dhaka` (UTC+6) timezone.
**Reason:** Target users are in Bangladesh. Spec explicitly says timezone-safe for Asia/Dhaka.

### D006: Pricing
**Decision:** Monthly plan at 200 BDT, per-character unlock at 350 BDT.
**Reason:** Spec suggests "about 200 BDT/month and 350 BDT/character." Using these as defaults in config.

### D007: Pedagogical Experiments & Stable User Hash Bucketing
**Decision:** All teaching and business experiments (EXP001 to EXP006) use SHA-256 hash modulo bucketing (`hash(user_id:exp_id) % variants`), persisted permanently in SQLite table `experiment_assignments`. Sample sizes under 30 display explicit unreliability warnings in `experiments_report.py`.
**Reason:** Guarantees repeatable, invariant user experience across sessions while enforcing rigorous statistical standards on pedagogical conclusions.

---

## NEEDS FROM USER

| Item | Why | Exact Action Required From User | Blocking? |
|---|---|---|---|
| **Google Play Billing Merchant Registration** | Google Play Developer Policy requires Play In-App Billing for apps distributed via Play Store. | 1. Check Google Play Console Payments profile support for Bangladesh bank accounts.<br>2. Confirm whether Bangladeshi users can purchase with local payment methods on Play. | No (Play billing sandbox & mock interface implemented). |
| **bKash Direct vs Aggregator Decision** | Direct bKash merchant API requires Bangladesh Bank MFS operator NOC and Trade License. | Choose between direct bKash merchant account or a licensed payment aggregator (SSLCommerz, AamarPay, PortPos, Shurjopay). | No (Sandbox gateway supports both API shapes). |
| **Nagad Merchant Credentials** | Live production transactions require Nagad Merchant ID and RSA Private Key. | Complete merchant onboarding with Nagad Ltd and add `NAGAD_MERCHANT_ID` and keys to production `.env`. | No (Sandbox gateway handles verification flow). |
| **Groq API Production Key** | Production concurrency for real Whisper STT, GPT-OSS LLM, and Orpheus TTS. | Fund production Groq account and place `GROQ_API_KEY=gsk_...` in `.env`. | No (Test mode handles all CI/unit tests). |
| **App Signing Keystore** | Building production `.aab` for Google Play Store upload. | Generate release keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` and configure `key.properties`. | No (Debug signing config works for dev & tests). |
| **Children's App Legal Review** | Formal legal compliance with COPPA and Google Play Designed for Families policy. | Have qualified legal counsel review `PLAY_STORE_METADATA.md` and privacy policy disclosures. | No (Full disclosures already drafted in markdown). |
