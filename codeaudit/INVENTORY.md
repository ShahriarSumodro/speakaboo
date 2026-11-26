# Code Truth Loop — Codebase Inventory

Generated from code reading in Phase 0/1.

## Backend (`backend/`)

### Core Files
| File | Lines | Purpose |
|------|-------|---------|
| `__init__.py` | ~1 | Package marker |
| `main.py` | 154 | FastAPI app entry: lifespan, CORS, rate limiting, exception handler, router registration |
| `config.py` | 258 | Settings loader: env→dataclass, .env parsing, provider validation |
| `cli_chat.py` | ~170 | CLI chat tool for testing conversation locally |

### Engine (`backend/engine/`)
| File | Lines | Purpose |
|------|-------|---------|
| `__init__.py` | ~1 | Package marker |
| `conversation.py` | 859 | Turn pipeline: STT→safety→level→LLM→correction→safety→TTS; both sync and streaming |
| `correction.py` | 247 | Parse LLM JSON, extract correction, categorize errors, TurnResponse dataclass |
| `safety.py` | 147 | Blocklist patterns, kid-mode, character-voiced redirects, `check_content_safety()` |
| `characters.py` | 185 | Character loading from JSON, `build_system_prompt()` with pedagogical rules |
| `level.py` | 119 | Heuristic CEFR level estimation from user transcripts |
| `placement.py` | 160 | Formal placement test: spoken sample → A1/A2/B1/B2 score and recommendations |
| `gamification.py` | 62 | XP awards for turns/shadowing/scenarios, streak freeze |
| `missions.py` | 87 | Daily missions: speak time, new words, complete scene, shadowing |
| `vocabulary.py` | 99 | Vocabulary notebook with Leitner spaced repetition |
| `shadowing.py` | 145 | Shadowing: compare transcript to target, F1 accuracy, pace scoring |
| `topics.py` | ~32 | Load topics from JSON |
| `scenarios.py` | ~52 | Load scenarios from JSON |
| `experiments.py` | 269 | A/B experiments: 6 experiments, deterministic bucketing, event logging |
| `telemetry.py` | ~90 | Crash recording, server metrics |
| `auth_token.py` | 139 | HMAC-SHA256 JWT tokens, PIN hashing, FastAPI auth dependency |
| `device_transport.py` | ~200 | Device/group chat transport layer |
| `group_chat.py` | ~180 | Multi-character group conversation |

### Providers (`backend/providers/`)
| File | Lines | Purpose |
|------|-------|---------|
| `base.py` | 166 | ABC interfaces: SttProvider, LlmProvider, TtsProvider + error types |
| `groq_stt.py` | ~110 | Groq Whisper STT implementation |
| `groq_llm.py` | ~160 | Groq LLM with model fallback chain |
| `groq_tts.py` | ~130 | Groq Orpheus TTS implementation |
| `mock.py` | ~130 | Mock providers for unit tests only |
| `payment.py` | 421 | Payment gateway interface + MockBkash, MockNagad, GooglePlay, WebBilling |

### Models (`backend/models/`)
| File | Lines | Purpose |
|------|-------|---------|
| `user.py` | 102 | User, UserProfile, Conversation, Turn, DailyUsage, Entitlement, MistakeLog |
| `learning.py` | 106 | UserProgress, Mission, VocabularyItem, Scenario, ShadowingScript, SafetyFlag |

### Repositories (`backend/repositories/`)
| File | Lines | Purpose |
|------|-------|---------|
| `__init__.py` | 23 | Singleton getter/setter for repository |
| `sqlite_repo.py` | 1367 | Full SQLite implementation: 15 tables, CRUD for all features, Leitner box logic |

### Routes (`backend/routes/`)
| File | Lines | Purpose |
|------|-------|---------|
| `auth.py` | 239 | Device auth, profile CRUD, parent PIN |
| `characters.py` | ~110 | List/get characters, preview audio |
| `conversation.py` | ~600 | Start, turn (sync+SSE), hint, summary, end |
| `learning.py` | ~520 | Shadowing, scenarios, topics, gamification, missions, vocabulary, referrals |
| `payment.py` | ~370 | Payment intents, verification, webhooks, manual TrxID |
| `health.py` | ~55 | Health check endpoint |
| `parent.py` | ~60 | Parent dashboard summary |
| `privacy.py` | ~160 | Data export, delete account |
| `usage.py` | ~50 | Daily usage caps |
| `debug.py` | ~30 | Debug last turns endpoint |

### Data Files
| File | Purpose |
|------|---------|
| `characters/rule_farmer.json` | Reggie Rule Farmer character |
| `characters/professor_anika.json` | Professor Anika character |
| `characters/dhaka_detective.json` | Kabir Chowdhury character |
| `data/shadowing_scripts.json` | 3 shadowing practice scripts |
| `data/scenarios.json` | Real-life speaking scenarios |
| `data/topics.json` | Conversation topic packs |

### Scripts (`backend/scripts/`)
| File | Purpose |
|------|---------|
| `e2e_turns.py` | End-to-end multi-turn test |
| `verify_providers.py` | Verify real providers |
| `load_test.py` | Load/stress testing |
| `backup_db.py` | Database backup |
| `cost_report.py` | Cost analysis |
| `retention_report.py` | Retention metrics |
| `revenue_report.py` | Revenue analysis |
| `experiments_report.py` | A/B experiment results |

### Tests (`backend/tests/`)
27 test files covering: health, config, characters, conversation, correction, safety, providers, repository, gamification, level, missions, vocabulary, payment, hardening, learning modes, debug, device/group chat, e2e, parent dashboard, plus 7 "phase" test files for specific feature phases.

