"""
Speakaboo Experiments & Pedagogical A/B Testing Service.

Provides:
- Config-driven experiment definitions matching EXPERIMENTS.md.
- Stable, deterministic user bucketing (SHA-256 hash modulo variants).
- Persistent variant assignments stored in SQLite.
- Granular event logging across SLA metrics: session length, return tomorrow,
  correction self-fixes, task repetition metrics, review recall, speaking checks,
  and per-turn AI infrastructure costs.
"""

import time
import hashlib
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional

from backend.repositories import get_repository
from backend.repositories.sqlite_repo import BaseRepository


@dataclass(frozen=True)
class Experiment:
    id: str
    name: str
    description: str
    variants: List[str]
    default_variant: str
    active: bool = True


# Pre-configured pedagogical & business experiments
EXPERIMENTS_REGISTRY: Dict[str, Experiment] = {
    "EXP001_CORRECTION_STYLE": Experiment(
        id="EXP001_CORRECTION_STYLE",
        name="Correction Style: Prompts First vs Recasts First",
        description="Tests whether clarification prompts increase learner self-repair compared to recasts.",
        variants=["prompts_first", "recast_first"],
        default_variant="recast_first",
    ),
    "EXP002_TASK_REPETITION": Experiment(
        id="EXP002_TASK_REPETITION",
        name="Task Repetition: Again, Faster Drills",
        description="Tests 3-attempt timed repetition drills for automaticity and WPM fluency gains.",
        variants=["repetition_drill", "single_attempt"],
        default_variant="single_attempt",
    ),
    "EXP003_PRE_TASK_PLANNING": Experiment(
        id="EXP003_PRE_TASK_PLANNING",
        name="Pre-Task Planning Time",
        description="Tests whether 45s of guided planning increases clause complexity in scenarios.",
        variants=["guided_planning", "immediate_start"],
        default_variant="immediate_start",
    ),
    "EXP004_FEEDBACK_TIMING": Experiment(
        id="EXP004_FEEDBACK_TIMING",
        name="Feedback Timing: Interim vs Delayed",
        description="Tests whether delayed session-end feedback lowers in-session anxiety.",
        variants=["interim", "delayed"],
        default_variant="delayed",
    ),
    "EXP005_PRICING_MODEL": Experiment(
        id="EXP005_PRICING_MODEL",
        name="Pricing Elasticity: Monthly vs Weekly vs Bundle",
        description="Tests paid conversion for 200 BDT/month vs 60 BDT/week vs 500 BDT/3-months.",
        variants=["monthly_200", "weekly_60", "bundle_500"],
        default_variant="monthly_200",
    ),
    "EXP006_PHONETIC_TRAINING": Experiment(
        id="EXP006_PHONETIC_TRAINING",
        name="High-Variability Multi-Voice Phonetic Training",
        description="Tests whether perception minimal pairs across Orpheus voices improve pronunciation.",
        variants=["multi_voice_perception", "single_voice_production"],
        default_variant="single_voice_production",
    ),
}


