"""
Learning & Retention API routes.

Provides endpoints for gamification, daily missions, scenarios, topic mode,
shadowing evaluation, and spaced-repetition vocabulary notebook.
"""

from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from backend.repositories import get_repository
from backend.repositories.sqlite_repo import BaseRepository
from backend.engine.gamification import GamificationEngine
from backend.engine.missions import MissionsEngine
from backend.engine.scenarios import ScenarioEngine
from backend.engine.topics import TopicEngine
from backend.engine.shadowing import ShadowingEngine
from backend.engine.vocabulary import VocabularyEngine

router = APIRouter(prefix="/api/learning", tags=["learning"])

scenario_engine = ScenarioEngine()
topic_engine = TopicEngine()
shadowing_engine = ShadowingEngine()


class ProgressResponse(BaseModel):
    user_id: str
    xp: int
    level: int
    current_streak: int
    longest_streak: int
    last_active_date: str
    streak_freeze_count: int


class MissionResponse(BaseModel):
    id: str
    mission_id: str
    title: str
    description: str
    type: str
    target: float
    current_value: float
    xp_reward: int
    completed: bool
    reward_claimed: bool


class ClaimRewardResponse(BaseModel):
    success: bool
    xp_earned: int
    new_xp: int
    new_level: int


class ScenarioResponse(BaseModel):
    id: str
    title: str
    category: str
    description: str
    target_turns: int
    suggested_vocabulary: List[str]
    difficulty: str


class ShadowingScriptResponse(BaseModel):
    id: str
    title: str
    target_text: str
    target_wpm: int
    difficulty: str


class ShadowingEvaluateRequest(BaseModel):
    user_id: str
    script_id: str
    transcript: str
    duration_seconds: float


class ShadowingEvaluateResponse(BaseModel):
    script_id: str
    transcript: str
    accuracy_score: float
    pace_wpm: float
    pace_score: float
    overall_score: float
    missed_words: List[str]
    added_words: List[str]
    xp_earned: int


class VocabularyItemResponse(BaseModel):
    id: str
    word_or_phrase: str
    context_sentence: str
    correction_notes: str
    box: int
    next_review_date: str
    times_reviewed: int


class AddWordRequest(BaseModel):
    word_or_phrase: str
    context_sentence: str = ""
    correction_notes: str = ""


class ReviewWordRequest(BaseModel):
    remembered: bool


# --- Progress & Gamification ---

@router.get("/progress/{user_id}", response_model=ProgressResponse)
async def get_progress(user_id: str, repo: BaseRepository = Depends(get_repository)):
    """Get learner XP, level, and streak info."""
    engine = GamificationEngine(repo)
    p = await engine.get_progress(user_id)
    return ProgressResponse(
        user_id=p.user_id,
        xp=p.xp,
        level=p.level,
        current_streak=p.current_streak,
        longest_streak=p.longest_streak,
        last_active_date=p.last_active_date,
        streak_freeze_count=p.streak_freeze_count,
    )


@router.post("/freeze/{user_id}", response_model=ProgressResponse)
async def add_streak_freeze(user_id: str, repo: BaseRepository = Depends(get_repository)):
    """Add a streak freeze to the user's account."""
    engine = GamificationEngine(repo)
    p = await engine.use_streak_freeze(user_id)
    return ProgressResponse(
        user_id=p.user_id,
        xp=p.xp,
        level=p.level,
        current_streak=p.current_streak,
        longest_streak=p.longest_streak,
        last_active_date=p.last_active_date,
        streak_freeze_count=p.streak_freeze_count,
    )


# --- Daily Missions ---

@router.get("/missions/{user_id}", response_model=List[MissionResponse])
async def get_missions(user_id: str, repo: BaseRepository = Depends(get_repository)):
    """Get user's daily missions and progress."""
    engine = MissionsEngine(repo)
    missions = await engine.get_user_missions(user_id)
    return [MissionResponse(**m) for m in missions]


@router.post("/missions/{user_id}/claim/{mission_id}", response_model=ClaimRewardResponse)
async def claim_mission(user_id: str, mission_id: str, repo: BaseRepository = Depends(get_repository)):
    """Claim XP reward for completed mission."""
    engine = MissionsEngine(repo)
    xp = await engine.claim_reward(user_id, mission_id)
    if xp is None:
        raise HTTPException(status_code=400, detail="Mission not completed or reward already claimed")

    prog = await repo.get_progress(user_id)
    return ClaimRewardResponse(
        success=True,
        xp_earned=xp,
        new_xp=prog.xp,
        new_level=prog.level,
    )


# --- Scenarios ---

@router.get("/scenarios", response_model=List[ScenarioResponse])
async def list_scenarios():
    """List available real-life speaking scenario packs."""
    return [
        ScenarioResponse(
            id=s.id,
            title=s.title,
            category=s.category,
            description=s.description,
            target_turns=s.target_turns,
            suggested_vocabulary=s.suggested_vocabulary,
            difficulty=s.difficulty,
        )
        for s in scenario_engine.list_scenarios()
    ]


@router.get("/scenarios/{scenario_id}", response_model=ScenarioResponse)
async def get_scenario(scenario_id: str):
    """Get scenario details."""
    s = scenario_engine.get_scenario(scenario_id)
    if not s:
        raise HTTPException(status_code=404, detail="Scenario not found")
    return ScenarioResponse(
        id=s.id,
        title=s.title,
        category=s.category,
        description=s.description,
        target_turns=s.target_turns,
        suggested_vocabulary=s.suggested_vocabulary,
        difficulty=s.difficulty,
    )


