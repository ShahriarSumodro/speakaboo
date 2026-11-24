# Speakaboo Council Inventory

Comprehensive catalog of every screen, backend route, module, teaching method, growth mechanism, and setting in Speakaboo.

---

## 1. Flutter Screens
| Screen | File Path | Status | Purpose / Wired Components |
|---|---|---|---|
| `TalkScreen` | `app/lib/screens/talk_screen.dart` | Real | Real-time speaking session with AI companion; SSE audio streaming, hint drawer, feedback chips, session summary. |
| `CharactersScreen` | `app/lib/screens/characters_screen.dart` | Real | Catalog of 3 original characters (Farmer Reggie, Detective Kabir, Prof. Anika), level tags, offline cache. |
| `CharacterDetailScreen` | `app/lib/screens/character_detail_screen.dart` | Real | Character profile, backstory, voice preview player (Orpheus TTS), 2-min trial banner, unlock sheet. |
| `MissionsScreen` | `app/lib/screens/missions_screen.dart` | Real | Streak counter, streak freeze/repair, daily missions, Word of the Day with Bengali translations. |
| `ProfileScreen` | `app/lib/screens/profile_screen.dart` | Real | User stats (XP, streak, words spoken), CEFR badge, edit name dialog, WhatsApp share card, referral code tile. |
| `OnboardingScreen` | `app/lib/screens/onboarding_screen.dart` | Real | First-launch setup: age band, learning goal, self-assessed level, optional spoken placement diagnostic. |
| `ScenariosScreen` | `app/lib/screens/scenarios_screen.dart` | Real | Real-world roleplay scenarios (job interview, Dhaka street food, airport immigration, tech startup pitch). |
| `TopicsScreen` | `app/lib/screens/topics_screen.dart` | Real | Curated conversation topics (Cricket & Tigers, Dhaka traffic, AI future, university life). |
| `ShadowingScreen` | `app/lib/screens/shadowing_screen.dart` | Real | Rhythm and fluency practice; speed controls (0.8x, 1.0x, 1.2x), audio playback and recording evaluation. |
| `VocabularyScreen` | `app/lib/screens/vocabulary_screen.dart` | Real | Leitner 5-box spaced repetition deck; flashcards, recall practice, due words filter. |
| `ParentDashboardScreen` | `app/lib/screens/parent_dashboard_screen.dart` | Real | Protected behind PBKDF2 4-digit PIN; weekly speaking minutes chart, safety moderation flags log. |
| `SettingsScreen` | `app/lib/screens/settings_screen.dart` | Real | Daily reminder time picker, theme selector (system/light/dark), bilingual privacy policy, account deletion. |
| `DevicePairingScreen` | `app/lib/screens/device_pairing_screen.dart` | Real (Stub) | Bluetooth LE toy companion discovery and pairing stub. |

---

## 2. Flutter Reusable Widgets & Components
| Widget | File Path | Status | Purpose |
|---|---|---|---|
| `CharacterFace` | `app/lib/widgets/character_face.dart` | Real | Procedural animated avatar; listening/thinking/speaking/celebrating states, character hats & glasses. |
| `CorrectionChip` | `app/lib/widgets/correction_chip.dart` | Real | Inline recast/correction pill with one-tap inspection. |
| `CorrectionDetailSheet` | `app/lib/widgets/correction_detail_sheet.dart` | Real | Bottom sheet explaining the mistake, category, and better alternative. |
| `HintSheet` | `app/lib/widgets/hint_sheet.dart` | Real | "Help me say it" drawer with sentence starter, model response, and key vocabulary. |
| `SessionSummarySheet` | `app/lib/widgets/session_summary_sheet.dart` | Real | Post-session recap: talk-time ratio, WPM, approximate clarity score, tomorrow hook, 3-retell prompt. |
| `UnlockSheet` | `app/lib/widgets/unlock_sheet.dart` | Real | Dual-flavor monetization sheet (Google Play for `play` flavor; bKash/Nagad for `direct` flavor; restore button). |
| `DailyCapSheet` | `app/lib/widgets/daily_cap_sheet.dart` | Real | Friendly practice completed celebration with Pro upgrade options for both flavors. |
| `EmptyStateWidget` | `app/lib/widgets/empty_state.dart` | Real | Standard empty state for vocabulary, missions, and history. |
| `ShareProgressCard` | `app/lib/widgets/share_progress_card.dart` | Real | Branded shareable card with streak, level, minutes for WhatsApp and Facebook. |

