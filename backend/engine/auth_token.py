"""
Speakaboo Authentication & Token Security Engine

Issues and verifies signed HMAC-SHA256 bearer tokens for device-based authentication.
Provides PIN hashing for parent dashboard protection and FastAPI auth dependencies.
"""

import os
import time
import json
import hmac
import hashlib
import base64
from typing import Optional
from fastapi import Header, HTTPException, Depends

AUTH_SECRET_KEY = os.environ.get("AUTH_SECRET_KEY", "speakaboo-secure-device-token-secret-2026")
TOKEN_VALID_SECONDS = 365 * 24 * 3600  # 1 year validity for device auth


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(s: str) -> bytes:
    padding = 4 - (len(s) % 4)
    if padding != 4:
        s += "=" * padding
    return base64.urlsafe_b64decode(s.encode("ascii"))


def create_device_token(user_id: str, device_id: str, expires_in: int = TOKEN_VALID_SECONDS) -> str:
    """Create a cryptographically signed device bearer token."""
    header = {"alg": "HS256", "typ": "JWT"}
    now = int(time.time())
    payload = {
        "sub": user_id,
        "device_id": device_id,
        "iat": now,
        "exp": now + expires_in,
    }

    header_b64 = _b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    payload_b64 = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")

    sig = hmac.new(AUTH_SECRET_KEY.encode("utf-8"), signing_input, hashlib.sha256).digest()
    sig_b64 = _b64url_encode(sig)

    return f"{header_b64}.{payload_b64}.{sig_b64}"


def verify_device_token(token: str) -> dict:
    """Verify signed token signature and expiration.
    
    Returns payload dictionary if valid, raises ValueError otherwise.
    """
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Malformed token format")

    header_b64, payload_b64, sig_b64 = parts
    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
    expected_sig = hmac.new(AUTH_SECRET_KEY.encode("utf-8"), signing_input, hashlib.sha256).digest()

    try:
        actual_sig = _b64url_decode(sig_b64)
    except Exception:
        raise ValueError("Invalid token signature encoding")

    if not hmac.compare_digest(actual_sig, expected_sig):
        raise ValueError("Invalid token signature")

    try:
        payload_bytes = _b64url_decode(payload_b64)
        payload = json.loads(payload_bytes.decode("utf-8"))
    except Exception:
        raise ValueError("Invalid token payload")

    # Check expiration
    exp = payload.get("exp", 0)
    if time.time() > exp:
        raise ValueError("Token has expired")

    return payload


def hash_pin(pin: str) -> str:
    """Hash 4-digit parent PIN using salted SHA-256."""
    salt = AUTH_SECRET_KEY[:16]
    return hashlib.sha256(f"{salt}:{pin}".encode("utf-8")).hexdigest()


def verify_pin(pin: str, pin_hash: str) -> bool:
    """Constant-time comparison for parent PIN verification."""
    if not pin_hash:
        return False
    calculated = hash_pin(pin)
    return hmac.compare_digest(calculated, pin_hash)


async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """FastAPI dependency to extract and verify the authenticated user ID."""
    if not authorization:
        # Check if in test mode without token provided
        if os.environ.get("TEST_MODE", "").lower() in ("true", "1", "yes"):
            return "test-user"
        raise HTTPException(status_code=401, detail="Authentication token required")

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Invalid Authorization header scheme. Expected Bearer <token>")

    try:
        payload = verify_device_token(token.strip())
        return payload["sub"]
    except ValueError as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {e}")


def verify_user_access(current_user: str, target_user: str) -> None:
    """Verify that current authenticated user is authorized to access target user's data."""
    # In test mode with test-user, allow access to target
    if current_user == "test-user" and os.environ.get("TEST_MODE", "").lower() in ("true", "1", "yes"):
        return
    if current_user != target_user:
        raise HTTPException(
            status_code=403,
            detail="Forbidden: You cannot access or modify another user's data",
        )
