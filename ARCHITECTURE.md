# Speakaboo Architecture

## Folder Structure

```
speakaboo/
├── app/                          # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/               # App configuration, themes, constants
│   │   ├── models/               # Data models
│   │   ├── providers/            # State management
│   │   ├── screens/              # UI screens
│   │   ├── widgets/              # Reusable widgets
│   │   └── services/             # API client, audio, storage
│   ├── test/                     # Flutter tests
│   ├── assets/                   # Images, fonts, sounds
│   └── pubspec.yaml
├── backend/                      # Python FastAPI backend
│   ├── __init__.py
│   ├── main.py                   # FastAPI app entry point
│   ├── config.py                 # Settings from .env
│   ├── providers/                # AI provider interfaces and implementations
│   │   ├── __init__.py
│   │   ├── base.py               # Abstract interfaces: SttProvider, LlmProvider, TtsProvider
│   │   ├── groq_stt.py           # Groq Whisper STT
│   │   ├── groq_llm.py           # Groq LLM
│   │   ├── groq_tts.py           # Groq TTS
│   │   └── mock.py               # Mock providers for testing
│   ├── engine/                   # Core conversation and correction engine
│   │   ├── __init__.py
│   │   ├── conversation.py       # Turn management, history, token budget
│   │   ├── correction.py         # Correction extraction and validation
│   │   ├── safety.py             # Content safety layer
│   │   └── level.py              # Learner level adaptation
│   ├── characters/               # Character data files (JSON)
│   │   └── rule_farmer.json      # Placeholder character
│   ├── models/                   # Database models and schemas
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── conversation.py
│   │   └── usage.py
│   ├── repositories/             # Data access layer (SQLite/Postgres swap)
│   │   ├── __init__.py
│   │   └── base.py
│   ├── routes/                   # API endpoints
│   │   ├── __init__.py
│   │   ├── health.py
│   │   ├── conversation.py
│   │   ├── characters.py
│   │   ├── usage.py
│   │   └── auth.py
│   ├── middleware/                # Logging, error handling, rate limiting
│   │   └── __init__.py
│   ├── cache/                    # TTS cache layer
│   │   └── __init__.py
│   ├── cli_chat.py               # CLI tool for testing conversations
│   └── tests/                    # pytest tests
│       ├── __init__.py
│       ├── conftest.py
│       ├── test_providers.py
│       ├── test_conversation.py
│       ├── test_correction.py
│       ├── test_safety.py
│       └── test_e2e.py
├── .env.example
├── .gitignore
├── PROGRESS.md
├── ARCHITECTURE.md
├── DESIGN.md
├── DECISIONS.md
└── README.md
```

## Data Flow: One Conversation Turn

```
User speaks → App captures audio
    → POST /api/conversation/turn (audio file + user_id + conversation_id)
    → STT Provider: audio → transcript
    → Safety Layer: check user message
    → Conversation Engine:
        - Load character persona + history
        - Build prompt with level adaptation
        - LLM Provider: generate reply (strict JSON)
        - Correction Engine: validate/repair JSON
        - Safety Layer: check model reply
    → TTS Provider: reply text → audio chunks (≤200 chars each)
    → TTS Cache: check/store
    → Usage Metering: log minutes
    → Response: {transcript, reply, correction, audio_urls, new_words, usage}
```

## Provider Interfaces

### SttProvider
```python
class SttProvider(ABC):
    async def transcribe(self, audio: bytes, language: str = "en") -> TranscriptResult
```

### LlmProvider
```python
class LlmProvider(ABC):
    async def chat(self, messages: list[Message], config: LlmConfig) -> LlmResult
```

### TtsProvider
```python
class TtsProvider(ABC):
    async def synthesize(self, text: str, voice_id: str) -> bytes
```

### PaymentGateway (Phase 5)
```python
class PaymentGateway(ABC):
    async def initiate_payment(self, amount: int, currency: str, user_id: str) -> PaymentIntent
    async def verify_payment(self, payment_id: str) -> PaymentStatus
```

