"""
Shadowing mode engine for Speakaboo.

Compares user transcript to target script text.
Calculates:
1. Accuracy score (word error rate / Levenshtein overlap)
2. Pace (WPM) vs target WPM
3. Identifies missed words and extra words
Uses original practice scripts (no copyrighted dialogue).
"""

import json
import re
import logging
from pathlib import Path
from typing import List, Optional
from backend.models.learning import ShadowingScript, ShadowingEvaluation

logger = logging.getLogger("speakaboo.engine.shadowing")

SCRIPTS_FILE = Path(__file__).parent.parent / "data" / "shadowing_scripts.json"


def _clean_words(text: str) -> List[str]:
    """Extract lowercase words without punctuation."""
    return [w.lower() for w in re.findall(r"[a-zA-Z0-9']+", text) if w]


class ShadowingEngine:
    """Evaluates learner shadowing sessions against target scripts."""

    def __init__(self, scripts_path: Optional[Path] = None):
        self.path = scripts_path or SCRIPTS_FILE
        self._scripts: List[ShadowingScript] = []
        self._load()

    def _load(self) -> None:
        if not self.path.exists():
            logger.warning(f"Shadowing scripts file not found: {self.path}")
            return
        with open(self.path, "r", encoding="utf-8") as f:
            data = json.load(f)
            self._scripts = [
                ShadowingScript(
                    id=item["id"],
                    title=item["title"],
                    target_text=item["target_text"],
                    target_wpm=item.get("target_wpm", 120),
                    difficulty=item.get("difficulty", "beginner"),
                )
                for item in data
            ]

    def list_scripts(self) -> List[ShadowingScript]:
        """List available practice scripts."""
        return self._scripts

    def get_script(self, script_id: str) -> Optional[ShadowingScript]:
        """Get script by ID."""
        for s in self._scripts:
            if s.id == script_id:
                return s
        return None

    def evaluate(
        self, script_id: str, transcript: str, duration_seconds: float
    ) -> ShadowingEvaluation:
        """Evaluate a learner's spoken attempt against the target script.

        Args:
            script_id: ID of the script
            transcript: Transcribed text from user speech
            duration_seconds: How long user took to speak
        """
        script = self.get_script(script_id)
        if not script:
            raise ValueError(f"Script not found: {script_id}")

        target_words = _clean_words(script.target_text)
        user_words = _clean_words(transcript)

        if not target_words or not user_words:
            return ShadowingEvaluation(
                script_id=script_id,
                transcript=transcript,
                accuracy_score=0.0,
                pace_wpm=0.0,
                pace_score=0.0,
                overall_score=0.0,
                missed_words=list(dict.fromkeys(target_words))[:5],
                added_words=[],
                feedback="No matching speech detected. Let's try again — speak clearly into the mic.",
            )

        # 1. Word Accuracy Calculation
        target_counts = {}
        for w in target_words:
            target_counts[w] = target_counts.get(w, 0) + 1

        user_counts = {}
        for w in user_words:
            user_counts[w] = user_counts.get(w, 0) + 1

        matched_words = 0
        for w, count in user_counts.items():
            if w in target_counts:
                matched_words += min(count, target_counts[w])

        # Precision & Recall
        recall = matched_words / len(target_words)
        precision = matched_words / len(user_words) if user_words else 0.0

        # F1-like score scaled to 100
        if precision + recall > 0:
            accuracy_score = (2 * precision * recall) / (precision + recall) * 100.0
        else:
            accuracy_score = 0.0

        # Find missed and added words
        missed = [w for w in target_words if w not in user_counts]
        added = [w for w in user_words if w not in target_counts]

        # 2. Pace (WPM) based on matched words & clamped to [0, 300]
        effective_duration = max(1.0, duration_seconds)
        if matched_words > 0:
            raw_wpm = (matched_words / effective_duration) * 60.0
            pace_wpm = min(300.0, max(0.0, raw_wpm))
        else:
            pace_wpm = 0.0

        # Target pace comparison (only award pace points if learner matched some passage words)
        target_wpm = script.target_wpm
        if accuracy_score >= 25.0 and target_wpm > 0 and pace_wpm > 0:
            diff_ratio = abs(pace_wpm - target_wpm) / target_wpm
            pace_score = max(0.0, 100.0 - (diff_ratio * 100.0))
        else:
            pace_score = 0.0

        overall_score = round(0.7 * accuracy_score + 0.3 * pace_score, 1)

        if accuracy_score < 50.0:
            feedback = "Let's try again! Listen to the companion voice and match the words in the passage."
        elif accuracy_score < 85.0:
            feedback = "Good effort! Practice the highlighted words and keep a steady pace."
        else:
            feedback = "Great job! Your pronunciation and rhythm matched the passage well."

        return ShadowingEvaluation(
            script_id=script_id,
            transcript=transcript,
            accuracy_score=round(accuracy_score, 1),
            pace_wpm=round(pace_wpm, 1),
            pace_score=round(pace_score, 1),
            overall_score=overall_score,
            missed_words=list(dict.fromkeys(missed))[:5],  # Unique, up to 5
            added_words=list(dict.fromkeys(added))[:5],
            feedback=feedback,
        )
