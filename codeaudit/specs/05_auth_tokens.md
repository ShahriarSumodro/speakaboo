# Spec 05: Auth & Tokens (`backend/engine/auth_token.py`, `backend/routes/auth.py`)

## Purpose
Device-based authentication using HMAC-SHA256 signed JWT-like bearer tokens and salted SHA-256 parent PIN hashing.

## Rules & Invariants
1. `create_device_token(user_id, device_id, expires_in)` signs `header.payload` with HS256 using `AUTH_SECRET_KEY`.
2. `verify_device_token(token)` verifies 3 parts, checks constant-time signature (`hmac.compare_digest`), decodes JSON payload, and rejects expired tokens (`time.time() > exp`).
3. `hash_pin` / `verify_pin` use salted SHA-256 + `hmac.compare_digest`.
4. `get_current_user_id` extracts `Bearer <token>` from `Authorization` header; raises 401 if missing/invalid unless `TEST_MODE=true` (returns `"test-user"`).
5. `verify_user_access(current_user, target_user)` raises 403 if `current_user != target_user` (unless `TEST_MODE=true` and `current_user == "test-user"`).
