"""
Repository layer for Speakaboo.

Abstract base repository that works with SQLite (dev) and can be swapped to Postgres.
"""

import json
import logging
import sqlite3
import time
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional
from datetime import datetime, timezone, timedelta

from backend.models.user import (
    User, Conversation, Turn, DailyUsage, Entitlement, MistakeLog, Plan,
)

logger = logging.getLogger("speakaboo.repositories")

# Asia/Dhaka timezone offset (UTC+6)
DHAKA_OFFSET = timedelta(hours=6)


def dhaka_today() -> str:
    """Get today's date in Asia/Dhaka timezone as YYYY-MM-DD."""
    now_utc = datetime.now(timezone.utc)
    dhaka_time = now_utc + DHAKA_OFFSET
    return dhaka_time.strftime("%Y-%m-%d")


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

    # --- Mistake logs (Phase 8 prep) ---
    @abstractmethod
    async def log_mistake(self, mistake: MistakeLog) -> MistakeLog: ...

    @abstractmethod
    async def get_mistakes(self, user_id: str, limit: int = 50) -> list[MistakeLog]: ...


class SqliteRepository(BaseRepository):
    """SQLite implementation of the repository."""

    def __init__(self, db_path: str = "speakaboo.db"):
        self._db_path = db_path
        self._conn: Optional[sqlite3.Connection] = None

    async def initialize(self) -> None:
        """Create tables if they don't exist."""
        self._conn = sqlite3.connect(self._db_path)
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
            
            CREATE INDEX IF NOT EXISTS idx_users_device ON users(device_id);
            CREATE INDEX IF NOT EXISTS idx_conversations_user ON conversations(user_id);
            CREATE INDEX IF NOT EXISTS idx_turns_conversation ON turns(conversation_id);
            CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date ON daily_usage(user_id, date);
            CREATE INDEX IF NOT EXISTS idx_entitlements_user ON entitlements(user_id);
            CREATE INDEX IF NOT EXISTS idx_mistakes_user ON mistake_logs(user_id);
        """)
        self._conn.commit()

    async def close(self) -> None:
        if self._conn:
            self._conn.close()

    # --- Users ---
    async def create_user(self, user: User) -> User:
        self._conn.execute(
            "INSERT INTO users (id, device_id, display_name, plan, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            (user.id, user.device_id, user.display_name, user.plan.value, user.created_at, user.updated_at),
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
        # Check if similar mistake already exists
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