---

## 3. Backend Routes
| Endpoint | Method | File Path | Status | Purpose |
|---|---|---|---|---|
| `/api/health` | GET | `backend/routes/health.py` | Real | Health status, uptime, database metrics, provider diagnostics. |
| `/api/auth/device` | POST | `backend/routes/auth.py` | Real | Device-based anonymous registration, JWT HMAC issuance. |
| `/api/auth/profile` | GET, PUT | `backend/routes/auth.py` | Real | User profile read and update (age band, goals, reminder time). |
| `/api/auth/set-parent-pin` | POST | `backend/routes/auth.py` | Real | PBKDF2 salt and hash generation for 4-digit Parent PIN. |
| `/api/auth/verify-parent-pin` | POST | `backend/routes/auth.py` | Real | Secure constant-time verification of Parent PIN. |
| `/api/characters/` | GET | `backend/routes/characters.py` | Real | External character catalog JSONs with personality traits and sample lines. |
| `/api/characters/{id}/preview-audio` | GET | `backend/routes/characters.py` | Real | Voice preview synthesized with Orpheus TTS, cached on disk. |
| `/api/conversation/start` | POST | `backend/routes/conversation.py` | Real | Initializes conversation with character memory recall greeting. |
| `/api/conversation/turn` | POST | `backend/routes/conversation.py` | Real | Full STT -> LLM -> TTS pipeline with error categorization. |
| `/api/conversation/stream-turn` | POST | `backend/routes/conversation.py` | Real | SSE streaming: early transcript + incremental TTS audio chunks. |
| `/api/conversation/hint` | POST | `backend/routes/conversation.py` | Real | Contextual sentence starters and model responses. |
| `/api/conversation/summary` | POST | `backend/routes/conversation.py` | Real | Talk-time ratio, WPM, approximate clarity score, tomorrow hook. |
| `/api/conversation/placement` | POST | `backend/routes/conversation.py` | Real | Spoken diagnostic test evaluating CEFR level and WPM. |
| `/api/conversation/mistakes/{id}` | GET | `backend/routes/conversation.py` | Real | Retrieves logged learner mistakes by category. |
| `/api/usage/status/{id}` | GET | `backend/routes/usage.py` | Real | Daily minutes spoken and cap status. |
| `/api/learning/missions/{id}` | GET | `backend/routes/learning.py` | Real | Daily missions progress and completion status. |
| `/api/learning/missions/claim` | POST | `backend/routes/learning.py` | Real | Claims XP rewards for completed missions. |
| `/api/learning/streak/repair` | POST | `backend/routes/learning.py` | Real | Zero-guilt streak freeze consumption and streak recovery. |
| `/api/learning/word-of-the-day` | GET | `backend/routes/learning.py` | Real | Daily educational vocabulary with Bengali translation and pronunciation. |
| `/api/learning/vocabulary/{id}` | GET | `backend/routes/learning.py` | Real | Retrieves Leitner box cards for user. |
| `/api/learning/vocabulary/review` | POST | `backend/routes/learning.py` | Real | Updates Leitner box (box 1-5) based on recall success. |
| `/api/learning/scenarios` | GET | `backend/routes/learning.py` | Real | Curriculum scenarios catalog. |
| `/api/learning/topics` | GET | `backend/routes/learning.py` | Real | Curated conversation topics catalog. |
| `/api/learning/shadowing` | GET | `backend/routes/learning.py` | Real | Shadowing passages and pace targets. |
| `/api/learning/referral/{id}` | GET | `backend/routes/learning.py` | Real | Generates or fetches unique referral code and referral stats. |
| `/api/learning/referral/claim` | POST | `backend/routes/learning.py` | Real | Processes referral claim awarding XP and streak freezes. |
| `/api/parent/summary/{id}` | GET | `backend/routes/parent.py` | Real | Aggregates weekly speaking minutes, active days, safety flags. |
| `/api/parent/safety-flags/{id}` | GET | `backend/routes/parent.py` | Real | Logs harmful intercepts and redirects. |
| `/api/payment/plans` | GET | `backend/routes/payment.py` | Real | Active subscription plans (200 BDT/mo) and character unlock prices (350 BDT). |
| `/api/payment/checkout` | POST | `backend/routes/payment.py` | Real | Initiates payment intent for Google Play, bKash, Nagad, or Web. |
| `/api/payment/verify` | POST | `backend/routes/payment.py` | Real | Verifies transaction and activates entitlement idempotently. |
| `/api/payment/webhook` | POST | `backend/routes/payment.py` | Real | Provider webhook notification callback. |
| `/api/payment/entitlements/{id}`| GET | `backend/routes/payment.py` | Real | Retrieves active entitlements (plans, character unlocks). |
| `/api/payment/restore/{id}` | POST | `backend/routes/payment.py` | Real | Restores purchases across flavors. |
| `/api/payment/refund` | POST | `backend/routes/payment.py` | Real | Marks payment refunded and revokes active entitlement. |
| `/api/privacy/export/{id}` | GET | `backend/routes/privacy.py` | Real | Full learning profile export with zero-raw-audio guarantee. |
| `/api/privacy/delete/{id}` | DELETE | `backend/routes/privacy.py` | Real | Cascade deletion of user data across all 13 SQLite tables. |

