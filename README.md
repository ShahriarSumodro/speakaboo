# Speakaboo 🦉
> **English Speaking Companion for Learners in Bangladesh**

Speakaboo is a spoken English practice mobile app (and future physical toy companion) designed for children, school students, and university learners across Bangladesh. The goal is building spoken fluency and daily speaking confidence by conversing with distinct AI character companions who reply in short, spoken turns, gently correct grammar slips in character, and keep learners engaged through streaks, XP, and daily missions.

The app works **fully standalone without the physical device**. Hardware toy support via Bluetooth Low Energy (BLE) is ready as an optional companion.

---

## 🎯 Hard Rules & Guiding Principles

1. **Clean Architecture**: Flutter mobile app in `/app`, Python FastAPI backend in `/backend`. API keys live **only** in the backend `.env`.
2. **Swappable AI Providers**: STT (`SttProvider`), LLM (`LlmProvider`), and TTS (`TtsProvider`) are abstract interfaces. Defaults use Groq Whisper Large v3 Turbo, Groq chat models (`llama-4-scout-17b-16e-instruct`), and PlayAI TTS, with mock implementations for offline development and testing.
3. **Short Spoken Turns**: AI replies are strictly constrained to **max 2 sentences** and **under 200 characters per TTS chunk** for natural conversational pacing, low latency (<2.5s turnaround), and high student speaking time.
4. **Kid Safety First**: All student and AI messages pass through real-time safety classification. Violence, sexual content, self-harm, drugs, and personal identifying data (address, school, phone) are blocked and gently redirected. **Raw voice audio is NEVER stored**.
5. **Original Characters Only**: Companion characters are defined as external JSON data files (e.g. `rule_farmer` - Farmer Reggie, `dhaka_detective` - Detective Kabir, `professor_anika` - Professor Anika).
6. **Timezone-Safe Streaks**: Daily rollover operates strictly in `Asia/Dhaka` (UTC+6) time.
7. **Monetization & Entitlements**: Payment integration (`PaymentGateway`) supports bKash and Nagad with mock sandbox flows and subscription/character unlock entitlements.
8. **60-30-10 Design System**: Follows the strict warm palette:
   - 60% Background: `#FBF8F5`
   - 30% Surface: `#F1E9E1`
   - 10% Accent: `#F26B21`
   - Text Primary: `#2A211B`

---

## 🏗️ Repository Structure

```
speakaboo/
├── app/                          # Flutter Mobile Application
│   ├── lib/
│   │   ├── config/               # Theme tokens (60-30-10), app config
│   │   ├── services/             # ApiService, AudioService, AnalyticsService
│   │   ├── providers/            # ConversationProvider
│   │   ├── screens/              # Talk, Characters, Missions, Profile, Onboarding, BLE Pairing
│   │   └── widgets/              # Animated CharacterFace, CorrectionChip, Sheets
│   └── test/                     # Flutter widget & unit test suite
├── backend/                      # Python FastAPI Backend
│   ├── config.py                 # Pydantic/dataclass environment loader
│   ├── main.py                   # FastAPI application & lifecycle hooks
│   ├── characters/               # Companion character JSON definitions
│   ├── providers/                # SttProvider, LlmProvider, TtsProvider, PaymentGateway
│   ├── engine/                   # Conversation, Correction, Safety, Gamification, BLE Transport, Group Chat
│   ├── models/                   # User, Learning, Turn, Entitlement models
│   ├── repositories/             # SQLite / Postgres repository abstraction
│   ├── routes/                   # REST API routes (conversation, auth, payment, privacy, etc.)
│   ├── scripts/                  # Load test runner, AI cost estimator
│   └── tests/                    # Comprehensive pytest suite (115+ tests)
├── ARCHITECTURE.md               # Data flow, BLE protocol, interfaces, schemas
├── DESIGN.md                     # UI rules, typography, gestures, accessibility
├── DECISIONS.md                  # Log of architectural assumptions
├── PROGRESS.md                   # Build loop tracking and test audit
└── README.md
```

---

## ⚙️ Setup & Installation

### Prerequisites
- Python 3.11+
- Flutter 3.19+
- Git

### 1. Backend Setup

```bash
# Clone the repository
git clone https://github.com/your-org/speakaboo.git
cd speakaboo

# Create and activate Python virtual environment
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
# Or via pyproject.toml:
pip install -e .
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Key environment variables:
| Variable | Default | Purpose |
|----------|---------|---------|
| `GROQ_API_KEY` | `""` | Groq API key for Whisper STT and chat models (leave empty for offline mock mode) |
| `STT_PROVIDER` | `mock` | `mock` or `groq` |
| `LLM_PROVIDER` | `mock` | `mock` or `groq` |
| `TTS_PROVIDER` | `mock` | `mock` or `groq` |
| `DATABASE_URL` | `sqlite:///./speakaboo.db` | SQLite for development, Postgres for production |
| `MONTHLY_PLAN_PRICE_BDT` | `200` | Subscription price in BDT |
| `CHARACTER_UNLOCK_PRICE_BDT`| `350` | Individual companion unlock in BDT |
| `FREE_DAILY_MINUTES` | `10` | Daily practice limit on free tier |
| `BASIC_DAILY_MINUTES` | `30` | Daily practice limit on Pro tier |
| `MULTI_CHARACTER_GROUP_CHAT`| `false` | Enable multi-character dialogue engine |

### 3. Run Backend

```bash
# Start FastAPI with hot reload
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```
API Documentation will be available at `http://localhost:8000/docs`.

### 4. Run Flutter Mobile App

```bash
cd app
flutter pub get
flutter run
```

---

## 🧪 Testing & Verification

### Run Backend Tests (pytest)
```bash
# Run full backend test suite
python -m pytest backend/tests/ -v
```

### Run Flutter Analysis & Tests
```bash
cd app
flutter analyze
flutter test
```

### Interactive CLI Chat
Hold a spoken or text conversation directly in the terminal:
```bash
# Text chat with Farmer Reggie:
python -m backend.cli_chat

# Audio file turn test:
python -m backend.cli_chat --audio sample.wav
```

### Run Concurrency Load Test
```bash
python -m backend.scripts.load_test --turns 50 --concurrency 10
```

### Generate Unit Economics & Cost Report
```bash
python -m backend.scripts.cost_report
```

---

## 📱 Hardware Toy Companion (Bluetooth LE)

Speakaboo supports an optional physical companion toy using standard Bluetooth Low Energy:
- **Audio RX (Microphone)**: 16kHz 16-bit mono Opus streaming over BLE L2CAP / GATT.
- **Audio TX (Speaker)**: Companion response playback on the physical device.
- **Push-to-Talk Button & RGB LED**: Hardware event notifications for hands-free child practice.
- Full protocol specification documented in [`ARCHITECTURE.md`](./ARCHITECTURE.md).

---

## 🔒 Privacy & Kid Safety Compliance

- **No Voice Retention**: Voice audio is converted to text in-memory and discarded immediately.
- **COPPA & Digital Security**: No student location, school name, phone number, or photo is ever requested.
- **Data Deletion**: Complete, irreversible user data purge available via `DELETE /api/privacy/user/{user_id}` or from the in-app Parent Dashboard.

---

## 📄 License
Copyright © 2026 Speakaboo. All rights reserved.
