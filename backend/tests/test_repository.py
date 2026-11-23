"""
Tests for the repository layer.
"""

import pytest
import os
import tempfile

from backend.repositories.sqlite_repo import SqliteRepository, dhaka_today
from backend.models.user import User, Plan, DailyUsage, Entitlement, MistakeLog


@pytest.fixture
async def repo():
    """Create a temporary SQLite repository."""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    r = SqliteRepository(path)
    await r.initialize()
    yield r
    await r.close()
    os.unlink(path)


class TestUserRepository:

    @pytest.mark.asyncio
    async def test_create_and_get_user(self, repo):
        user = User(device_id="device-123", display_name="Test User")
        await repo.create_user(user)

        found = await repo.get_user(user.id)
        assert found is not None
        assert found.device_id == "device-123"
        assert found.plan == Plan.FREE

    @pytest.mark.asyncio
    async def test_get_user_by_device(self, repo):
        user = User(device_id="device-456")
        await repo.create_user(user)

        found = await repo.get_user_by_device("device-456")
        assert found is not None
        assert found.id == user.id

    @pytest.mark.asyncio
    async def test_update_user(self, repo):
        user = User(device_id="device-789")
        await repo.create_user(user)

        user.display_name = "Updated Name"
        user.plan = Plan.BASIC
        await repo.update_user(user)

        found = await repo.get_user(user.id)
        assert found.display_name == "Updated Name"
        assert found.plan == Plan.BASIC


class TestUsageRepository:

    @pytest.mark.asyncio
    async def test_increment_usage(self, repo):
        user = User(device_id="d-usage")
        await repo.create_user(user)

        usage = await repo.increment_usage(user.id, 2.5)
        assert usage.minutes_spoken == 2.5
        assert usage.turns_count == 1

        # Increment again
        usage2 = await repo.increment_usage(user.id, 1.0)
        assert usage2.minutes_spoken == 3.5
        assert usage2.turns_count == 2

    @pytest.mark.asyncio
    async def test_get_daily_usage(self, repo):
        user = User(device_id="d-daily")
        await repo.create_user(user)

        await repo.increment_usage(user.id, 5.0)
        usage = await repo.get_daily_usage(user.id)
        assert usage is not None
        assert usage.minutes_spoken == 5.0


class TestMistakeLog:

    @pytest.mark.asyncio
    async def test_log_mistake(self, repo):
        user = User(device_id="d-mistakes")
        await repo.create_user(user)

        mistake = MistakeLog(
            user_id=user.id,
            category="grammar",
            original="I goes",
            better="I go",
        )
        await repo.log_mistake(mistake)

        mistakes = await repo.get_mistakes(user.id)
        assert len(mistakes) == 1
        assert mistakes[0].original == "I goes"

    @pytest.mark.asyncio
    async def test_duplicate_mistake_increments_count(self, repo):
        user = User(device_id="d-dup")
        await repo.create_user(user)

        mistake1 = MistakeLog(user_id=user.id, original="I goes", better="I go")
        await repo.log_mistake(mistake1)

        mistake2 = MistakeLog(user_id=user.id, original="I goes", better="I go")
        result = await repo.log_mistake(mistake2)
        assert result.count == 2


def test_dhaka_today_format():
    """dhaka_today returns YYYY-MM-DD format."""
    today = dhaka_today()
    assert len(today) == 10
    assert today[4] == "-"
    assert today[7] == "-"