@router.post("/scenarios/{scenario_id}/complete/{user_id}")
async def complete_scenario(scenario_id: str, user_id: str, repo: BaseRepository = Depends(get_repository)):
    """Mark scenario completed: awards XP and updates daily mission progress."""
    s = scenario_engine.get_scenario(scenario_id)
    if not s:
        raise HTTPException(status_code=404, detail="Scenario not found")

    gamification = GamificationEngine(repo)
    missions = MissionsEngine(repo)

    prog, xp_earned = await gamification.on_scenario_completed(user_id)
    await missions.track_scenario_completed(user_id)

    return {
        "status": "completed",
        "scenario_id": scenario_id,
        "xp_earned": xp_earned,
        "total_xp": prog.xp,
        "level": prog.level,
    }


# --- Topics ---

@router.get("/topics")
async def list_topics():
    """List conversation topics."""
    return topic_engine.list_topics()


@router.get("/topics/{topic_id}")
async def get_topic(topic_id: str):
    """Get topic details."""
    t = topic_engine.get_topic(topic_id)
    if not t:
        raise HTTPException(status_code=404, detail="Topic not found")
    return t


# --- Shadowing Mode ---

@router.get("/shadowing/scripts", response_model=List[ShadowingScriptResponse])
async def list_shadowing_scripts():
    """List original practice scripts for shadowing."""
    return [
        ShadowingScriptResponse(
            id=s.id,
            title=s.title,
            target_text=s.target_text,
            target_wpm=s.target_wpm,
            difficulty=s.difficulty,
        )
        for s in shadowing_engine.list_scripts()
    ]


@router.post("/shadowing/evaluate", response_model=ShadowingEvaluateResponse)
async def evaluate_shadowing(
    request: ShadowingEvaluateRequest, repo: BaseRepository = Depends(get_repository)
):
    """Evaluate shadowing attempt, score accuracy and pace, award XP."""
    try:
        eval_result = shadowing_engine.evaluate(
            script_id=request.script_id,
            transcript=request.transcript,
            duration_seconds=request.duration_seconds,
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    # Award XP and track mission
    gamification = GamificationEngine(repo)
    missions = MissionsEngine(repo)

    prog, xp_earned = await gamification.on_shadowing_completed(
        user_id=request.user_id, accuracy_score=eval_result.accuracy_score
    )
    await missions.track_shadowing_completed(request.user_id)

    return ShadowingEvaluateResponse(
        script_id=eval_result.script_id,
        transcript=eval_result.transcript,
        accuracy_score=eval_result.accuracy_score,
        pace_wpm=eval_result.pace_wpm,
        pace_score=eval_result.pace_score,
        overall_score=eval_result.overall_score,
        missed_words=eval_result.missed_words,
        added_words=eval_result.added_words,
        xp_earned=xp_earned,
    )


# --- Vocabulary Notebook ---

@router.get("/vocabulary/{user_id}", response_model=List[VocabularyItemResponse])
async def get_vocabulary(user_id: str, repo: BaseRepository = Depends(get_repository)):
    """Get user's vocabulary notebook items."""
    engine = VocabularyEngine(repo)
    items = await engine.get_notebook(user_id)
    return [
        VocabularyItemResponse(
            id=i.id,
            word_or_phrase=i.word_or_phrase,
            context_sentence=i.context_sentence,
            correction_notes=i.correction_notes,
            box=i.box,
            next_review_date=i.next_review_date,
            times_reviewed=i.times_reviewed,
        )
        for i in items
    ]


@router.get("/vocabulary/{user_id}/due", response_model=List[VocabularyItemResponse])
async def get_due_vocabulary(user_id: str, repo: BaseRepository = Depends(get_repository)):
    """Get vocabulary items due for review today."""
    engine = VocabularyEngine(repo)
    items = await engine.get_due_words(user_id)
    return [
        VocabularyItemResponse(
            id=i.id,
            word_or_phrase=i.word_or_phrase,
            context_sentence=i.context_sentence,
            correction_notes=i.correction_notes,
            box=i.box,
            next_review_date=i.next_review_date,
            times_reviewed=i.times_reviewed,
        )
        for i in items
    ]


@router.post("/vocabulary/{user_id}", response_model=VocabularyItemResponse)
async def add_vocabulary_word(
    user_id: str, request: AddWordRequest, repo: BaseRepository = Depends(get_repository)
):
    """Manually add a word or phrase to the vocabulary notebook."""
    engine = VocabularyEngine(repo)
    item = await engine.add_word(
        user_id=user_id,
        word_or_phrase=request.word_or_phrase,
        context_sentence=request.context_sentence,
        correction_notes=request.correction_notes,
    )
    return VocabularyItemResponse(
        id=item.id,
        word_or_phrase=item.word_or_phrase,
        context_sentence=item.context_sentence,
        correction_notes=item.correction_notes,
        box=item.box,
        next_review_date=item.next_review_date,
        times_reviewed=item.times_reviewed,
    )


@router.post("/vocabulary/{user_id}/review/{item_id}", response_model=VocabularyItemResponse)
async def review_vocabulary_word(
    user_id: str, item_id: str, request: ReviewWordRequest, repo: BaseRepository = Depends(get_repository)
):
    """Submit review result for a vocabulary item."""
    engine = VocabularyEngine(repo)
    item = await engine.review_word(item_id, request.remembered)
    if not item:
        raise HTTPException(status_code=404, detail="Vocabulary item not found")

    return VocabularyItemResponse(
        id=item.id,
        word_or_phrase=item.word_or_phrase,
        context_sentence=item.context_sentence,
        correction_notes=item.correction_notes,
        box=item.box,
        next_review_date=item.next_review_date,
        times_reviewed=item.times_reviewed,
    )
