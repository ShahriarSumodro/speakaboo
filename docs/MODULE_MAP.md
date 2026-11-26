# Speakaboo — Module Map

| Area | Backend Files | Flutter Files |
|------|--------------|---------------|
| Conversation & Turn Pipeline | `backend/engine/conversation.py`, `backend/routes/conversation.py` | `app/lib/providers/conversation_provider.dart`, `app/lib/screens/talk_screen.dart` |
| Grammar Correction | `backend/engine/correction.py` | `app/lib/widgets/correction_chip.dart`, `correction_detail_sheet.dart` |
| Safety & Moderation | `backend/engine/safety.py` | `app/lib/screens/parent_dashboard_screen.dart` |
| AI Providers (STT/LLM/TTS) | `backend/providers/base.py`, `groq_stt.py`, `groq_llm.py`, `groq_tts.py`, `mock.py` | — |
| Characters & Prompts | `backend/engine/characters.py`, `backend/routes/characters.py`, `backend/characters/*.json` | `app/lib/screens/characters_screen.dart`, `character_detail_screen.dart`, `app/lib/models/character.dart` |
| Auth, Profile & PIN | `backend/engine/auth_token.py`, `backend/routes/auth.py` | `app/lib/providers/auth_provider.dart`, `app/lib/services/auth_storage.dart`, `app/lib/screens/profile_screen.dart` |
| Usage Caps & Entitlements | `backend/routes/usage.py`, `backend/routes/conversation.py` | `app/lib/models/usage_info.dart`, `app/lib/widgets/daily_cap_sheet.dart` |
| Gamification, Streaks, Missions | `backend/engine/gamification.py`, `missions.py`, `level.py`, `placement.py` | `app/lib/screens/missions_screen.dart`, `onboarding_screen.dart` |
| Vocabulary & Leitner SRS | `backend/engine/vocabulary.py` | `app/lib/screens/vocabulary_screen.dart`, `app/lib/models/learning_models.dart` |
| Shadowing, Scenarios, Topics | `backend/engine/shadowing.py`, `scenarios.py`, `topics.py`, `backend/routes/learning.py` | `app/lib/screens/shadowing_screen.dart`, `scenarios_screen.dart`, `topics_screen.dart` |
| Payments & Billing | `backend/providers/payment.py`, `backend/routes/payment.py` | `app/lib/services/billing/billing_provider.dart`, `app/lib/widgets/unlock_sheet.dart` |
| Parent Dashboard & Privacy | `backend/routes/parent.py`, `backend/routes/privacy.py` | `app/lib/screens/parent_dashboard_screen.dart`, `app/lib/models/parent_summary.dart` |
| Experiments & Telemetry | `backend/engine/experiments.py`, `backend/engine/telemetry.py` | `app/lib/services/analytics_service.dart` |
| Database | `backend/repositories/sqlite_repo.py`, `backend/models/user.py`, `learning.py` | — |
| Config & Secrets | `backend/config.py`, `.env.example` | `app/lib/config/app_config.dart`, `app/lib/config/theme.dart` |