### DeviceTransport (Phase 6)
```python
class DeviceTransport(ABC):
    async def scan(self, timeout_seconds: float = 3.0) -> List[DeviceInfo]: ...
    async def connect(self, device_id: str) -> bool: ...
    async def disconnect(self) -> None: ...
    async def send_audio_chunk(self, chunk: bytes) -> bool: ...
    async def receive_audio_chunk(self) -> Optional[bytes]: ...
    async def send_command(self, command: str, params: Optional[Dict[str, Any]] = None) -> bool: ...
    async def get_events(self) -> List[DeviceEvent]: ...
```

## Physical Toy Hardware Protocol (Bluetooth Low Energy)

The Speakaboo mobile app communicates with the standalone physical companion toy via Bluetooth Low Energy (BLE 5.0+):

### 1. GATT Services & Characteristics
* **Speakaboo Control Service (`0000SPK0-0000-1000-8000-00805F9B34FB`)**:
  * `0000SPK1`: Control & Feedback (Write/Notify) — RGB LED color states, volume control (0-100), mute.
  * `0000SPK2`: Button & Sensor Events (Notify) — Push-to-Talk button (`PRESSED=0x01`, `RELEASED=0x02`), tap/shake sensor.
  * `0000SPK3`: Battery & Power (Read/Notify) — Battery percentage (0-100), charging status (`CHARGING=0x01`, `FULL=0x02`).
* **Speakaboo Audio Streaming Service (`0000SPKA-0000-1000-8000-00805F9B34FB`) / L2CAP CoC (PSM 0x0080)**:
  * `Audio RX (Mic Stream)` (Notify): 16kHz 16-bit mono Opus-encoded (or raw PCM) audio stream chunked in 20ms frames.
  * `Audio TX (Speaker Stream)` (Write Without Response): 16kHz mono Opus audio stream chunked for toy playback.

### 2. Audio Framing & Bandwidth
* BLE MTU negotiated up to 512 bytes.
* Audio packets framed with a 2-byte header `[sequence_id: uint16]` + payload.
* Standard Opus voice bitrate ~16-24 kbps ensures low latency (<150ms over air) without buffer underruns.

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/api/auth/device` | Register/login with device ID |
| POST | `/api/conversation/turn` | Submit audio turn, get response |
| GET | `/api/conversation/{id}/history` | Get conversation history |
| GET | `/api/characters` | List available characters |
| GET | `/api/characters/{id}` | Get character details |
| GET | `/api/usage/{user_id}` | Get usage stats |
| GET | `/api/usage/{user_id}/daily` | Get daily usage |

## Database Models

### User
- id (UUID), device_id, display_name, plan, created_at, updated_at

### Conversation
- id (UUID), user_id, character_id, started_at, last_turn_at

### Turn
- id (UUID), conversation_id, user_transcript, ai_reply, correction_json, new_words_json, stt_seconds, tts_chars, llm_tokens_in, llm_tokens_out, created_at

### Usage
- id, user_id, date, minutes_spoken, turns_count

### Entitlement
- id, user_id, type (plan/character), value, expires_at

## Feature Flags

| Flag | Default | Description |
|------|---------|-------------|
| `constructive_criticism_mode` | `false` | Planned Phase 8: deeper feedback mode |
| `multi_character_group_chat` | `false` | Phase 6: Multi-character group chat engine |

## Correction Output Schema (v1, extensible)

```json
{
  "version": 1,
  "reply": "string (max 200 chars, 2 sentences)",
  "correction": {
    "original": "what the user said wrong",
    "better": "improved version",
    "reason_short": "brief explanation"
  } | null,
  "new_words": ["word1", "word2"],
  "feedback_level": "gentle",
  "detailed_feedback": null
}
```

The `feedback_level` and `detailed_feedback` fields are reserved for Phase 8 (Constructive Criticism Mode). They are included in the schema now but ignored by current code.
