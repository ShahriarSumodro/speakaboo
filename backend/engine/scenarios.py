"""
Scenario engine for Speakaboo.

Loads real-life scenario packs from data and formats scenario contexts.
"""

import json
import logging
from pathlib import Path
from typing import List, Optional
from backend.models.learning import Scenario

logger = logging.getLogger("speakaboo.engine.scenarios")

SCENARIOS_FILE = Path(__file__).parent.parent / "data" / "scenarios.json"


class ScenarioEngine:
    """Manages real-life conversational scenarios."""

    def __init__(self, scenarios_path: Optional[Path] = None):
        self.path = scenarios_path or SCENARIOS_FILE
        self._scenarios: List[Scenario] = []
        self._load()

    def _load(self) -> None:
        if not self.path.exists():
            logger.warning(f"Scenarios file not found: {self.path}")
            return
        with open(self.path, "r", encoding="utf-8") as f:
            data = json.load(f)
            self._scenarios = [
                Scenario(
                    id=item["id"],
                    title=item["title"],
                    category=item.get("category", "General"),
                    description=item.get("description", ""),
                    prompt_context=item.get("prompt_context", ""),
                    target_turns=item.get("target_turns", 5),
                    suggested_vocabulary=item.get("suggested_vocabulary", []),
                    difficulty=item.get("difficulty", "intermediate"),
                )
                for item in data
            ]

    def list_scenarios(self) -> List[Scenario]:
        """Return all loaded scenarios."""
        return self._scenarios

    def get_scenario(self, scenario_id: str) -> Optional[Scenario]:
        """Get scenario by ID."""
        for s in self._scenarios:
            if s.id == scenario_id:
                return s
        return None
