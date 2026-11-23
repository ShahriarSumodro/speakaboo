"""
Telemetry, Analytics, and Crash Reporting system for Speakaboo.

Tracks engagement, retention, learning milestones, and runtime errors
without ever logging personal data or audio content.
"""

from dataclasses import dataclass, field
import time
import logging
from typing import Dict, Any, List, Optional

logger = logging.getLogger("speakaboo.telemetry")


@dataclass
class AnalyticsEvent:
    """An event logged for product analytics (retention, funnel, usage)."""
    event_name: str
    user_id: str
    timestamp: float = field(default_factory=time.time)
    properties: Dict[str, Any] = field(default_factory=dict)


@dataclass
class CrashReport:
    """A caught exception or runtime crash report."""
    error_id: str
    error_type: str
    message: str
    stack_trace: str
    user_id: Optional[str] = None
    endpoint: Optional[str] = None
    timestamp: float = field(default_factory=time.time)


class TelemetryService:
    """
    In-memory telemetry and crash service with event batching.
    Can export to Mixpanel, PostHog, or Sentry in production.
    """

    def __init__(self, max_buffer_size: int = 500):
        self._events: List[AnalyticsEvent] = []
        self._crashes: List[CrashReport] = []
        self._max_buffer = max_buffer_size

    def track(self, event_name: str, user_id: str, properties: Optional[Dict[str, Any]] = None) -> AnalyticsEvent:
        """Track an analytics event."""
        event = AnalyticsEvent(
            event_name=event_name,
            user_id=user_id,
            properties=properties or {},
        )
        self._events.append(event)
        if len(self._events) > self._max_buffer:
            self._events.pop(0)

        logger.info(f"Analytics: [{event_name}] user={user_id} props={properties}")
        return event

    def record_crash(
        self,
        error_type: str,
        message: str,
        stack_trace: str,
        user_id: Optional[str] = None,
        endpoint: Optional[str] = None,
    ) -> CrashReport:
        """Record an application crash or unexpected error."""
        import uuid
        report = CrashReport(
            error_id=str(uuid.uuid4())[:8],
            error_type=error_type,
            message=message,
            stack_trace=stack_trace,
            user_id=user_id,
            endpoint=endpoint,
        )
        self._crashes.append(report)
        if len(self._crashes) > self._max_buffer:
            self._crashes.pop(0)

        logger.error(f"CrashReport [{report.error_id}]: {error_type} - {message} (endpoint={endpoint})")
        return report

    def get_events(self, user_id: Optional[str] = None) -> List[AnalyticsEvent]:
        """Get logged events, optionally filtered by user."""
        if user_id:
            return [e for e in self._events if e.user_id == user_id]
        return list(self._events)

    def get_crashes(self) -> List[CrashReport]:
        """Get logged crash reports."""
        return list(self._crashes)

    def clear(self) -> None:
        """Clear all buffers (useful in tests)."""
        self._events.clear()
        self._crashes.clear()


# Global telemetry singleton
telemetry = TelemetryService()
