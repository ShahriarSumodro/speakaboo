"""
Repository layer for Speakaboo.

Abstract base repository that works with SQLite (dev) and can be swapped to Postgres.
Includes Phase 3 Learning, Gamification, Vocabulary, and Parent Dashboard support.
"""

import json
import logging
import sqlite3
import time
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone, timedelta

from backend.models.user import (
    User, UserProfile, AgeBand, Conversation, Turn, DailyUsage, Entitlement, MistakeLog, Plan,
)
from backend.models.learning import (
    UserProgress, Mission, UserMissionProgress, VocabularyItem, SafetyFlag,
)

logger = logging.getLogger("speakaboo.repositories")

# Asia/Dhaka timezone offset (UTC+6)
DHAKA_OFFSET = timedelta(hours=6)


def dhaka_today() -> str:
    """Get today's date in Asia/Dhaka timezone as YYYY-MM-DD."""
    now_utc = datetime.now(timezone.utc)
    dhaka_time = now_utc + DHAKA_OFFSET
    return dhaka_time.strftime("%Y-%m-%d")


def dhaka_date_add(days: int, from_date: Optional[str] = None) -> str:
    """Add days to a given YYYY-MM-DD date (or today in Asia/Dhaka)."""
    if from_date:
        base = datetime.strptime(from_date, "%Y-%m-%d")
    else:
        now_utc = datetime.now(timezone.utc)
        base = now_utc + DHAKA_OFFSET
    result = base + timedelta(days=days)
    return result.strftime("%Y-%m-%d")


def dhaka_date_diff(earlier_date: str, later_date: str) -> int:
    """Return later_date - earlier_date in whole days."""
    d1 = datetime.strptime(earlier_date, "%Y-%m-%d")
    d2 = datetime.strptime(later_date, "%Y-%m-%d")
    return (d2 - d1).days


def calculate_level(xp: int) -> int:
    """Calculate level from XP (e.g. Lvl 1: 0-100, Lvl 2: 101-250, Lvl 3: 251-450...)."""
    if xp <= 0:
        return 1
    # Simple progressive curve: 100 * level^1.2
    lvl = 1
    req = 100
    total = 0
    while total + req <= xp:
        total += req
        lvl += 1
        req = int(100 * (lvl ** 1.2))
    return lvl


class BaseRepository(ABC):
    """Abstract repository for all data operations."""

    # --- Users ---
    @abstractmethod
    async def create_user(self, user: User) -> User: ...
    @abstractmethod
    async def get_user(self, user_id: str) -> Optional[User]: ...
    @abstractmethod
    async def get_user_by_device(self, device_id: str) -> Optional[User]: ...
    @abstractmethod
    async def update_user(self, user: User) -> User: ...
    @abstractmethod
    async def delete_user_data(self, user_id: str) -> bool: ...
    @abstractmethod
    async def get_profile(self, user_id: str) -> Optional[UserProfile]: ...
    @abstractmethod
    async def save_profile(self, profile: UserProfile) -> UserProfile: ...
    @abstractmethod
    async def get_character_usage_seconds(self, user_id: str, character_id: str) -> float: ...
    @abstractmethod
    async def increment_character_usage_seconds(self, user_id: str, character_id: str, seconds: float) -> float: ...

    # --- Conversations ---
    @abstractmethod
    async def create_conversation(self, conv: Conversation) -> Conversation: ...
    @abstractmethod
    async def get_conversation(self, conv_id: str) -> Optional[Conversation]: ...

    # --- Turns ---
    @abstractmethod
    async def create_turn(self, turn: Turn) -> Turn: ...
    @abstractmethod
    async def get_turns(self, conversation_id: str, limit: int = 50) -> list[Turn]: ...

    # --- Usage ---
    @abstractmethod
    async def get_daily_usage(self, user_id: str, date: Optional[str] = None) -> Optional[DailyUsage]: ...
    @abstractmethod
    async def increment_usage(self, user_id: str, minutes: float, date: Optional[str] = None) -> DailyUsage: ...

    # --- Entitlements ---
    @abstractmethod
    async def get_entitlements(self, user_id: str) -> list[Entitlement]: ...
    @abstractmethod
    async def add_entitlement(self, entitlement: Entitlement) -> Entitlement: ...

    # --- Mistake logs ---
    @abstractmethod
    async def log_mistake(self, mistake: MistakeLog) -> MistakeLog: ...
    @abstractmethod
    async def get_mistakes(self, user_id: str, limit: int = 50) -> list[MistakeLog]: ...

    # --- Phase 3: Gamification & Streaks ---
    @abstractmethod
    async def get_progress(self, user_id: str) -> UserProgress: ...
    @abstractmethod
    async def record_activity(self, user_id: str, xp_earned: int = 0, date: Optional[str] = None) -> UserProgress: ...
    @abstractmethod
    async def add_streak_freeze(self, user_id: str, count: int = 1) -> UserProgress: ...

    # --- Phase 3: Missions ---
    @abstractmethod
    async def get_daily_missions(self, user_id: str, date: Optional[str] = None) -> List[UserMissionProgress]: ...
    @abstractmethod
    async def update_mission_progress(self, user_id: str, mission_type: str, increment: float, date: Optional[str] = None) -> List[UserMissionProgress]: ...
    @abstractmethod
    async def claim_mission_reward(self, user_id: str, mission_id: str, date: Optional[str] = None) -> Optional[int]: ...

    # --- Phase 3: Vocabulary Notebook ---
    @abstractmethod
    async def add_vocabulary(self, item: VocabularyItem) -> VocabularyItem: ...
    @abstractmethod
    async def get_vocabulary(self, user_id: str, limit: int = 100) -> List[VocabularyItem]: ...
    @abstractmethod
    async def get_due_vocabulary(self, user_id: str, date: Optional[str] = None) -> List[VocabularyItem]: ...
    @abstractmethod
    async def review_vocabulary(self, item_id: str, remembered: bool) -> Optional[VocabularyItem]: ...

    # --- Phase 3: Safety Flags & Parent Dashboard ---
    @abstractmethod
    async def log_safety_flag(self, flag: SafetyFlag) -> SafetyFlag: ...
    @abstractmethod
    async def get_safety_flags(self, user_id: str, limit: int = 50) -> List[SafetyFlag]: ...
    @abstractmethod
    async def get_parent_summary(self, user_id: str) -> Dict[str, Any]: ...

    # --- Payments Ledger ---
    @abstractmethod
    async def record_payment(self, payment_id: str, user_id: str, gateway: str, amount_bdt: int, purpose: str, target_id: str = "", checkout_url: str = "", status: str = "pending") -> dict: ...
    @abstractmethod
    async def get_payment(self, payment_id: str) -> Optional[dict]: ...
    @abstractmethod
    async def update_payment_status(self, payment_id: str, status: str, transaction_id: str = "") -> bool: ...
    @abstractmethod
    async def get_payments_by_user(self, user_id: str) -> List[dict]: ...

    # --- Experiments & Analytics ---
    @abstractmethod
    async def get_experiment_assignment(self, user_id: str, experiment_id: str) -> Optional[str]: ...
    @abstractmethod
    async def record_experiment_assignment(self, user_id: str, experiment_id: str, variant: str) -> None: ...
    @abstractmethod
    async def record_analytics_event(
        self,
        user_id: str,
        event_name: str,
        metric_value: float = 0.0,
        metadata: Optional[Dict[str, Any]] = None,
        session_id: str = "",
        experiment_id: str = "",
        variant: str = "",
    ) -> str: ...
    @abstractmethod
    async def get_analytics_events(
        self,
        event_name: Optional[str] = None,
        experiment_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]: ...


