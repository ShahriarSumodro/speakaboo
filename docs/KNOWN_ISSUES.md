# Speakaboo — Known Issues & Tech Debt

1. **`AUTH_SECRET_KEY` fallback (`backend/engine/auth_token.py:20`):** Falls back to a hardcoded default if `AUTH_SECRET_KEY` env var is unset. Production deployments MUST set `AUTH_SECRET_KEY`.
2. **Large files still >300 lines:** `sqlite_repo.py` (1367 lines), `api_service.dart` (1096 lines), `conversation.py` (859 lines), `profile_screen.dart` (768 lines) are candidates for future modular splitting.
3. **Sandbox payment gateways (`backend/providers/payment.py`):** `MockBkashGateway` / `MockNagadGateway` simulate checkout & verification in sandbox mode; live production payments require real bKash/Nagad merchant API integration.
4. **In-memory conversation & rate-limit state:** `ConversationEngine._conversations` and `main.py:_rate_limits` are in-memory per process; multi-worker deployment requires external store (e.g., Redis).
5. **Hardcoded `Colors.blueAccent` (`app/lib/screens/missions_screen.dart`):** Streak freeze icon uses `Colors.blueAccent` instead of a theme token.