class ExperimentsService:
    """Service managing deterministic A/B assignment and experiment event logging."""

    def __init__(self, repo: Optional[BaseRepository] = None):
        self._repo = repo

    def _get_repo(self) -> BaseRepository:
        return self._repo or get_repository()

    async def get_variant(self, user_id: str, experiment_id: str) -> str:
        """Get or assign a stable, persistent variant for a user in an experiment."""
        repo = self._get_repo()
        exp = EXPERIMENTS_REGISTRY.get(experiment_id)
        if not exp or not exp.active:
            return exp.default_variant if exp else "control"

        # 1. Check existing assignment in database
        assigned = await repo.get_experiment_assignment(user_id, experiment_id)
        if assigned and assigned in exp.variants:
            return assigned

        # 2. Compute deterministic hash bucket
        seed = f"{user_id}:{experiment_id}".encode("utf-8")
        hash_val = int(hashlib.sha256(seed).hexdigest(), 16)
        bucket = hash_val % len(exp.variants)
        selected_variant = exp.variants[bucket]

        # 3. Persist assignment permanently
        await repo.record_experiment_assignment(user_id, experiment_id, selected_variant)
        return selected_variant

    async def log_event(
        self,
        user_id: str,
        event_name: str,
        metric_value: float = 0.0,
        metadata: Optional[Dict[str, Any]] = None,
        session_id: str = "",
        experiment_id: str = "",
        variant: str = "",
    ) -> str:
        """Log a granular analytics/pedagogical event with experiment attribution."""
        repo = self._get_repo()

        # If experiment_id is provided but variant is empty, auto-resolve variant
        if experiment_id and not variant:
            variant = await self.get_variant(user_id, experiment_id)

        return await repo.record_analytics_event(
            user_id=user_id,
            event_name=event_name,
            metric_value=metric_value,
            metadata=metadata or {},
            session_id=session_id,
            experiment_id=experiment_id,
            variant=variant,
        )

    # --- Specific Pedagogical Metric Loggers ---

    async def log_session_length(self, user_id: str, duration_seconds: float, session_id: str = "", experiment_id: str = "") -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="session_length",
            metric_value=duration_seconds,
            metadata={"duration_seconds": duration_seconds},
            session_id=session_id,
            experiment_id=experiment_id,
        )

    async def log_next_day_return(self, user_id: str, returned: bool, day_offset: int = 1, experiment_id: str = "") -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="next_day_return",
            metric_value=1.0 if returned else 0.0,
            metadata={"day_offset": day_offset, "returned": returned},
            experiment_id=experiment_id,
        )

    async def log_correction_outcome(
        self,
        user_id: str,
        correction_type: str,  # "prompt" or "recast"
        self_repaired: bool,
        original_mistake: str = "",
        corrected_form: str = "",
        session_id: str = "",
    ) -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="correction_outcome",
            metric_value=1.0 if self_repaired else 0.0,
            metadata={
                "correction_type": correction_type,
                "self_repaired": self_repaired,
                "original": original_mistake,
                "better": corrected_form,
            },
            session_id=session_id,
            experiment_id="EXP001_CORRECTION_STYLE",
        )

    async def log_task_attempt(
        self,
        user_id: str,
        task_id: str,
        attempt_number: int,
        wpm: float,
        pause_count: int,
        filler_count: int,
        lexical_variety: float,
        session_id: str = "",
    ) -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="task_attempt",
            metric_value=wpm,
            metadata={
                "task_id": task_id,
                "attempt_number": attempt_number,
                "wpm": wpm,
                "pause_count": pause_count,
                "filler_count": filler_count,
                "lexical_variety": lexical_variety,
            },
            session_id=session_id,
            experiment_id="EXP002_TASK_REPETITION",
        )

    async def log_review_result(
        self,
        user_id: str,
        card_id: str,
        box: int,
        recalled_correctly: bool,
    ) -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="review_result",
            metric_value=1.0 if recalled_correctly else 0.0,
            metadata={
                "card_id": card_id,
                "box": box,
                "recalled_correctly": recalled_correctly,
            },
        )

    async def log_speaking_check(
        self,
        user_id: str,
        day_offset: int,  # 0, 7, 14
        score: float,
        cefr_level: str,
    ) -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="speaking_check_score",
            metric_value=score,
            metadata={
                "day_offset": day_offset,
                "score": score,
                "cefr_level": cefr_level,
            },
        )

    async def log_turn_cost(
        self,
        user_id: str,
        turn_id: str,
        cost_usd: float,
        stt_sec: float,
        tokens_in: int,
        tokens_out: int,
        tts_chars: int,
    ) -> str:
        return await self.log_event(
            user_id=user_id,
            event_name="cost_per_turn",
            metric_value=cost_usd,
            metadata={
                "turn_id": turn_id,
                "stt_sec": stt_sec,
                "tokens_in": tokens_in,
                "tokens_out": tokens_out,
                "tts_chars": tts_chars,
            },
        )


# Global service instance
experiments_service = ExperimentsService()
