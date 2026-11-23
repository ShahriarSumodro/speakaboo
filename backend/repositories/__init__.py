"""
Backend repositories package with repository singleton getter.
"""

from typing import Optional
from backend.repositories.sqlite_repo import SqliteRepository, BaseRepository

_repo: Optional[BaseRepository] = None


async def get_repository() -> BaseRepository:
    """Get or initialize the shared repository instance."""
    global _repo
    if _repo is None:
        _repo = SqliteRepository("speakaboo.db")
        await _repo.initialize()
    return _repo


def set_repository(repo: BaseRepository) -> None:
    """Set the repository instance (e.g. for testing)."""
    global _repo
    _repo = repo
