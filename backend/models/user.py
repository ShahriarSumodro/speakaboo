"""
Database models for Speakaboo.

Uses dataclasses for portability — works with SQLite now, Postgres later.
"""

import uuid
import time
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum


class Plan(str, Enum):
    FREE = "free"
    BASIC = "basic"
    PREMIUM = "premium"


class AgeBand(str, Enum):
    KID = "kid"
    TEEN = "teen"
    ADULT = "adult"


@dataclass
class User:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    device_id: str = ""
    display_name: str = ""
    plan: Plan = Plan.FREE
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)


@dataclass
class UserProfile:
    user_id: str
    display_name: str = "Learner"
    age_band: AgeBand = AgeBand.KID
    goal: str = "confidence"  # confidence, school, ielts, job
    level: str = "beginner"   # beginner, intermediate, advanced
    daily_goal_minutes: int = 10
    reminder_time: str = "20:00"  # 8 PM local time
    theme: str = "system"     # system, light, dark
    parent_pin_hash: str = ""
    language: str = "en"
    updated_at: float = field(default_factory=time.time)


@dataclass
class Conversation:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    character_id: str = ""
    started_at: float = field(default_factory=time.time)
    last_turn_at: float = field(default_factory=time.time)


@dataclass
class Turn:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    conversation_id: str = ""
    user_transcript: str = ""
    ai_reply: str = ""
    correction_json: Optional[str] = None
    new_words_json: Optional[str] = None
    stt_seconds: float = 0.0
    tts_chars: int = 0
    llm_tokens_in: int = 0
    llm_tokens_out: int = 0
    created_at: float = field(default_factory=time.time)


@dataclass
class DailyUsage:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    date: str = ""  # YYYY-MM-DD in Asia/Dhaka
    minutes_spoken: float = 0.0
    turns_count: int = 0


@dataclass
class Entitlement:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    type: str = ""  # "plan" or "character"
    value: str = ""  # plan name or character_id
    expires_at: Optional[float] = None


@dataclass 
class MistakeLog:
    """Tracks recurring mistake categories per user (Phase 8 preparation)."""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    category: str = ""  # grammar, word_choice, pronunciation, etc.
    original: str = ""
    better: str = ""
    count: int = 1
    last_seen_at: float = field(default_factory=time.time)
