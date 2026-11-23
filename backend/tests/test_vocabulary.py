"""
Tests for Vocabulary Notebook and Spaced Repetition (Leitner boxes).
"""

import pytest
import tempfile
import os
from backend.repositories.sqlite_repo import (
    SqliteRepository, dhaka_today, dhaka_date_add,
)
from backend.engine.vocabulary import VocabularyEngine


@pytest.fixture
async def repo():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    r = SqliteRepository(path)
    await r.initialize()
    yield r
    await r.close()
    os.unlink(path)


@pytest.fixture
def engine(repo):
    return VocabularyEngine(repo)


class TestVocabularyEngine:

    @pytest.mark.asyncio
    async def test_add_word_and_deduplicate(self, engine):
        item1 = await engine.add_word("u1", "Harvest", context_sentence="Reggie reaps the harvest.")
        assert item1.word_or_phrase == "harvest"
        assert item1.box == 1

        # Adding same word returns existing
        item2 = await engine.add_word("u1", "HARVEST")
        assert item1.id == item2.id

    @pytest.mark.asyncio
    async def test_add_from_turn_captures_words_and_corrections(self, engine):
        items = await engine.add_from_turn(
            user_id="u2",
            new_words=["monsoon", "fertile"],
            correction={"original": "I goes", "better": "I went", "reason_short": "past tense"},
            context_sentence="I went to the fertile land during monsoon.",
        )
        assert len(items) == 3
        words = [i.word_or_phrase for i in items]
        assert "monsoon" in words
        assert "fertile" in words
        assert any("i went" in w.lower() for w in words)

    @pytest.mark.asyncio
    async def test_review_advances_box_on_success(self, engine):
        item = await engine.add_word("u3", "consistent")
        assert item.box == 1

        # Successful review -> Box 2
        reviewed = await engine.review_word(item.id, remembered=True)
        assert reviewed.box == 2
        assert reviewed.times_reviewed == 1

        # Successful review -> Box 3
        reviewed3 = await engine.review_word(item.id, remembered=True)
        assert reviewed3.box == 3

    @pytest.mark.asyncio
    async def test_review_resets_box_on_lapse(self, engine):
        item = await engine.add_word("u4", "ephemeral")
        await engine.review_word(item.id, remembered=True)  # Box 2
        await engine.review_word(item.id, remembered=True)  # Box 3

        # Forgotten -> Reset to Box 1
        lapsed = await engine.review_word(item.id, remembered=False)
        assert lapsed.box == 1

    @pytest.mark.asyncio
    async def test_due_words_retrieval(self, engine, repo):
        item = await engine.add_word("u5", "diligent")
        
        # Next review is tomorrow by default
        due_today = await engine.get_due_words("u5", date=dhaka_today())
        # Today it's not due yet
        assert len(due_today) == 0

        # On tomorrow's date it should be due
        tomorrow = dhaka_date_add(1)
        due_tomorrow = await engine.get_due_words("u5", date=tomorrow)
        assert len(due_tomorrow) == 1
        assert due_tomorrow[0].word_or_phrase == "diligent"
