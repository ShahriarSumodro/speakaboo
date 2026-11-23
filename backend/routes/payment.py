"""
Payment & Monetization API routes.

Handles checkout sessions, bKash & Nagad verification, webhooks,
and entitlement grants (monthly plans, character unlocks).
"""

import time
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from backend.config import load_settings
from backend.repositories import get_repository
from backend.repositories.sqlite_repo import BaseRepository
from backend.models.user import Entitlement
from backend.providers.payment import (
    get_payment_gateway, PaymentPurpose, PaymentStatus,
)

router = APIRouter(prefix="/api/payment", tags=["payment"])


class PlanInfo(BaseModel):
    id: str
    name: str
    price_bdt: int
    daily_minutes: int
    description: str


class PricingResponse(BaseModel):
    monthly_plan: PlanInfo
    character_unlock_price_bdt: int


class CheckoutRequest(BaseModel):
    user_id: str
    gateway: str = "bkash"  # "bkash" or "nagad"
    purpose: str = "monthly_plan"  # "monthly_plan" or "character_unlock"
    target_id: str = ""  # character_id or empty for monthly plan


class CheckoutResponse(BaseModel):
    payment_id: str
    gateway: str
    amount_bdt: int
    checkout_url: str
    status: str


class VerifyRequest(BaseModel):
    payment_id: str
    gateway: str = "bkash"
    verification_token: str = ""


class VerifyResponse(BaseModel):
    payment_id: str
    success: bool
    status: str
    transaction_id: str
    message: str
    entitlement_granted: Optional[str] = None


class EntitlementResponse(BaseModel):
    id: str
    user_id: str
    type: str
    value: str
    expires_at: Optional[float]
    is_active: bool


@router.get("/plans", response_model=PricingResponse)
async def get_plans_and_pricing():
    """Get active subscription plans and per-character unlock prices."""
    settings = load_settings()
    return PricingResponse(
        monthly_plan=PlanInfo(
            id="monthly",
            name="Monthly Pro",
            price_bdt=settings.payment.monthly_plan_price_bdt,
            daily_minutes=settings.usage.basic_daily_minutes,
            description="30 minutes speaking practice every day, all scenarios and topics unlocked.",
        ),
        character_unlock_price_bdt=settings.payment.character_unlock_price_bdt,
    )


@router.post("/checkout", response_model=CheckoutResponse)
async def create_checkout(request: CheckoutRequest):
    """Initiate a payment checkout session with bKash or Nagad."""
    settings = load_settings()
    gateway = get_payment_gateway(request.gateway)

    if request.purpose == "monthly_plan":
        purpose = PaymentPurpose.MONTHLY_PLAN
        amount = settings.payment.monthly_plan_price_bdt
    elif request.purpose == "character_unlock":
        purpose = PaymentPurpose.CHARACTER_UNLOCK
        amount = settings.payment.character_unlock_price_bdt
        if not request.target_id:
            raise HTTPException(status_code=400, detail="target_id (character_id) required for character unlock")
    else:
        raise HTTPException(status_code=400, detail=f"Unknown purpose: {request.purpose}")

    intent = await gateway.create_payment_intent(
        user_id=request.user_id,
        amount_bdt=amount,
        purpose=purpose,
        target_id=request.target_id,
    )

    return CheckoutResponse(
        payment_id=intent.payment_id,
        gateway=intent.gateway,
        amount_bdt=intent.amount_bdt,
        checkout_url=intent.checkout_url,
        status=intent.status.value,
    )


@router.post("/verify", response_model=VerifyResponse)
async def verify_payment(
    request: VerifyRequest, repo: BaseRepository = Depends(get_repository)
):
    """Verify payment and grant entitlement upon success."""
    gateway = get_payment_gateway(request.gateway)
    res = await gateway.verify_payment(request.payment_id, request.verification_token)

    if not res.success:
        return VerifyResponse(
            payment_id=res.payment_id,
            success=False,
            status=res.status.value,
            transaction_id="",
            message=res.message,
        )

    # Grant entitlement
    # Retrieve user from intent or request
    # If monthly plan: expires in 30 days. If character: permanent (expires_at=None).
    user_id = getattr(gateway, "_intents", {}).get(request.payment_id, None)
    uid = user_id.user_id if user_id else "unknown_user"

    expires_at = (time.time() + (30 * 86400)) if res.entitlement_type == "plan" else None
    ent = Entitlement(
        user_id=uid,
        type=res.entitlement_type,
        value=res.entitlement_value,
        expires_at=expires_at,
    )
    await repo.add_entitlement(ent)

    return VerifyResponse(
        payment_id=res.payment_id,
        success=True,
        status=res.status.value,
        transaction_id=res.transaction_id,
        message=res.message,
        entitlement_granted=f"{ent.type}:{ent.value}",
    )


@router.post("/webhook")
async def payment_webhook(
    payload: Dict[str, Any],
    gateway_name: str = "bkash",
    repo: BaseRepository = Depends(get_repository),
):
    """Webhook callback for asynchronous payment notifications."""
    gateway = get_payment_gateway(gateway_name)
    res = await gateway.process_webhook(payload)
    if res.success:
        uid = getattr(gateway, "_intents", {}).get(res.payment_id)
        if uid:
            expires_at = (time.time() + (30 * 86400)) if res.entitlement_type == "plan" else None
            await repo.add_entitlement(
                Entitlement(
                    user_id=uid.user_id,
                    type=res.entitlement_type,
                    value=res.entitlement_value,
                    expires_at=expires_at,
                )
            )
    return {"status": "received", "success": res.success}


@router.get("/entitlements/{user_id}", response_model=List[EntitlementResponse])
async def get_user_entitlements(
    user_id: str, repo: BaseRepository = Depends(get_repository)
):
    """List active user entitlements, filtering out expired subscriptions."""
    all_ents = await repo.get_entitlements(user_id)
    now = time.time()
    active = []

    for e in all_ents:
        is_active = (e.expires_at is None) or (e.expires_at > now)
        active.append(
            EntitlementResponse(
                id=e.id,
                user_id=e.user_id,
                type=e.type,
                value=e.value,
                expires_at=e.expires_at,
                is_active=is_active,
            )
        )

    return active


@router.post("/restore/{user_id}", response_model=List[EntitlementResponse])
async def restore_purchases(
    user_id: str, repo: BaseRepository = Depends(get_repository)
):
    """Restore active purchases for the user."""
    return await get_user_entitlements(user_id, repo)
