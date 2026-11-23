"""
Tests for Phase 1: Measurement Foundation.
- Experiments Service & Stable User Hash Bucketing
- Event Logging Across SLA Metrics
- Simulated 14-Day Cohort Producing Correct Numbers in Both Reports
- Sample Size Reliability & Plain-Language Warning Checks
"""

import pytest
import tempfile
import os
import time

from backend.models.user import User
from backend.repositories.sqlite_repo import SqliteRepository, dhaka_today, dhaka_date_add
from backend.repositories import set_repository
from backend.engine.experiments import ExperimentsService, EXPERIMENTS_REGISTRY
from backend.scripts.experiments_report import generate_experiments_report
from backend.scripts.retention_report import generate_retention_report


@pytest.fixture
async def repo():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    r = SqliteRepository(path)
    await r.initialize()
    set_repository(r)
    yield r
    await r.close()
    if os.path.exists(path):
        os.unlink(path)


@pytest.mark.asyncio
async def test_stable_deterministic_variant_bucketing(repo):
    """User assignment is deterministic, persistent in SQLite, and evenly distributed."""
    service = ExperimentsService(repo)

    # 1. Same user always gets the same variant
    v1 = await service.get_variant("user-abc-1", "EXP001_CORRECTION_STYLE")
    v2 = await service.get_variant("user-abc-1", "EXP001_CORRECTION_STYLE")
    assert v1 == v2
    assert v1 in ("prompts_first", "recast_first")

    # 2. Check persistence in SQLite
    saved = await repo.get_experiment_assignment("user-abc-1", "EXP001_CORRECTION_STYLE")
    assert saved == v1

    # 3. Multiple users are distributed across variants
    assigned_variants = set()
    for i in range(20):
        v = await service.get_variant(f"user-dist-{i}", "EXP001_CORRECTION_STYLE")
        assigned_variants.add(v)
    assert len(assigned_variants) == 2  # Both variants assigned


@pytest.mark.asyncio
async def test_analytics_event_logging(repo):
    """Pedagogical and operational events are recorded with proper metadata."""
    service = ExperimentsService(repo)

    # Log session length
    eid1 = await service.log_session_length("user-metric-1", duration_seconds=185.5, session_id="s-101")
    assert eid1 is not None

    # Log correction outcome
    eid2 = await service.log_correction_outcome(
        user_id="user-metric-1",
        correction_type="prompt",
        self_repaired=True,
        original_mistake="he go yesterday",
        corrected_form="he went yesterday",
        session_id="s-101",
    )
    assert eid2 is not None

    # Log task repetition metrics
    eid3 = await service.log_task_attempt(
        user_id="user-metric-1",
        task_id="market_story",
        attempt_number=2,
        wpm=115.0,
        pause_count=3,
        filler_count=1,
        lexical_variety=0.68,
        session_id="s-101",
    )
    assert eid3 is not None

    # Log speaking check score
    eid4 = await service.log_speaking_check(
        user_id="user-metric-1",
        day_offset=7,
        score=78.5,
        cefr_level="B1",
    )
    assert eid4 is not None

    # Verify query
    events = await repo.get_analytics_events(user_id="user-metric-1")
    assert len(events) == 4
    names = [e["event_name"] for e in events]
    assert "session_length" in names
    assert "correction_outcome" in names
    assert "task_attempt" in names
    assert "speaking_check_score" in names

    corr_event = next(e for e in events if e["event_name"] == "correction_outcome")
    assert corr_event["metadata"]["self_repaired"] is True
    assert corr_event["experiment_id"] == "EXP001_CORRECTION_STYLE"


@pytest.mark.asyncio
async def test_simulated_14_day_cohort_and_reports(repo):
    """A simulated 14-day cohort generates correct retention and experiments metrics."""
    service = ExperimentsService(repo)
    start_date = "2026-11-01"

    # Simulate 40 users in a 14-day cohort
    # Group 1 (30 users): assigned to prompts_first
    # Group 2 (10 users): assigned to recast_first (small sample < 30)
    for i in range(40):
        uid = f"cohort-u-{i:02d}"
        u = User(id=uid, device_id=f"dev-{uid}", created_at=time.time())
        await repo.create_user(u)

        # Force assignment for deterministic sample size validation
        variant = "prompts_first" if i < 30 else "recast_first"
        await repo.record_experiment_assignment(uid, "EXP001_CORRECTION_STYLE", variant)

        # Day 0 activity
        await repo.increment_usage(uid, minutes=5.0, date=start_date)

        # Log correction outcome event
        await service.log_event(
            user_id=uid,
            event_name="correction_outcome",
            metric_value=1.0 if (i % 2 == 0) else 0.0,
            metadata={"self_repaired": (i % 2 == 0)},
            experiment_id="EXP001_CORRECTION_STYLE",
            variant=variant,
        )

        # Day 1 return for 25 users (62.5% D1 retention)
        if i < 25:
            d1_date = dhaka_date_add(1, from_date=start_date)
            await repo.increment_usage(uid, minutes=4.0, date=d1_date)

        # Day 7 return for 15 users (37.5% D7 retention)
        if i < 15:
            d7_date = dhaka_date_add(7, from_date=start_date)
            await repo.increment_usage(uid, minutes=6.0, date=d7_date)

    # 1. Run retention report
    ret_report = generate_retention_report(repo.db_path)
    assert ret_report["total_users"] == 40
    assert ret_report["total_speaking_minutes"] > 0
    assert ret_report["minutes_per_active_day"] > 0
    assert "sessions_per_week" in ret_report
    assert ret_report["day_1_retention_pct"] > 50.0  # ~62.5%
    assert ret_report["day_7_retention_pct"] > 30.0  # ~37.5%

    # 2. Run experiments report
    exp_report = generate_experiments_report(repo.db_path)
    assert "EXP001_CORRECTION_STYLE" in exp_report["experiments"]
    exp1 = exp_report["experiments"]["EXP001_CORRECTION_STYLE"]

    # prompts_first has N=30 -> reliable sample
    assert "prompts_first" in exp1["variants"]
    pf = exp1["variants"]["prompts_first"]
    assert pf["sample_size"] == 30
    assert pf["is_sample_reliable"] is True
    assert "Statistically adequate" in pf["sample_warning"]
    assert "correction_outcome" in pf["metrics"]

    # recast_first has N=10 -> underpowered, shows plain-language warning
    assert "recast_first" in exp1["variants"]
    rf = exp1["variants"]["recast_first"]
    assert rf["sample_size"] == 10
    assert rf["is_sample_reliable"] is False
    assert "Sample size too small" in rf["sample_warning"]
    assert "directional hypotheses only" in rf["sample_warning"]


@pytest.mark.asyncio
async def test_cascade_deletion_removes_experiments_and_events(repo):
    """Deleting user data completely purges experiment assignments and analytics events."""
    service = ExperimentsService(repo)
    uid = "u-purge-test"
    u = User(id=uid, device_id="dev-purge", created_at=time.time())
    await repo.create_user(u)

    await service.get_variant(uid, "EXP001_CORRECTION_STYLE")
    await service.log_session_length(uid, 120.0)

    # Verify they exist
    assert await repo.get_experiment_assignment(uid, "EXP001_CORRECTION_STYLE") is not None
    events_before = await repo.get_analytics_events(user_id=uid)
    assert len(events_before) == 1

    # Delete user
    deleted = await repo.delete_user_data(uid)
    assert deleted is True

    # Verify purged
    assert await repo.get_experiment_assignment(uid, "EXP001_CORRECTION_STYLE") is None
    events_after = await repo.get_analytics_events(user_id=uid)
    assert len(events_after) == 0