---

## Flutter App (`app/lib/`)

### Core
| File | Bytes | Purpose |
|------|-------|---------|
| `main.dart` | 5538 | App entry, theme, provider registration, MaterialApp |

### Config
| File | Bytes | Purpose |
|------|-------|---------|
| `config/app_config.dart` | 3005 | Backend URL, timeouts, feature flags |
| `config/theme.dart` | 10817 | 60-30-10 warm palette, WCAG AA, light+dark, `SpeakabooColors` extension |

### Models
| File | Bytes | Purpose |
|------|-------|---------|
| `models/character.dart` | 2022 | Character model |
| `models/learning_models.dart` | 13505 | LearningProgress, VocabCard, MissionData, etc. |
| `models/parent_summary.dart` | 1911 | Parent dashboard summary |
| `models/payment_models.dart` | 1346 | Payment intent/status |
| `models/usage_info.dart` | 819 | Usage/caps info |
| `models/user_profile.dart` | 2521 | UserProfile model |

### Providers
| File | Bytes | Purpose |
|------|-------|---------|
| `providers/auth_provider.dart` | 5369 | Auth state, health check, profile, PIN, delete account |
| `providers/conversation_provider.dart` | 13603 | Conversation state machine, streaming+blocking turns |

### Services
| File | Bytes | Purpose |
|------|-------|---------|
| `services/api_service.dart` | 35192 | Complete HTTP API client (all endpoints), SSE parsing, auth retry |
| `services/audio_service.dart` | 3671 | Audio recording/playback with just_audio |
| `services/auth_storage.dart` | 2496 | SharedPreferences-based device ID/token storage |
| `services/billing/billing_provider.dart` | 3624 | In-app purchase abstraction |
| `services/cache_service.dart` | 1585 | SharedPreferences JSON cache |
| `services/analytics_service.dart` | 1729 | Analytics event tracking |
| `services/notification_service.dart` | 2906 | Local notifications |

### Screens (14 screens)
| File | Bytes | Purpose |
|------|-------|---------|
| `screens/talk_screen.dart` | 16436 | Main conversation UI |
| `screens/characters_screen.dart` | 7355 | Character picker grid |
| `screens/character_detail_screen.dart` | 13733 | Character detail + preview + start |
| `screens/missions_screen.dart` | 19723 | Daily missions + word of day |
| `screens/vocabulary_screen.dart` | 14769 | Vocabulary notebook + review cards |
| `screens/shadowing_screen.dart` | 14513 | Shadowing practice mode |
| `screens/scenarios_screen.dart` | 12896 | Real-life scenario roleplay |
| `screens/topics_screen.dart` | 5174 | Topic picker |
| `screens/profile_screen.dart` | 28958 | Full profile + stats + settings |
| `screens/settings_screen.dart` | 10063 | Server config, diagnostics |
| `screens/parent_dashboard_screen.dart` | 15960 | Parent gate + weekly summary |
| `screens/onboarding_screen.dart` | 15118 | 3-step onboarding |
| `screens/device_pairing_screen.dart` | 9403 | Device pairing setup |
| `screens/main_shell.dart` | 1805 | Bottom nav shell |

### Widgets (10 widgets)
| File | Bytes | Purpose |
|------|-------|---------|
| `widgets/character_face.dart` | 12876 | Animated character avatar |
| `widgets/character_sheet.dart` | 4662 | Character bottom sheet |
| `widgets/correction_chip.dart` | 2995 | Correction display chip |
| `widgets/correction_detail_sheet.dart` | 4139 | Correction detail bottom sheet |
| `widgets/daily_cap_sheet.dart` | 8465 | Daily usage cap sheet |
| `widgets/dev_server_dialog.dart` | 7449 | Dev server config dialog |
| `widgets/empty_state.dart` | 2551 | Empty state placeholder |
| `widgets/hint_sheet.dart` | 5324 | Sentence hint bottom sheet |
| `widgets/session_summary_sheet.dart` | 14357 | End-of-session coaching metrics |
| `widgets/share_progress_card.dart` | 6603 | Share progress image card |
| `widgets/unlock_sheet.dart` | 10335 | Character unlock purchase sheet |

### Tests (`app/test/`)
| File | Bytes | Purpose |
|------|-------|---------|
| `auth_retry_test.dart` | 9427 | Auth token retry on 401 |
| `billing_test.dart` | 3890 | Billing provider unit tests |
| `data_layer_test.dart` | 7945 | Model deserialization tests |
| `server_banner_test.dart` | 2332 | Server connection banner tests |
| `widget_test.dart` | 44818 | Full widget tests for all screens |

---

## Big File Targets (>300 lines)
1. `backend/repositories/sqlite_repo.py` — 1367 lines
2. `backend/engine/conversation.py` — 859 lines
3. `app/lib/services/api_service.dart` — 1096 lines
4. `app/test/widget_test.dart` — ~1275 lines
5. `backend/routes/conversation.py` — ~600 lines
6. `backend/routes/learning.py` — ~520 lines
7. `backend/providers/payment.py` — 421 lines

## Functions >40 Lines
- `SqliteRepository.initialize()` — creates all 15 tables (~230 lines of SQL)
- `ConversationEngine.process_turn()` — ~230 lines
- `ConversationEngine.stream_turn()` — ~230 lines
- `ConversationEngine.get_session_summary()` — ~80 lines
- `build_system_prompt()` — ~90 lines

## Smells Found
- See `FINDINGS.md` for all findings (F-001 through F-015)
