# Speakaboo Market Launch Readiness Checklist

Comprehensive verification checklist for launching Speakaboo to students, parents, and schools across Bangladesh and publishing on Google Play Store.

---

## 1. Compliance & App Store Policies

- [ ] **Google Play Billing Policy Compliance:**
  - `play` flavor strictly enforces Google Play In-App Billing for digital subscriptions and character unlocks.
  - `direct` flavor (for direct website APK distribution) uses bKash and Nagad checkout.
  - Zero alternative direct billing links or payment screens inside the Play-distributed build.
- [ ] **Families Policy & COPPA Compliance:**
  - Content rating questionnaire verified: Everyone (3+).
  - Target audience declaration: Children (Ages 6-12) & General Audience.
  - Zero raw voice audio stored or transmitted to unverified third parties.
  - Parent Dashboard locked behind PBKDF2 4-digit Parent PIN.
  - Zero behavioral advertising, third-party analytics trackers, or user profiling.
- [ ] **Data Safety & Privacy:**
  - Complete Data Safety declarations published in `PLAY_STORE_METADATA.md`.
  - In-app Account & Data deletion mechanism (`DELETE /api/privacy/user/{id}`) operational and tested.
  - Privacy Policy and Terms of Service available in both English and Bangla.

---

## 2. Infrastructure, Security & Reliability

- [ ] **Backend Production Deployment:**
  - Multi-stage Docker container deployed with non-root user `appuser`.
  - Health check probe (`GET /api/health`) reporting healthy database, providers, and uptime.
  - Automated SQLite database backup script (`backend/scripts/backup_db.py`) scheduled via daily cron.
  - Reverse proxy SSL termination (Caddy / Nginx) with WebSockets & SSE streaming support.
- [ ] **Rate Limiting & Abuse Prevention:**
  - 120 requests/minute client IP rate limit active.
  - 10MB payload size limit enforced on audio uploads.
  - HMAC-SHA256 signed tokens required on all user data routes.
- [ ] **AI Infrastructure Unit Economics:**
  - Real-time turn cost logging active across STT, LLM, and TTS.
  - Unit-cost guard in place: alerts if average cost per learner-minute exceeds revenue threshold.
  - Multi-tier LLM fallback chain (`gpt-oss-120b` -> `llama-3.3-70b-versatile` -> `llama-3.1-8b-instant`).

---

## 3. Client Performance & Low-End Android Profile

- [ ] **Low-Memory Device Performance (2GB–3GB RAM):**
  - Cold start time under 3.5 seconds on target device profile.
  - Offline local cache (`CacheService`) renders home screen and catalog instantly without network stalls.
  - Low-bandwidth audio compression (16 kHz mono Opus/WAV) preserves mobile data.
  - Release APK size optimized via R8/Proguard rules (`app/android/app/proguard-rules.pro`).
- [ ] **UI & Visual Consistency:**
  - 60-30-10 palette verified across both Light and Warm Dark themes.
  - Minimum 44px tap targets enforced for accessibility on small screens.
  - Zero hardcoded mock text or dead buttons (`tools/reality_audit.py` passes with 0 violations).

---

## 4. Needs From User (Blockers for Real Merchant Activation)

| Action Item | Responsible Party | Impact / Blocking |
|---|---|---|
| **Google Play Merchant Registration:** Confirm Bangladesh merchant registration eligibility for IAP subscriptions on Play Console. | User / Founder | Required for production Play Store billing. |
| **bKash Merchant Approval vs Aggregator:** Select direct merchant API (requires Bangladesh Bank MFS license) or licensed aggregator (SSLCommerz / AamarPay). | User / Founder | Required for live bKash payments outside sandbox. |
| **Nagad Merchant Credentials:** Acquire live merchant ID and RSA key pair from Nagad Ltd. | User / Founder | Required for live Nagad payments outside sandbox. |
| **Production Groq API Key:** Fund production Groq account for high-concurrency production traffic. | User / Founder | Required for production scale. |
| **App Signing Keystore:** Generate upload keystore and configure GitHub Secrets / Play App Signing. | User / Founder | Required for building release `.aab`. |

---

## 5. Pilot Metrics & Launch Thresholds

| Metric | Target Threshold | Pilot Gate Verification |
|---|---|---|
| **Day-1 Retention (D1):** | >= 40% | Monitored via `pilot_report.py` |
| **Day-7 Retention (D7):** | >= 20% | Monitored via `pilot_report.py` |
| **Weekly Active Sessions:** | Median >= 3 sessions/week | Monitored via `pilot_report.py` |
| **First Conversation Completion:** | >= 60% of new installs | Monitored via `pilot_report.py` |
| **Speaking Check Gain:** | Positive WPM / clarity change | Monitored via `pilot_report.py` |
| **Net Operational Margin:** | Revenue > AI Infrastructure Cost | Monitored via `revenue_report.py` |
