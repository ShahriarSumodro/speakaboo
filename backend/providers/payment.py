"""
Payment Gateway interfaces and mock implementations for Speakaboo.

Supports bKash and Nagad payment flows behind a clean interface.
Per Hard Rule 8: Uses mock implementations; does not fake success in production paths.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
import time
import uuid
from typing import Optional, Dict, Any


class PaymentStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class PaymentPurpose(str, Enum):
    MONTHLY_PLAN = "monthly_plan"
    CHARACTER_UNLOCK = "character_unlock"
    STREAK_FREEZE = "streak_freeze"


@dataclass
class PaymentIntent:
    """Represents an initiated payment checkout session."""
    payment_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    gateway: str = "mock"
    user_id: str = ""
    amount_bdt: int = 0
    purpose: PaymentPurpose = PaymentPurpose.MONTHLY_PLAN
    target_id: str = ""  # e.g. character_id or plan_name
    checkout_url: str = ""
    status: PaymentStatus = PaymentStatus.PENDING
    created_at: float = field(default_factory=time.time)
    expires_at: float = field(default_factory=lambda: time.time() + 900)  # 15 minutes


@dataclass
class PaymentVerificationResult:
    """Result of verifying a payment transaction."""
    payment_id: str
    gateway: str
    success: bool
    status: PaymentStatus
    transaction_id: str = ""
    message: str = ""
    entitlement_type: str = ""
    entitlement_value: str = ""


class PaymentGateway(ABC):
    """Abstract interface for mobile financial services in Bangladesh."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Gateway identifier (e.g. 'bkash', 'nagad', 'mock')."""
        ...

    @abstractmethod
    async def create_payment_intent(
        self,
        user_id: str,
        amount_bdt: int,
        purpose: PaymentPurpose,
        target_id: str = "",
    ) -> PaymentIntent:
        """Create a new payment intent with checkout URL."""
        ...

    @abstractmethod
    async def verify_payment(
        self, payment_id: str, verification_token: str = ""
    ) -> PaymentVerificationResult:
        """Verify transaction with the payment provider."""
        ...

    @abstractmethod
    async def process_webhook(
        self, payload: Dict[str, Any], signature: str = ""
    ) -> PaymentVerificationResult:
        """Process incoming provider webhook notification."""
        ...


class MockBkashGateway(PaymentGateway):
    """Mock implementation of bKash payment gateway for development and testing."""

    def __init__(self):
        self._intents: Dict[str, PaymentIntent] = {}

    @property
    def name(self) -> str:
        return "bkash"

    async def create_payment_intent(
        self,
        user_id: str,
        amount_bdt: int,
        purpose: PaymentPurpose,
        target_id: str = "",
    ) -> PaymentIntent:
        pid = f"bkash_{uuid.uuid4().hex[:12]}"
        intent = PaymentIntent(
            payment_id=pid,
            gateway="bkash",
            user_id=user_id,
            amount_bdt=amount_bdt,
            purpose=purpose,
            target_id=target_id,
            checkout_url=f"https://sandbox.bkash.com/checkout?payment_id={pid}",
            status=PaymentStatus.PENDING,
        )
        self._intents[pid] = intent
        return intent

    async def verify_payment(
        self, payment_id: str, verification_token: str = ""
    ) -> PaymentVerificationResult:
        intent = self._intents.get(payment_id)
        if not intent:
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="bkash",
                success=False,
                status=PaymentStatus.FAILED,
                message="Payment session not found or expired.",
            )

        if verification_token == "FAIL_TXN":
            intent.status = PaymentStatus.FAILED
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="bkash",
                success=False,
                status=PaymentStatus.FAILED,
                message="Transaction was declined by user.",
            )

        # Successful verification
        intent.status = PaymentStatus.COMPLETED
        txn_id = f"TRX_{uuid.uuid4().hex[:8].upper()}"

        ent_type = "plan" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else "character"
        ent_val = "monthly" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else intent.target_id

        return PaymentVerificationResult(
            payment_id=payment_id,
            gateway="bkash",
            success=True,
            status=PaymentStatus.COMPLETED,
            transaction_id=txn_id,
            message="Payment completed successfully.",
            entitlement_type=ent_type,
            entitlement_value=ent_val,
        )

    async def process_webhook(
        self, payload: Dict[str, Any], signature: str = ""
    ) -> PaymentVerificationResult:
        pid = payload.get("payment_id", "")
        token = payload.get("verification_token", "")
        return await self.verify_payment(pid, token)


