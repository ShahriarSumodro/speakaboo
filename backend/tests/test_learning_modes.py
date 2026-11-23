"""
Tests for Scenarios, Topics, and Shadowing Modes.
"""

import pytest
from backend.engine.scenarios import ScenarioEngine
from backend.engine.topics import TopicEngine
from backend.engine.shadowing import ShadowingEngine


def test_scenarios_loaded():
    engine = ScenarioEngine()
    scenarios = engine.list_scenarios()
    assert len(scenarios) >= 5
    ids = [s.id for s in scenarios]
    assert "job_interview" in ids
    assert "ielts_speaking_part_2" in ids
    assert "ordering_food" in ids
    assert "talking_to_foreigner" in ids
    assert "school_presentation" in ids

    item = engine.get_scenario("job_interview")
    assert item is not None
    assert item.difficulty in ("beginner", "intermediate", "advanced")
    assert len(item.suggested_vocabulary) > 0


def test_topics_loaded():
    engine = TopicEngine()
    topics = engine.list_topics()
    assert len(topics) >= 3
    ids = [t["id"] for t in topics]
    assert "weather_monsoon" in ids
    assert "global_warming" in ids

    item = engine.get_topic("global_warming")
    assert "strictly neutral" in item["prompt_context"].lower()


class TestShadowingEngine:

    def test_scripts_loaded(self):
        engine = ShadowingEngine()
        scripts = engine.list_scripts()
        assert len(scripts) >= 3
        ids = [s.id for s in scripts]
        assert "script_morning_market" in ids
        assert "script_study_habits" in ids

    def test_perfect_shadowing_evaluation(self):
        engine = ShadowingEngine()
        script = engine.get_script("script_morning_market")
        assert script is not None

        # Say exact target text in expected duration
        eval_res = engine.evaluate(
            script_id=script.id,
            transcript=script.target_text,
            duration_seconds=12.0,
        )

        assert eval_res.accuracy_score >= 95.0
        assert eval_res.overall_score >= 80.0
        assert len(eval_res.missed_words) == 0

    def test_imperfect_shadowing_identifies_missed_words(self):
        engine = ShadowingEngine()
        script = engine.get_script("script_morning_market")

        eval_res = engine.evaluate(
            script_id=script.id,
            transcript="Early every morning the town bazaar is crowded",
            duration_seconds=5.0,
        )

        assert eval_res.accuracy_score < 80.0
        assert len(eval_res.missed_words) > 0
        assert "fresh" in eval_res.missed_words or "harvest" in eval_res.missed_words
