# Spec 10: Payments & Billing (`backend/providers/payment.py`, `backend/routes/payment.py`)

## Purpose
Handles bKash, Nagad, Google Play, Web Checkout, and manual TrxID verification with a SQLite ledger and idempotent entitlement granting.

## Rules & Invariants
1. `POST /api/payment/initiate`: creates payment intent, records `"pending"` row in `payments` table, returns `payment_id` and `checkout_url`.
2. `POST /api/payment/verify`: idempotent — if `payments.status == "completed"`, returns success immediately without duplicating entitlements. Otherwise verifies with gateway, updates `payments`, and grants `Entitlement(type="plan"|"character", ...)`.
3. `POST /api/payment/webhook`: idempotent asynchronous verification.
4. Manual TrxID verification enforces global uniqueness of `transaction_id` so a TrxID cannot be reused across accounts/payments.
5. Note: `MockBkashGateway` and `MockNagadGateway` are sandbox gateways; production real-money processing requires real gateway credentials.