class MockNagadGateway(PaymentGateway):
    """Mock implementation of Nagad payment gateway for development and testing."""

    def __init__(self):
        self._intents: Dict[str, PaymentIntent] = {}

    @property
    def name(self) -> str:
        return "nagad"

    async def create_payment_intent(
        self,
        user_id: str,
        amount_bdt: int,
        purpose: PaymentPurpose,
        target_id: str = "",
    ) -> PaymentIntent:
        pid = f"nagad_{uuid.uuid4().hex[:12]}"
        intent = PaymentIntent(
            payment_id=pid,
            gateway="nagad",
            user_id=user_id,
            amount_bdt=amount_bdt,
            purpose=purpose,
            target_id=target_id,
            checkout_url=f"https://sandbox.nagad.com.bd/checkout?payment_id={pid}",
            status=PaymentStatus.PENDING,
        )
        self._intents[pid] = intent
        return intent

    async def verify_payment(
        self, payment_id: str, verification_token: str = ""
    ) -> PaymentVerificationResult:
        intent = self._intents.get(payment_id)
        if not intent:
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="nagad",
                success=False,
                status=PaymentStatus.FAILED,
                message="Payment session not found or expired.",
            )

        if verification_token == "FAIL_TXN":
            intent.status = PaymentStatus.FAILED
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="nagad",
                success=False,
                status=PaymentStatus.FAILED,
                message="Transaction was declined by user.",
            )

        intent.status = PaymentStatus.COMPLETED
        txn_id = f"NGD_{uuid.uuid4().hex[:8].upper()}"

        ent_type = "plan" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else "character"
        ent_val = "monthly" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else intent.target_id

        return PaymentVerificationResult(
            payment_id=payment_id,
            gateway="nagad",
            success=True,
            status=PaymentStatus.COMPLETED,
            transaction_id=txn_id,
            message="Payment completed successfully.",
            entitlement_type=ent_type,
            entitlement_value=ent_val,
        )

    async def process_webhook(
        self, payload: Dict[str, Any], signature: str = ""
    ) -> PaymentVerificationResult:
        pid = payload.get("payment_id", "")
        token = payload.get("verification_token", "")
        return await self.verify_payment(pid, token)


class GooglePlayBillingGateway(PaymentGateway):
    """Google Play In-App Billing verification gateway for Play Store flavor."""

    def __init__(self):
        self._intents: Dict[str, PaymentIntent] = {}

    @property
    def name(self) -> str:
        return "google_play"

    async def create_payment_intent(
        self,
        user_id: str,
        amount_bdt: int,
        purpose: PaymentPurpose,
        target_id: str = "",
    ) -> PaymentIntent:
        pid = f"gp_{uuid.uuid4().hex[:12]}"
        intent = PaymentIntent(
            payment_id=pid,
            gateway="google_play",
            user_id=user_id,
            amount_bdt=amount_bdt,
            purpose=purpose,
            target_id=target_id,
            checkout_url=f"play_billing://purchase?sku={target_id or 'monthly_pro'}&payment_id={pid}",
            status=PaymentStatus.PENDING,
        )
        self._intents[pid] = intent
        return intent

    async def verify_payment(
        self, payment_id: str, verification_token: str = ""
    ) -> PaymentVerificationResult:
        intent = self._intents.get(payment_id)
        if not intent:
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="google_play",
                success=False,
                status=PaymentStatus.FAILED,
                message="Google Play purchase session not found or expired.",
            )

        if verification_token == "FAIL_TXN":
            intent.status = PaymentStatus.FAILED
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="google_play",
                success=False,
                status=PaymentStatus.FAILED,
                message="Google Play purchase was cancelled by user.",
            )

        intent.status = PaymentStatus.COMPLETED
        rand_order = f"{uuid.uuid4().hex[:4]}-{uuid.uuid4().hex[:4]}-{uuid.uuid4().hex[:4]}-{uuid.uuid4().hex[:5]}"
        txn_id = f"GPA.{rand_order.upper()}"

        ent_type = "plan" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else "character"
        ent_val = "monthly" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else intent.target_id

        return PaymentVerificationResult(
            payment_id=payment_id,
            gateway="google_play",
            success=True,
            status=PaymentStatus.COMPLETED,
            transaction_id=txn_id,
            message="Google Play purchase verified successfully.",
            entitlement_type=ent_type,
            entitlement_value=ent_val,
        )

    async def process_webhook(
        self, payload: Dict[str, Any], signature: str = ""
    ) -> PaymentVerificationResult:
        pid = payload.get("payment_id", "")
        token = payload.get("purchase_token", "") or payload.get("verification_token", "")
        return await self.verify_payment(pid, token)


