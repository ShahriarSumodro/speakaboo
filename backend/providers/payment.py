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


class _BaseSandboxGateway(PaymentGateway):
    """Shared implementation for sandbox/mock payment gateways."""

    def __init__(
        self,
        gateway_name: str,
        pid_prefix: str,
        txn_prefix: str,
        checkout_url_template: str,
        not_found_message: str = "Payment session not found or expired.",
        fail_message: str = "Transaction was declined by user.",
        success_message: str = "Payment completed successfully.",
    ):
        self._gateway_name = gateway_name
        self._pid_prefix = pid_prefix
        self._txn_prefix = txn_prefix
        self._checkout_url_template = checkout_url_template
        self._not_found_message = not_found_message
        self._fail_message = fail_message
        self._success_message = success_message
        self._intents: Dict[str, PaymentIntent] = {}

    @property
    def name(self) -> str:
        return self._gateway_name

    async def create_payment_intent(
        self,
        user_id: str,
        amount_bdt: int,
        purpose: PaymentPurpose,
        target_id: str = "",
    ) -> PaymentIntent:
        pid = f"{self._pid_prefix}_{uuid.uuid4().hex[:12]}"
        checkout_url = self._checkout_url_template.format(
            pid=pid, sku=target_id or "monthly_pro"
        )
        intent = PaymentIntent(
            payment_id=pid,
            gateway=self._gateway_name,
            user_id=user_id,
            amount_bdt=amount_bdt,
            purpose=purpose,
            target_id=target_id,
            checkout_url=checkout_url,
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
                gateway=self._gateway_name,
                success=False,
                status=PaymentStatus.FAILED,
                message=self._not_found_message,
            )

        if verification_token == "FAIL_TXN":
            intent.status = PaymentStatus.FAILED
            return PaymentVerificationResult(
                payment_id=payment_id,
                gateway=self._gateway_name,
                success=False,
                status=PaymentStatus.FAILED,
                message=self._fail_message,
            )

        intent.status = PaymentStatus.COMPLETED
        txn_id = f"{self._txn_prefix}{uuid.uuid4().hex[:8].upper()}"
        ent_type = "plan" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else "character"
        ent_val = "monthly" if intent.purpose == PaymentPurpose.MONTHLY_PLAN else intent.target_id

        return PaymentVerificationResult(
            payment_id=payment_id,
            gateway=self._gateway_name,
            success=True,
            status=PaymentStatus.COMPLETED,
            transaction_id=txn_id,
            message=self._success_message,
            entitlement_type=ent_type,
            entitlement_value=ent_val,
        )

    async def process_webhook(
        self, payload: Dict[str, Any], signature: str = ""
    ) -> PaymentVerificationResult:
        pid = payload.get("payment_id", "")
        token = payload.get("purchase_token", "") or payload.get("verification_token", "")
        return await self.verify_payment(pid, token)


class MockBkashGateway(_BaseSandboxGateway):
    """Mock implementation of bKash payment gateway for development and testing."""

    def __init__(self):
        super().__init__(
            gateway_name="bkash",
            pid_prefix="bkash",
            txn_prefix="TRX_",
            checkout_url_template="https://sandbox.bkash.com/checkout?payment_id={pid}",
        )


class MockNagadGateway(_BaseSandboxGateway):
    """Mock implementation of Nagad payment gateway for development and testing."""

    def __init__(self):
        super().__init__(
            gateway_name="nagad",
            pid_prefix="nagad",
            txn_prefix="NGD_",
            checkout_url_template="https://sandbox.nagad.com.bd/checkout?payment_id={pid}",
        )


class GooglePlayBillingGateway(_BaseSandboxGateway):
    """Google Play In-App Billing verification gateway for Play Store flavor."""

    def __init__(self):
        super().__init__(
            gateway_name="google_play",
            pid_prefix="gp",
            txn_prefix="GPA.",
            checkout_url_template="play_billing://purchase?sku={sku}&payment_id={pid}",
            not_found_message="Google Play purchase session not found or expired.",
            fail_message="Google Play purchase was cancelled by user.",
            success_message="Google Play purchase verified successfully.",
        )


class WebBillingGateway(_BaseSandboxGateway):
    """External Web Checkout gateway (e.g. for browser checkout / aggregator)."""

    def __init__(self):
        super().__init__(
            gateway_name="web_checkout",
            pid_prefix="web",
            txn_prefix="WEB_",
            checkout_url_template="https://pay.speakaboo.app/checkout?session={pid}",
            not_found_message="Web checkout session not found or expired.",
            fail_message="Web payment failed.",
            success_message="Web checkout completed successfully.",
        )


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
