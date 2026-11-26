"""
Data models for Phase 3 learning, retention, and gamification.
"""

import uuid
import time
from dataclasses import dataclass, field
from typing import Optional, List


@dataclass
class UserProgress:
    """User gamification and streak progress."""
    user_id: str
    xp: int = 0
    level: int = 1
    current_streak: int = 0
    longest_streak: int = 0
    last_active_date: str = ""  # YYYY-MM-DD in Asia/Dhaka
    streak_freeze_count: int = 0
    previous_streak: int = 0
    streak_repaired: bool = False
    updated_at: float = field(default_factory=time.time)


@dataclass
class Mission:
    """Daily mission definition."""
    id: str
    title: str
    description: str
    type: str  # speak_time, new_words, complete_scene, shadowing
    target: float
    xp_reward: int = 50


@dataclass
class UserMissionProgress:
    """User progress towards a daily mission."""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    date: str = ""  # YYYY-MM-DD in Asia/Dhaka
    mission_id: str = ""
    current_value: float = 0.0
    completed: bool = False
    reward_claimed: bool = False


@dataclass
class VocabularyItem:
    """Learned vocabulary word or corrected phrase with spaced repetition."""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    word_or_phrase: str = ""
    context_sentence: str = ""
    correction_notes: str = ""
    box: int = 1  # Leitner box 1 to 5
    next_review_date: str = ""  # YYYY-MM-DD in Asia/Dhaka
    times_reviewed: int = 0
    created_at: float = field(default_factory=time.time)


@dataclass
class Scenario:
    """Real-life speaking scenario pack."""
    id: str
    title: str
    category: str
    description: str
    prompt_context: str
    target_turns: int = 5
    suggested_vocabulary: List[str] = field(default_factory=list)
    difficulty: str = "intermediate"


@dataclass
class ShadowingScript:
    """Original practice script for shadowing mode."""
    id: str
    title: str
    target_text: str
    target_wpm: int = 120
    difficulty: str = "beginner"


@dataclass
class ShadowingEvaluation:
    """Evaluation result of learner shadowing attempt."""
    script_id: str
    transcript: str
    accuracy_score: float  # 0 to 100
    pace_wpm: float
    pace_score: float  # 0 to 100
    overall_score: float  # 0 to 100
    missed_words: List[str] = field(default_factory=list)
    added_words: List[str] = field(default_factory=list)
    feedback: str = ""


@dataclass
class SafetyFlag:
    """Recorded safety incident for parent dashboard."""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    category: str = ""
    snippet: str = ""
    created_at: float = field(default_factory=time.time)