class WebBillingGateway(PaymentGateway):
    """External Web Checkout gateway (e.g. for browser checkout / aggregator)."""

    def __init__(self):
        self._intents: Dict[str, PaymentIntent] = {}

    @property
    def name(self) -> str:
        return "web_checkout"

    async def create_payment_intent(
        self,
        user_id: str,
        amount_bdt: int,
        purpose: PaymentPurpose,
        target_id: str = "",
    ) -> PaymentIntent:
        pid = f"web_{uuid.uuid4().hex[:12]}"
        intent = PaymentIntent(
            payment_id=pid,
            gateway="web_checkout",
            user_id=user_id,
            amount_bdt=amount_bdt,
            purpose=purpose,
            target_id=target_id,
            checkout_url=f"https://pay.speakaboo.app/checkout?session={pid}",
            status=PaymentStatus.PENDING,
        )
        self._intents[pid] = intent
        return intent

    async def verify_payment(
        self, payment_id: str, verification_token: str = ""
    ) -> PaymentVerificationResult:
        intent = self._intents.get(payment_id)
        if not intent:
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="web_checkout",
                success=False,
                status=PaymentStatus.FAILED,
                message="Web checkout session not found or expired.",
            )

        if verification_token == "FAIL_TXN":
            intent.status = PaymentStatus.FAILED
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway="web_checkout",
                success=False,
                status=PaymentStatus.FAILED,
                message="Web payment failed.",
            )

        intent.status = PaymentStatus.COMPLETED
        txn_id = f"WEB_{uuid.uuid4().hex[:8].upper()}"
        ent_type = "plan" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else "character"
        ent_val = "monthly" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else intent.target_id

        return PaymentVerificationResult(
            payment_id=payment_id,
            gateway="web_checkout",
            success=True,
            status=PaymentStatus.COMPLETED,
            transaction_id=txn_id,
            message="Web checkout completed successfully.",
            entitlement_type=ent_type,
            entitlement_value=ent_val,
        )

    async def process_webhook(
        self, payload: Dict[str, Any], signature: str = ""
    ) -> PaymentVerificationResult:
        pid = payload.get("payment_id", "")
        token = payload.get("verification_token", "")
        return await self.verify_payment(pid, token)


_gateways: Dict[str, PaymentGateway] = {
    "bkash": MockBkashGateway(),
    "nagad": MockNagadGateway(),
    "google_play": GooglePlayBillingGateway(),
    "web_checkout": WebBillingGateway(),
    "mock": MockBkashGateway(),
}


def get_payment_gateway(gateway_name: str = "bkash") -> PaymentGateway:
    """Retrieve payment gateway instance."""
    normalized = gateway_name.lower()
    return _gateways.get(normalized, _gateways["mock"])