---

## 4. Backend Engines & Services
| Module | File Path | Status | Purpose |
|---|---|---|---|
| `ConversationEngine` | `backend/engine/conversation.py` | Real | Turn pipeline orchestration, STT, prompt formulation, TTS caching. |
| `CharacterManager` | `backend/engine/characters.py` | Real | External character loaders, personality prompts, feedback styles. |
| `CorrectionEngine` | `backend/engine/correction.py` | Real | Error categorization and structured JSON reply parsing. |
| `PlacementEngine` | `backend/engine/placement.py` | Real | Spoken diagnostic evaluation for CEFR level and speaking pace. |
| `ExperimentsService` | `backend/engine/experiments.py` | Real | Deterministic SHA-256 hash bucketing across 6 active experiments (EXP001-EXP006). |
| `SafetyEngine` | `backend/engine/safety.py` | Real | Multi-category content moderation, character-voiced redirects, kid profanity sanitization. |
| `SqliteRepository` | `backend/repositories/sqlite_repo.py` | Real | Complete persistent repository with 13 relational tables and migrations. |

---

## 5. Teaching & Pedagogical Methods
| Method | Implementation | Status | Evidence / Config |
|---|---|---|---|
| Single Focus Error | Max 1 error corrected per turn | Active | `backend/engine/characters.py` prompt instructions |
| Recast in Bot Reply | Bot models correct usage naturally | Active | `backend/engine/characters.py` prompt instructions |
| Prompts-First vs Recast | A/B tested (`EXP001`) | Active | `backend/engine/experiments.py` |
| "Again, Faster" Retell | 3-retell drill prompt in summary | Active | `backend/routes/conversation.py` summary endpoint |
| Pre-Task Planning | Guided prompts before scenarios | Active | `EXP003` variant |
| Spaced Retrieval | Expanding Leitner 5-box schedule | Active | `backend/repositories/sqlite_repo.py` |
| Shadowing | 0.8x, 1.0x, 1.2x pacing evaluation | Active | `app/lib/screens/shadowing_screen.dart` |
| Spoken Diagnostic | CEFR placement with WPM & clarity | Active | `backend/engine/placement.py` |
| Bengali Error Categories| Articles, tenses, prepositions, S-V agreement | Active | `backend/engine/correction.py` |

---

## 6. Retention & Growth Mechanisms
| Mechanism | Implementation | Status | Evidence |
|---|---|---|---|
| Fast First Win | Spoken greeting within 60s of launch | Active | `TalkScreen` on-launch start call |
| Daily Habit Loop | Local notification -> 2-min talk -> XP -> Vocab | Active | `app/lib/services/notification_service.dart` |
| Streak Forgiveness | Streak freeze and 1-tap repair | Active | `backend/routes/learning.py` streak repair |
| Character Relationship | Memory of learner name, goal, last topic | Active | SQLite `character_memories` table |
| Tomorrow Hook | Character cliffhanger in session summary | Active | `backend/routes/conversation.py` summary endpoint |
| Social Progress Card | WhatsApp / Facebook branded card | Active | `app/lib/widgets/share_progress_card.dart` |
| Viral Referral | 100 XP + streak freeze for referrer, 50 XP for referee | Active | SQLite `referrals` table |
| Parent Summary | Weekly speaking minutes, active days, safety flags | Active | `app/lib/screens/parent_dashboard_screen.dart` |