# Default Daily Missions pool
DEFAULT_MISSIONS = [
    Mission(id="m_speak_3m", title="Daily Speaker", description="Speak for at least 3 minutes today", type="speak_time", target=3.0, xp_reward=50),
    Mission(id="m_new_words_3", title="Word Explorer", description="Learn or use 3 new words", type="new_words", target=3.0, xp_reward=40),
    Mission(id="m_complete_scene", title="Scenario Master", description="Complete 1 real-life speaking scenario", type="complete_scene", target=1.0, xp_reward=60),
    Mission(id="m_shadowing_1", title="Echo Speaker", description="Complete 1 shadowing practice session", type="shadowing", target=1.0, xp_reward=50),
]


class SqliteRepository(BaseRepository):
    """SQLite implementation of the repository with full Phase 3 capabilities."""

    def __init__(self, db_path: str = "speakaboo.db"):
        self._db_path = db_path
        self._conn: Optional[sqlite3.Connection] = None

    @property
    def db_path(self) -> str:
        return self._db_path

    async def initialize(self) -> None:
        """Create tables and indexes if they don't exist."""
        self._conn = sqlite3.connect(self._db_path, check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        self._conn.execute("PRAGMA journal_mode=WAL")

        self._conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                device_id TEXT UNIQUE,
                display_name TEXT DEFAULT '',
                plan TEXT DEFAULT 'free',
                created_at REAL,
                updated_at REAL
            );
            
            CREATE TABLE IF NOT EXISTS conversations (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                character_id TEXT NOT NULL,
                started_at REAL,
                last_turn_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
            
            CREATE TABLE IF NOT EXISTS turns (
                id TEXT PRIMARY KEY,
                conversation_id TEXT NOT NULL,
                user_transcript TEXT,
                ai_reply TEXT,
                correction_json TEXT,
                new_words_json TEXT,
                stt_seconds REAL DEFAULT 0,
                tts_chars INTEGER DEFAULT 0,
                llm_tokens_in INTEGER DEFAULT 0,
                llm_tokens_out INTEGER DEFAULT 0,
                created_at REAL,
                FOREIGN KEY (conversation_id) REFERENCES conversations(id)
            );
            
            CREATE TABLE IF NOT EXISTS daily_usage (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                date TEXT NOT NULL,
                minutes_spoken REAL DEFAULT 0,
                turns_count INTEGER DEFAULT 0,
                UNIQUE(user_id, date),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
            
            CREATE TABLE IF NOT EXISTS entitlements (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                type TEXT NOT NULL,
                value TEXT NOT NULL,
                expires_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
            
            CREATE TABLE IF NOT EXISTS mistake_logs (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                category TEXT DEFAULT '',
                original TEXT DEFAULT '',
                better TEXT DEFAULT '',
                count INTEGER DEFAULT 1,
                last_seen_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 3: Gamification & Streaks
            CREATE TABLE IF NOT EXISTS user_progress (
                user_id TEXT PRIMARY KEY,
                xp INTEGER DEFAULT 0,
                level INTEGER DEFAULT 1,
                current_streak INTEGER DEFAULT 0,
                longest_streak INTEGER DEFAULT 0,
                last_active_date TEXT DEFAULT '',
                streak_freeze_count INTEGER DEFAULT 0,
                updated_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 3: Daily Missions Progress
            CREATE TABLE IF NOT EXISTS user_missions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                date TEXT NOT NULL,
                mission_id TEXT NOT NULL,
                current_value REAL DEFAULT 0.0,
                completed INTEGER DEFAULT 0,
                reward_claimed INTEGER DEFAULT 0,
                UNIQUE(user_id, date, mission_id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 3: Vocabulary Notebook (Leitner Box)
            CREATE TABLE IF NOT EXISTS vocabulary_items (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                word_or_phrase TEXT NOT NULL,
                context_sentence TEXT DEFAULT '',
                correction_notes TEXT DEFAULT '',
                box INTEGER DEFAULT 1,
                next_review_date TEXT NOT NULL,
                times_reviewed INTEGER DEFAULT 0,
                created_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 3: Safety Flags (for Parent Dashboard)
            CREATE TABLE IF NOT EXISTS safety_flags (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                category TEXT NOT NULL,
                snippet TEXT NOT NULL,
                created_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 1: User Profiles
            CREATE TABLE IF NOT EXISTS user_profiles (
                user_id TEXT PRIMARY KEY,
                display_name TEXT DEFAULT 'Learner',
                age_band TEXT DEFAULT 'kid',
                goal TEXT DEFAULT 'confidence',
                level TEXT DEFAULT 'beginner',
                daily_goal_minutes INTEGER DEFAULT 10,
                reminder_time TEXT DEFAULT '20:00',
                theme TEXT DEFAULT 'system',
                parent_pin_hash TEXT DEFAULT '',
                language TEXT DEFAULT 'en',
                updated_at REAL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 4: Character Free Trials (2 minutes free per locked companion)
            CREATE TABLE IF NOT EXISTS character_trials (
                user_id TEXT NOT NULL,
                character_id TEXT NOT NULL,
                seconds_used REAL DEFAULT 0.0,
                updated_at REAL,
                PRIMARY KEY (user_id, character_id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 6: Character Memory (remembers learner name, goal, and last topic)
            CREATE TABLE IF NOT EXISTS character_memories (
                user_id TEXT NOT NULL,
                character_id TEXT NOT NULL,
                learner_name TEXT DEFAULT '',
                goal TEXT DEFAULT '',
                last_topic TEXT DEFAULT '',
                last_hook TEXT DEFAULT '',
                last_summary TEXT DEFAULT '',
                updated_at REAL,
                PRIMARY KEY (user_id, character_id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Phase 6: Referrals & Viral Growth Loop
            CREATE TABLE IF NOT EXISTS referrals (
                id TEXT PRIMARY KEY,
                referrer_user_id TEXT NOT NULL,
                referee_user_id TEXT NOT NULL,
                reward_claimed INTEGER DEFAULT 0,
                created_at REAL,
                UNIQUE(referrer_user_id, referee_user_id),
                FOREIGN KEY (referrer_user_id) REFERENCES users(id),
                FOREIGN KEY (referee_user_id) REFERENCES users(id)
            );
            
            -- Phase 9: Payments & Transactions Ledger
            CREATE TABLE IF NOT EXISTS payments (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                gateway TEXT NOT NULL,
                amount_bdt INTEGER NOT NULL,
                purpose TEXT NOT NULL,
                target_id TEXT DEFAULT '',
                status TEXT NOT NULL,
                transaction_id TEXT DEFAULT '',
                checkout_url TEXT DEFAULT '',
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Patch Phase 1: Teaching & Pedagogical Experiments
            CREATE TABLE IF NOT EXISTS experiment_assignments (
                user_id TEXT NOT NULL,
                experiment_id TEXT NOT NULL,
                variant TEXT NOT NULL,
                assigned_at REAL NOT NULL,
                PRIMARY KEY (user_id, experiment_id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            );

            -- Patch Phase 1: Granular Analytics & Pedagogical Event Logging
            CREATE TABLE IF NOT EXISTS analytics_events (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                session_id TEXT DEFAULT '',
                event_name TEXT NOT NULL,
                experiment_id TEXT DEFAULT '',
                variant TEXT DEFAULT '',
                metric_value REAL DEFAULT 0.0,
                metadata_json TEXT DEFAULT '{}',
                timestamp REAL NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
            
            CREATE INDEX IF NOT EXISTS idx_users_device ON users(device_id);
            CREATE INDEX IF NOT EXISTS idx_conversations_user ON conversations(user_id);
            CREATE INDEX IF NOT EXISTS idx_turns_conversation ON turns(conversation_id);
            CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date ON daily_usage(user_id, date);
            CREATE INDEX IF NOT EXISTS idx_entitlements_user ON entitlements(user_id);
            CREATE INDEX IF NOT EXISTS idx_mistakes_user ON mistake_logs(user_id);
            CREATE INDEX IF NOT EXISTS idx_user_missions ON user_missions(user_id, date);
            CREATE INDEX IF NOT EXISTS idx_vocab_user ON vocabulary_items(user_id, next_review_date);
            CREATE INDEX IF NOT EXISTS idx_safety_flags_user ON safety_flags(user_id);
            CREATE INDEX IF NOT EXISTS idx_user_profiles_user ON user_profiles(user_id);
            CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
            CREATE INDEX IF NOT EXISTS idx_exp_assignments ON experiment_assignments(user_id, experiment_id);
            CREATE INDEX IF NOT EXISTS idx_events_name ON analytics_events(event_name);
            CREATE INDEX IF NOT EXISTS idx_events_user ON analytics_events(user_id);
            CREATE INDEX IF NOT EXISTS idx_events_exp ON analytics_events(experiment_id, variant);
        """)

        # Migrations for existing user_progress table
        for col, col_type in [("previous_streak", "INTEGER DEFAULT 0"), ("streak_repaired", "INTEGER DEFAULT 0")]:
            try:
                self._conn.execute(f"ALTER TABLE user_progress ADD COLUMN {col} {col_type}")
            except sqlite3.OperationalError:
                pass

        self._conn.commit()

    async def close(self) -> None:
        if self._conn:
            self._conn.close()
            self._conn = None

    # --- Users ---
    async def create_user(self, user: User) -> User:
        self._conn.execute(
            "INSERT INTO users (id, device_id, display_name, plan, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (user.id, user.device_id, user.display_name, user.plan.value, user.created_at, user.updated_at),
        )
        self._conn.execute(
            """INSERT OR IGNORE INTO user_profiles (
                user_id, display_name, age_band, goal, level,
                daily_goal_minutes, reminder_time, theme, parent_pin_hash, language, updated_at
            ) VALUES (?, ?, 'kid', 'confidence', 'beginner', 10, '20:00', 'system', '', 'en', ?)""",
            (user.id, user.display_name or "Learner", user.created_at),
        )
        self._conn.commit()
        return user

    async def get_user(self, user_id: str) -> Optional[User]:
        row = self._conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        return self._row_to_user(row) if row else None

    async def get_user_by_device(self, device_id: str) -> Optional[User]:
        row = self._conn.execute("SELECT * FROM users WHERE device_id = ?", (device_id,)).fetchone()
        return self._row_to_user(row) if row else None

    async def update_user(self, user: User) -> User:
        user.updated_at = time.time()
        self._conn.execute(
            "UPDATE users SET display_name = ?, plan = ?, updated_at = ? WHERE id = ?",
            (user.display_name, user.plan.value, user.updated_at, user.id),
        )
        self._conn.commit()
        return user

    async def get_profile(self, user_id: str) -> Optional[UserProfile]:
        row = self._conn.execute("SELECT * FROM user_profiles WHERE user_id = ?", (user_id,)).fetchone()
        if not row:
            return None
        return UserProfile(
            user_id=row["user_id"],
            display_name=row["display_name"],
            age_band=AgeBand(row["age_band"]),
            goal=row["goal"],
            level=row["level"],
            daily_goal_minutes=row["daily_goal_minutes"],
            reminder_time=row["reminder_time"],
            theme=row["theme"],
            parent_pin_hash=row["parent_pin_hash"] or "",
            language=row["language"] or "en",
            updated_at=row["updated_at"],
        )

    async def save_profile(self, profile: UserProfile) -> UserProfile:
        profile.updated_at = time.time()
        self._conn.execute(
            """INSERT INTO user_profiles (
                user_id, display_name, age_band, goal, level,
                daily_goal_minutes, reminder_time, theme, parent_pin_hash, language, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                display_name=excluded.display_name,
                age_band=excluded.age_band,
                goal=excluded.goal,
                level=excluded.level,
                daily_goal_minutes=excluded.daily_goal_minutes,
                reminder_time=excluded.reminder_time,
                theme=excluded.theme,
                parent_pin_hash=excluded.parent_pin_hash,
                language=excluded.language,
                updated_at=excluded.updated_at
            """,
            (
                profile.user_id,
                profile.display_name,
                profile.age_band.value if isinstance(profile.age_band, AgeBand) else profile.age_band,
                profile.goal,
                profile.level,
                profile.daily_goal_minutes,
                profile.reminder_time,
                profile.theme,
                profile.parent_pin_hash,
                profile.language,
                profile.updated_at,
            ),
        )
        self._conn.commit()
        return profile

    async def get_character_usage_seconds(self, user_id: str, character_id: str) -> float:
        row = self._conn.execute(
            "SELECT seconds_used FROM character_trials WHERE user_id = ? AND character_id = ?",
            (user_id, character_id),
        ).fetchone()
        return float(row["seconds_used"]) if row else 0.0

    async def increment_character_usage_seconds(self, user_id: str, character_id: str, seconds: float) -> float:
        now = time.time()
        self._conn.execute(
            """INSERT INTO character_trials (user_id, character_id, seconds_used, updated_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(user_id, character_id) DO UPDATE SET
                seconds_used = seconds_used + excluded.seconds_used,
                updated_at = excluded.updated_at
            """,
            (user_id, character_id, seconds, now),
        )
        self._conn.commit()
        return await self.get_character_usage_seconds(user_id, character_id)

    # --- Conversations ---
    async def create_conversation(self, conv: Conversation) -> Conversation:
        self._conn.execute(
            "INSERT INTO conversations (id, user_id, character_id, started_at, last_turn_at) VALUES (?, ?, ?, ?, ?)",
            (conv.id, conv.user_id, conv.character_id, conv.started_at, conv.last_turn_at),
        )
        self._conn.commit()
        return conv

    async def get_conversation(self, conv_id: str) -> Optional[Conversation]:
        row = self._conn.execute("SELECT * FROM conversations WHERE id = ?", (conv_id,)).fetchone()
        if not row:
            return None
        return Conversation(
            id=row["id"], user_id=row["user_id"], character_id=row["character_id"],
            started_at=row["started_at"], last_turn_at=row["last_turn_at"],
        )

    # --- Turns ---
    async def create_turn(self, turn: Turn) -> Turn:
        self._conn.execute(
            """INSERT INTO turns (id, conversation_id, user_transcript, ai_reply, correction_json,
               new_words_json, stt_seconds, tts_chars, llm_tokens_in, llm_tokens_out, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (turn.id, turn.conversation_id, turn.user_transcript, turn.ai_reply,
             turn.correction_json, turn.new_words_json, turn.stt_seconds, turn.tts_chars,
             turn.llm_tokens_in, turn.llm_tokens_out, turn.created_at),
        )
        self._conn.commit()
        return turn

    async def get_turns(self, conversation_id: str, limit: int = 50) -> list[Turn]:
        rows = self._conn.execute(
            "SELECT * FROM turns WHERE conversation_id = ? ORDER BY created_at DESC LIMIT ?",
            (conversation_id, limit),
        ).fetchall()
        return [self._row_to_turn(r) for r in rows]

    # --- Usage ---
    async def get_daily_usage(self, user_id: str, date: Optional[str] = None) -> Optional[DailyUsage]:
        date = date or dhaka_today()
        row = self._conn.execute(
            "SELECT * FROM daily_usage WHERE user_id = ? AND date = ?",
            (user_id, date),
        ).fetchone()
        if not row:
            return None
        return DailyUsage(
            id=row["id"], user_id=row["user_id"], date=row["date"],
            minutes_spoken=row["minutes_spoken"], turns_count=row["turns_count"],
        )

    async def increment_usage(self, user_id: str, minutes: float, date: Optional[str] = None) -> DailyUsage:
        date = date or dhaka_today()
        existing = await self.get_daily_usage(user_id, date)

        if existing:
            existing.minutes_spoken += minutes
            existing.turns_count += 1
            self._conn.execute(
                "UPDATE daily_usage SET minutes_spoken = ?, turns_count = ? WHERE id = ?",
                (existing.minutes_spoken, existing.turns_count, existing.id),
            )
            self._conn.commit()
            return existing
        else:
            usage = DailyUsage(user_id=user_id, date=date, minutes_spoken=minutes, turns_count=1)
            self._conn.execute(
                "INSERT INTO daily_usage (id, user_id, date, minutes_spoken, turns_count) VALUES (?, ?, ?, ?, ?)",
                (usage.id, usage.user_id, usage.date, usage.minutes_spoken, usage.turns_count),
            )
            self._conn.commit()
            return usage

    # --- Entitlements ---
    async def get_entitlements(self, user_id: str) -> list[Entitlement]:
        rows = self._conn.execute(
            "SELECT * FROM entitlements WHERE user_id = ?", (user_id,)
        ).fetchall()
        return [
            Entitlement(
                id=r["id"], user_id=r["user_id"], type=r["type"],
                value=r["value"], expires_at=r["expires_at"],
            )
            for r in rows
        ]

    async def add_entitlement(self, entitlement: Entitlement) -> Entitlement:
        self._conn.execute(
            "INSERT INTO entitlements (id, user_id, type, value, expires_at) VALUES (?, ?, ?, ?, ?)",
            (entitlement.id, entitlement.user_id, entitlement.type,
             entitlement.value, entitlement.expires_at),
        )
        self._conn.commit()
        return entitlement

    # --- Mistake logs ---
    async def log_mistake(self, mistake: MistakeLog) -> MistakeLog:
        existing = self._conn.execute(
            "SELECT * FROM mistake_logs WHERE user_id = ? AND original = ? AND better = ?",
            (mistake.user_id, mistake.original, mistake.better),
        ).fetchone()

        if existing:
            self._conn.execute(
                "UPDATE mistake_logs SET count = count + 1, last_seen_at = ? WHERE id = ?",
                (time.time(), existing["id"]),
            )
            self._conn.commit()
            mistake.id = existing["id"]
            mistake.count = existing["count"] + 1
        else:
            self._conn.execute(
                "INSERT INTO mistake_logs (id, user_id, category, original, better, count, last_seen_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (mistake.id, mistake.user_id, mistake.category, mistake.original,
                 mistake.better, mistake.count, mistake.last_seen_at),
            )
            self._conn.commit()

        return mistake

    async def get_mistakes(self, user_id: str, limit: int = 50) -> list[MistakeLog]:
        rows = self._conn.execute(
            "SELECT * FROM mistake_logs WHERE user_id = ? ORDER BY last_seen_at DESC LIMIT ?",
            (user_id, limit),
        ).fetchall()
        return [
            MistakeLog(
                id=r["id"], user_id=r["user_id"], category=r["category"],
                original=r["original"], better=r["better"],
                count=r["count"], last_seen_at=r["last_seen_at"],
            )
            for r in rows
        ]

    # ========================================================
    # Phase 3: Gamification & Daily Streaks (Asia/Dhaka safe)
    # ========================================================

    async def get_progress(self, user_id: str) -> UserProgress:
        row = self._conn.execute(
            "SELECT * FROM user_progress WHERE user_id = ?", (user_id,)
        ).fetchone()

        if not row:
            # Initialize progress for user
            prog = UserProgress(user_id=user_id)
            self._conn.execute(
                """INSERT INTO user_progress (user_id, xp, level, current_streak, longest_streak,
                   last_active_date, streak_freeze_count, updated_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (prog.user_id, prog.xp, prog.level, prog.current_streak, prog.longest_streak,
                 prog.last_active_date, prog.streak_freeze_count, prog.updated_at),
            )
            self._conn.commit()
            return prog

        return UserProgress(
            user_id=row["user_id"],
            xp=row["xp"],
            level=row["level"],
            current_streak=row["current_streak"],
            longest_streak=row["longest_streak"],
            last_active_date=row["last_active_date"],
            streak_freeze_count=row["streak_freeze_count"],
            previous_streak=row["previous_streak"] if "previous_streak" in row.keys() else 0,
            streak_repaired=bool(row["streak_repaired"]) if "streak_repaired" in row.keys() else False,
            updated_at=row["updated_at"],
        )

    async def record_activity(
        self, user_id: str, xp_earned: int = 0, date: Optional[str] = None
    ) -> UserProgress:
        """Record user activity today, updating streak (Asia/Dhaka safe) and XP."""
        today = date or dhaka_today()
        prog = await self.get_progress(user_id)

        # 1. Update XP & Level
        prog.xp += xp_earned
        prog.level = calculate_level(prog.xp)

        # 2. Streak calculation
        if not prog.last_active_date:
            # First day ever active
            prog.current_streak = 1
            prog.longest_streak = max(prog.longest_streak, 1)
            prog.last_active_date = today
        elif prog.last_active_date == today:
            # Already active today, streak doesn't increment further today
            pass
        else:
            diff = dhaka_date_diff(prog.last_active_date, today)
            if diff == 1:
                # Consecutive day!
                prog.current_streak += 1
                prog.longest_streak = max(prog.longest_streak, prog.current_streak)
                prog.last_active_date = today
            elif diff == 2 and prog.streak_freeze_count > 0:
                # Missed 1 day, but saved by streak freeze!
                prog.streak_freeze_count -= 1
                prog.current_streak += 1
                prog.longest_streak = max(prog.longest_streak, prog.current_streak)
                prog.last_active_date = today
                logger.info(f"Streak freeze used for user {user_id}. Remaining: {prog.streak_freeze_count}")
            else:
                # Missed more than allowed without freeze: save previous streak for repair opportunity
                prog.previous_streak = prog.current_streak
                prog.streak_repaired = False
                prog.current_streak = 1
                prog.longest_streak = max(prog.longest_streak, 1)
                prog.last_active_date = today

        prog.updated_at = time.time()

        self._conn.execute(
            """UPDATE user_progress SET xp = ?, level = ?, current_streak = ?, longest_streak = ?,
               last_active_date = ?, streak_freeze_count = ?, previous_streak = ?, streak_repaired = ?,
               updated_at = ? WHERE user_id = ?""",
            (prog.xp, prog.level, prog.current_streak, prog.longest_streak,
             prog.last_active_date, prog.streak_freeze_count, prog.previous_streak,
             1 if prog.streak_repaired else 0, prog.updated_at, user_id),
        )
        self._conn.commit()
        return prog

    async def repair_streak(self, user_id: str) -> tuple[UserProgress, bool]:
        """Restore lost streak without guilt if learner completes a recovery session."""
        prog = await self.get_progress(user_id)
        if prog.previous_streak > 1 and not prog.streak_repaired:
            prog.current_streak = prog.previous_streak + 1
            prog.longest_streak = max(prog.longest_streak, prog.current_streak)
            prog.previous_streak = 0
            prog.streak_repaired = True
            prog.updated_at = time.time()
            self._conn.execute(
                """UPDATE user_progress SET current_streak = ?, longest_streak = ?, previous_streak = ?,
                   streak_repaired = ?, updated_at = ? WHERE user_id = ?""",
                (prog.current_streak, prog.longest_streak, prog.previous_streak,
                 1 if prog.streak_repaired else 0, prog.updated_at, user_id),
            )
            self._conn.commit()
            return prog, True
        return prog, False

    async def add_streak_freeze(self, user_id: str, count: int = 1) -> UserProgress:
        prog = await self.get_progress(user_id)
        prog.streak_freeze_count += count
        prog.updated_at = time.time()
        self._conn.execute(
            "UPDATE user_progress SET streak_freeze_count = ?, updated_at = ? WHERE user_id = ?",
            (prog.streak_freeze_count, prog.updated_at, user_id),
        )
        self._conn.commit()
        return prog

    # ========================================================
    # Phase 6: Character Memory & Social Proof
    # ========================================================

    async def save_character_memory(
        self,
        user_id: str,
        character_id: str,
        learner_name: str = "",
        goal: str = "",
        last_topic: str = "",
        last_hook: str = "",
        last_summary: str = "",
    ) -> None:
        """Store companion memory of learner details and previous conversation topics."""
        now = time.time()
        self._conn.execute(
            """INSERT INTO character_memories (user_id, character_id, learner_name, goal, last_topic, last_hook, last_summary, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)
               ON CONFLICT(user_id, character_id) DO UPDATE SET
               learner_name = CASE WHEN excluded.learner_name != '' THEN excluded.learner_name ELSE character_memories.learner_name END,
               goal = CASE WHEN excluded.goal != '' THEN excluded.goal ELSE character_memories.goal END,
               last_topic = CASE WHEN excluded.last_topic != '' THEN excluded.last_topic ELSE character_memories.last_topic END,
               last_hook = CASE WHEN excluded.last_hook != '' THEN excluded.last_hook ELSE character_memories.last_hook END,
               last_summary = CASE WHEN excluded.last_summary != '' THEN excluded.last_summary ELSE character_memories.last_summary END,
               updated_at = excluded.updated_at""",
            (user_id, character_id, learner_name, goal, last_topic, last_hook, last_summary, now),
        )
        self._conn.commit()

    async def get_character_memory(self, user_id: str, character_id: str) -> Optional[dict]:
        """Retrieve stored companion memory for personalized greetings."""
        row = self._conn.execute(
            "SELECT * FROM character_memories WHERE user_id = ? AND character_id = ?",
            (user_id, character_id),
        ).fetchone()
        if not row:
            return None
        return {
            "user_id": row["user_id"],
            "character_id": row["character_id"],
            "learner_name": row["learner_name"],
            "goal": row["goal"],
            "last_topic": row["last_topic"],
            "last_hook": row["last_hook"],
            "last_summary": row["last_summary"],
            "updated_at": row["updated_at"],
        }

    async def create_referral(self, referrer_id: str, referee_id: str) -> bool:
        """Record referral and reward both learners with XP and streak freeze."""
        if referrer_id == referee_id:
            return False
        import uuid as _uuid
        try:
            self._conn.execute(
                """INSERT INTO referrals (id, referrer_user_id, referee_user_id, reward_claimed, created_at)
                   VALUES (?, ?, ?, 0, ?)""",
                (str(_uuid.uuid4()), referrer_id, referee_id, time.time()),
            )
            # Award referrer 100 XP + 1 streak freeze
            await self.record_activity(referrer_id, xp_earned=100)
            await self.add_streak_freeze(referrer_id, count=1)
            # Award referee 50 XP
            await self.record_activity(referee_id, xp_earned=50)
            self._conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False

    async def get_referral_info(self, user_id: str) -> dict:
        """Get user referral code and statistics."""
        import hashlib
        short_code = "SPK-" + hashlib.md5(user_id.encode()).hexdigest()[:6].upper()
        rows = self._conn.execute(
            "SELECT * FROM referrals WHERE referrer_user_id = ?", (user_id,)
        ).fetchall()
        return {
            "referral_code": short_code,
            "referral_count": len(rows),
            "xp_earned": len(rows) * 100,
            "freezes_earned": len(rows),
        }

    # ========================================================
    # Phase 3: Daily Missions Engine
    # ========================================================

    async def get_daily_missions(
        self, user_id: str, date: Optional[str] = None
    ) -> List[UserMissionProgress]:
        today = date or dhaka_today()

        # Check existing missions for today
        rows = self._conn.execute(
            "SELECT * FROM user_missions WHERE user_id = ? AND date = ?",
            (user_id, today),
        ).fetchall()

        if not rows:
            # Seed default missions for today
            seeded = []
            for m in DEFAULT_MISSIONS:
                ump = UserMissionProgress(user_id=user_id, date=today, mission_id=m.id)
                self._conn.execute(
                    """INSERT INTO user_missions (id, user_id, date, mission_id, current_value, completed, reward_claimed)
                       VALUES (?, ?, ?, ?, ?, ?, ?)""",
                    (ump.id, ump.user_id, ump.date, ump.mission_id, ump.current_value,
                     1 if ump.completed else 0, 1 if ump.reward_claimed else 0),
                )
                seeded.append(ump)
            self._conn.commit()
            return seeded

        return [
            UserMissionProgress(
                id=r["id"],
                user_id=r["user_id"],
                date=r["date"],
                mission_id=r["mission_id"],
                current_value=r["current_value"],
                completed=bool(r["completed"]),
                reward_claimed=bool(r["reward_claimed"]),
            )
            for r in rows
        ]

    async def update_mission_progress(
        self, user_id: str, mission_type: str, increment: float, date: Optional[str] = None
    ) -> List[UserMissionProgress]:
        missions = await self.get_daily_missions(user_id, date)
        type_to_mission = {m.type: m for m in DEFAULT_MISSIONS}

        updated = []
        for ump in missions:
            m_def = next((m for m in DEFAULT_MISSIONS if m.id == ump.mission_id), None)
            if m_def and m_def.type == mission_type and not ump.completed:
                ump.current_value += increment
                if ump.current_value >= m_def.target:
                    ump.completed = True

                self._conn.execute(
                    "UPDATE user_missions SET current_value = ?, completed = ? WHERE id = ?",
                    (ump.current_value, 1 if ump.completed else 0, ump.id),
                )
                updated.append(ump)

        if updated:
            self._conn.commit()

        return missions

    async def claim_mission_reward(
        self, user_id: str, mission_id: str, date: Optional[str] = None
    ) -> Optional[int]:
        today = date or dhaka_today()
        row = self._conn.execute(
            "SELECT * FROM user_missions WHERE user_id = ? AND date = ? AND mission_id = ?",
            (user_id, today, mission_id),
        ).fetchone()

        if not row or not row["completed"] or row["reward_claimed"]:
            return None

        m_def = next((m for m in DEFAULT_MISSIONS if m.id == mission_id), None)
        xp_reward = m_def.xp_reward if m_def else 50

        self._conn.execute(
            "UPDATE user_missions SET reward_claimed = 1 WHERE id = ?", (row["id"],)
        )
        self._conn.commit()

        # Award XP to user progress
        await self.record_activity(user_id, xp_earned=xp_reward, date=today)
        return xp_reward

    # ========================================================
    # Phase 3: Vocabulary Notebook (Spaced Repetition / Leitner)
    # ========================================================

    async def add_vocabulary(self, item: VocabularyItem) -> VocabularyItem:
        if not item.next_review_date:
            item.next_review_date = dhaka_date_add(1)  # Default: review tomorrow

        self._conn.execute(
            """INSERT INTO vocabulary_items (id, user_id, word_or_phrase, context_sentence,
               correction_notes, box, next_review_date, times_reviewed, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (item.id, item.user_id, item.word_or_phrase, item.context_sentence,
             item.correction_notes, item.box, item.next_review_date, item.times_reviewed, item.created_at),
        )
        self._conn.commit()
        return item

    async def get_vocabulary(self, user_id: str, limit: int = 100) -> List[VocabularyItem]:
        rows = self._conn.execute(
            "SELECT * FROM vocabulary_items WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
            (user_id, limit),
        ).fetchall()
        return [self._row_to_vocab(r) for r in rows]

    async def get_due_vocabulary(
        self, user_id: str, date: Optional[str] = None
    ) -> List[VocabularyItem]:
        today = date or dhaka_today()
        rows = self._conn.execute(
            "SELECT * FROM vocabulary_items WHERE user_id = ? AND next_review_date <= ? ORDER BY next_review_date ASC",
            (user_id, today),
        ).fetchall()
        return [self._row_to_vocab(r) for r in rows]

    async def review_vocabulary(self, item_id: str, remembered: bool) -> Optional[VocabularyItem]:
        row = self._conn.execute(
            "SELECT * FROM vocabulary_items WHERE id = ?", (item_id,)
        ).fetchone()
        if not row:
            return None

        current_box = row["box"]
        times_reviewed = row["times_reviewed"] + 1

        # Leitner box interval: Box 1=1d, Box 2=3d, Box 3=7d, Box 4=14d, Box 5=30d
        box_intervals = {1: 1, 2: 3, 3: 7, 4: 14, 5: 30}

        if remembered:
            new_box = min(5, current_box + 1)
        else:
            new_box = 1  # Reset to box 1 on lapse

        days_ahead = box_intervals.get(new_box, 1)
        next_date = dhaka_date_add(days_ahead)

        self._conn.execute(
            """UPDATE vocabulary_items SET box = ?, next_review_date = ?, times_reviewed = ?
               WHERE id = ?""",
            (new_box, next_date, times_reviewed, item_id),
        )
        self._conn.commit()

        return VocabularyItem(
            id=row["id"],
            user_id=row["user_id"],
            word_or_phrase=row["word_or_phrase"],
            context_sentence=row["context_sentence"],
            correction_notes=row["correction_notes"],
            box=new_box,
            next_review_date=next_date,
            times_reviewed=times_reviewed,
            created_at=row["created_at"],
        )

    # ========================================================
    # Phase 3: Safety Flags & Parent Dashboard
    # ========================================================

    async def log_safety_flag(self, flag: SafetyFlag) -> SafetyFlag:
        self._conn.execute(
            "INSERT INTO safety_flags (id, user_id, category, snippet, created_at) VALUES (?, ?, ?, ?, ?)",
            (flag.id, flag.user_id, flag.category, flag.snippet, flag.created_at),
        )
        self._conn.commit()
        return flag

    async def get_safety_flags(self, user_id: str, limit: int = 50) -> List[SafetyFlag]:
        rows = self._conn.execute(
            "SELECT * FROM safety_flags WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
            (user_id, limit),
        ).fetchall()
        return [
            SafetyFlag(
                id=r["id"],
                user_id=r["user_id"],
                category=r["category"],
                snippet=r["snippet"],
                created_at=r["created_at"],
            )
            for r in rows
        ]

    async def get_parent_summary(self, user_id: str) -> Dict[str, Any]:
        """Aggregate data for parent dashboard: weekly minutes, streak, words, safety flags."""
        today = dhaka_today()
        # 7 days window
        seven_days_ago = dhaka_date_add(-7, from_date=today)

        # Weekly minutes & turns
        usage_rows = self._conn.execute(
            """SELECT SUM(minutes_spoken) as total_min, SUM(turns_count) as total_turns
               FROM daily_usage WHERE user_id = ? AND date >= ?""",
            (user_id, seven_days_ago),
        ).fetchone()

        weekly_minutes = usage_rows["total_min"] or 0.0
        weekly_turns = usage_rows["total_turns"] or 0

        # Progress
        progress = await self.get_progress(user_id)

        # Total vocabulary learned
        vocab_count = self._conn.execute(
            "SELECT COUNT(*) as cnt FROM vocabulary_items WHERE user_id = ?",
            (user_id,),
        ).fetchone()["cnt"]

        # Safety flags count in last 30 days
        thirty_days_ago = time.time() - (30 * 86400)
        safety_rows = self._conn.execute(
            "SELECT category, COUNT(*) as cnt FROM safety_flags WHERE user_id = ? AND created_at >= ? GROUP BY category",
            (user_id, thirty_days_ago),
        ).fetchall()

        safety_counts = {r["category"]: r["cnt"] for r in safety_rows}
        total_safety_flags = sum(safety_counts.values())

        return {
            "user_id": user_id,
            "weekly_minutes_spoken": round(weekly_minutes, 1),
            "weekly_turns_count": weekly_turns,
            "current_streak": progress.current_streak,
            "longest_streak": progress.longest_streak,
            "xp": progress.xp,
            "level": progress.level,
            "total_words_learned": vocab_count,
            "safety_flags_count": total_safety_flags,
            "safety_flags_by_category": safety_counts,
        }

    # ========================================================
    # Phase 9: Payments Ledger
    # ========================================================

    async def record_payment(
        self,
        payment_id: str,
        user_id: str,
        gateway: str,
        amount_bdt: int,
        purpose: str,
        target_id: str = "",
        checkout_url: str = "",
        status: str = "pending",
    ) -> dict:
        now = time.time()
        self._conn.execute(
            """INSERT INTO payments (id, user_id, gateway, amount_bdt, purpose, target_id, status, transaction_id, checkout_url, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, '', ?, ?, ?)""",
            (payment_id, user_id, gateway, amount_bdt, purpose, target_id, status, checkout_url, now, now),
        )
        self._conn.commit()
        return {
            "id": payment_id,
            "user_id": user_id,
            "gateway": gateway,
            "amount_bdt": amount_bdt,
            "purpose": purpose,
            "target_id": target_id,
            "status": status,
            "checkout_url": checkout_url,
            "created_at": now,
        }

    async def get_payment(self, payment_id: str) -> Optional[dict]:
        row = self._conn.execute("SELECT * FROM payments WHERE id = ?", (payment_id,)).fetchone()
        if not row:
            return None
        return dict(row)

    async def update_payment_status(
        self, payment_id: str, status: str, transaction_id: str = ""
    ) -> bool:
        now = time.time()
        cur = self._conn.execute(
            "UPDATE payments SET status = ?, transaction_id = ?, updated_at = ? WHERE id = ?",
            (status, transaction_id, now, payment_id),
        )
        self._conn.commit()
        return cur.rowcount > 0

    async def get_payments_by_user(self, user_id: str) -> List[dict]:
        rows = self._conn.execute(
            "SELECT * FROM payments WHERE user_id = ? ORDER BY created_at DESC", (user_id,)
        ).fetchall()
        return [dict(r) for r in rows]

    async def delete_user_data(self, user_id: str) -> bool:
        """Completely purge all records for a user across all tables."""
        cursor = self._conn.cursor()
        cursor.execute("SELECT id FROM conversations WHERE user_id = ?", (user_id,))
        conv_ids = [r["id"] for r in cursor.fetchall()]
        for cid in conv_ids:
            cursor.execute("DELETE FROM turns WHERE conversation_id = ?", (cid,))
        cursor.execute("DELETE FROM conversations WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM daily_usage WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM entitlements WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM mistake_logs WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM user_progress WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM user_missions WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM vocabulary_items WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM safety_flags WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM user_profiles WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM character_trials WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM character_memories WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM referrals WHERE referrer_user_id = ? OR referee_user_id = ?", (user_id, user_id))
        cursor.execute("DELETE FROM payments WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM experiment_assignments WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM analytics_events WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
        self._conn.commit()
        return True

    # --- Experiments & Analytics ---
    async def get_experiment_assignment(self, user_id: str, experiment_id: str) -> Optional[str]:
        cursor = self._conn.execute(
            "SELECT variant FROM experiment_assignments WHERE user_id = ? AND experiment_id = ?",
            (user_id, experiment_id),
        )
        row = cursor.fetchone()
        return row[0] if row else None

    async def record_experiment_assignment(self, user_id: str, experiment_id: str, variant: str) -> None:
        self._conn.execute(
            """
            INSERT OR REPLACE INTO experiment_assignments (user_id, experiment_id, variant, assigned_at)
            VALUES (?, ?, ?, ?)
            """,
            (user_id, experiment_id, variant, time.time()),
        )
        self._conn.commit()

    async def record_analytics_event(
        self,
        user_id: str,
        event_name: str,
        metric_value: float = 0.0,
        metadata: Optional[Dict[str, Any]] = None,
        session_id: str = "",
        experiment_id: str = "",
        variant: str = "",
    ) -> str:
        import uuid
        event_id = str(uuid.uuid4())
        meta_json = json.dumps(metadata or {})
        self._conn.execute(
            """
            INSERT INTO analytics_events (
                id, user_id, session_id, event_name, experiment_id, variant, metric_value, metadata_json, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                event_id,
                user_id,
                session_id,
                event_name,
                experiment_id,
                variant,
                float(metric_value),
                meta_json,
                time.time(),
            ),
        )
        self._conn.commit()
        return event_id

    async def get_analytics_events(
        self,
        event_name: Optional[str] = None,
        experiment_id: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        query = "SELECT * FROM analytics_events WHERE 1=1"
        params = []
        if event_name:
            query += " AND event_name = ?"
            params.append(event_name)
        if experiment_id:
            query += " AND experiment_id = ?"
            params.append(experiment_id)
        if user_id:
            query += " AND user_id = ?"
            params.append(user_id)
        query += " ORDER BY timestamp ASC"

        cursor = self._conn.execute(query, params)
        rows = cursor.fetchall()
        result = []
        for r in rows:
            result.append({
                "id": r["id"],
                "user_id": r["user_id"],
                "session_id": r["session_id"],
                "event_name": r["event_name"],
                "experiment_id": r["experiment_id"],
                "variant": r["variant"],
                "metric_value": r["metric_value"],
                "metadata": json.loads(r["metadata_json"] or "{}"),
                "timestamp": r["timestamp"],
            })
        return result

    # --- Helpers ---
    @staticmethod
    def _row_to_user(row) -> User:
        return User(
            id=row["id"],
            device_id=row["device_id"],
            display_name=row["display_name"],
            plan=Plan(row["plan"]),
            created_at=row["created_at"],
            updated_at=row["updated_at"],
        )

    @staticmethod
    def _row_to_turn(row) -> Turn:
        return Turn(
            id=row["id"],
            conversation_id=row["conversation_id"],
            user_transcript=row["user_transcript"],
            ai_reply=row["ai_reply"],
            correction_json=row["correction_json"],
            new_words_json=row["new_words_json"],
            stt_seconds=row["stt_seconds"],
            tts_chars=row["tts_chars"],
            llm_tokens_in=row["llm_tokens_in"],
            llm_tokens_out=row["llm_tokens_out"],
            created_at=row["created_at"],
        )

    @staticmethod
    def _row_to_vocab(row) -> VocabularyItem:
        return VocabularyItem(
            id=row["id"],
            user_id=row["user_id"],
            word_or_phrase=row["word_or_phrase"],
            context_sentence=row["context_sentence"],
            correction_notes=row["correction_notes"],
            box=row["box"],
            next_review_date=row["next_review_date"],
            times_reviewed=row["times_reviewed"],
            created_at=row["created_at"],
        )
