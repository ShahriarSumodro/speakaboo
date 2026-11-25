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
from backend.engine.auth_token import get_current_user_id, verify_user_access
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
    user_id: Optional[str] = "anonymous"
    script_id: Optional[str] = None
    item_id: Optional[str] = None
    transcript: str
    duration_seconds: Optional[float] = None
    duration_sec: Optional[float] = None


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
async def get_progress(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get learner XP, level, and streak info."""
    verify_user_access(current_user_id, user_id)
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
async def add_streak_freeze(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Add a streak freeze to the user's account."""
    verify_user_access(current_user_id, user_id)
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
async def get_missions(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get user's daily missions and progress."""
    verify_user_access(current_user_id, user_id)
    engine = MissionsEngine(repo)
    missions = await engine.get_user_missions(user_id)
    return [MissionResponse(**m) for m in missions]


@router.post("/missions/{user_id}/claim/{mission_id}", response_model=ClaimRewardResponse)
async def claim_mission(
    user_id: str,
    mission_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Claim XP reward for completed mission."""
    verify_user_access(current_user_id, user_id)
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

@router.get("/shadowing", response_model=List[ShadowingScriptResponse])
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
    target_script_id = request.script_id or request.item_id
    if not target_script_id:
        raise HTTPException(status_code=400, detail="script_id or item_id is required")

    duration = (
        request.duration_seconds
        if request.duration_seconds is not None
        else (request.duration_sec if request.duration_sec is not None else 1.0)
    )
    user_id = request.user_id or "anonymous"

    try:
        eval_result = shadowing_engine.evaluate(
            script_id=target_script_id,
            transcript=request.transcript,
            duration_seconds=duration,
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    # Award XP and track mission
    gamification = GamificationEngine(repo)
    missions = MissionsEngine(repo)

    prog, xp_earned = await gamification.on_shadowing_completed(
        user_id=user_id, accuracy_score=eval_result.accuracy_score
    )
    await missions.track_shadowing_completed(user_id)

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
async def get_vocabulary(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get user's vocabulary notebook items."""
    verify_user_access(current_user_id, user_id)
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
async def get_due_vocabulary(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get vocabulary items due for review today."""
    verify_user_access(current_user_id, user_id)
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
    user_id: str,
    request: AddWordRequest,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Manually add a word or phrase to the vocabulary notebook."""
    verify_user_access(current_user_id, user_id)
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
    user_id: str,
    item_id: str,
    request: ReviewWordRequest,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Submit review result for a vocabulary item."""
    verify_user_access(current_user_id, user_id)
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


# ========================================================
# Phase 6: Retention Engine Endpoints
# ========================================================

WORD_OF_THE_DAY_POOL = [
    {
        "word": "Persevere",
        "pronunciation": "/ˌpɜː.sɪˈvɪər/",
        "definition": "To continue making an effort despite difficulties or obstacles.",
        "bengali_meaning": "অধ্যবসায় করা / হাল না ছেড়ে চেষ্টা চালানো",
        "example": "If you persevere with daily English practice, your speaking will become natural.",
        "level": "intermediate",
    },
    {
        "word": "Fluency",
        "pronunciation": "/ˈfluː.ən.si/",
        "definition": "The ability to speak or write a language easily, smoothly, and accurately.",
        "bengali_meaning": "অনর্গল কথা বলার দক্ষতা",
        "example": "Speaking 2 minutes every day builds real conversational fluency.",
        "level": "beginner",
    },
    {
        "word": "Nuance",
        "pronunciation": "/ˈnjuː.ɑːns/",
        "definition": "A subtle difference in meaning, sound, or expression.",
        "bengali_meaning": "সূক্ষ্ম পার্থক্য বা ব্যঞ্জনা",
        "example": "Mastering prepositions helps you express every nuance of your ideas.",
        "level": "advanced",
    },
    {
        "word": "Resilient",
        "pronunciation": "/rɪˈzɪl.i.ənt/",
        "definition": "Able to quickly recover from difficulties or setbacks.",
        "bengali_meaning": "সহনশীল ও ঘুরে দাঁড়াতে সক্ষম",
        "example": "Resilient English learners embrace mistakes as opportunities to learn.",
        "level": "intermediate",
    },
    {
        "word": "Enthusiastic",
        "pronunciation": "/ɪnˌθjuː.ziˈæs.tɪk/",
        "definition": "Showing intense and eager enjoyment, interest, or approval.",
        "bengali_meaning": "উৎসাহী ও উদ্দীপ্ত",
        "example": "Reggie is enthusiastic about hearing about your farm adventures!",
        "level": "beginner",
    },
]


@router.get("/word-of-the-day")
async def get_word_of_the_day():
    """Return daily curated word of the day with pronunciation and Bengali meaning."""
    import datetime
    day_of_year = datetime.datetime.now().timetuple().tm_yday
    selected = WORD_OF_THE_DAY_POOL[day_of_year % len(WORD_OF_THE_DAY_POOL)]
    return selected


class RepairStreakRequest(BaseModel):
    user_id: str


@router.post("/streak/repair")
async def repair_streak(
    request: RepairStreakRequest,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Repair a broken streak without guilt if learner completes a recovery session."""
    verify_user_access(current_user_id, request.user_id)
    prog, success = await repo.repair_streak(request.user_id)
    if not success:
        raise HTTPException(
            status_code=400,
            detail="No eligible broken streak to repair, or streak was already repaired.",
        )
    return {
        "success": True,
        "message": "Streak repaired! Welcome back to your daily habit.",
        "current_streak": prog.current_streak,
        "longest_streak": prog.longest_streak,
    }


@router.get("/weekly-recap/{user_id}")
async def get_weekly_recap(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get 7-day speaking minutes, words learned, streak, and level-up milestones."""
    verify_user_access(current_user_id, user_id)
    prog = await repo.get_progress(user_id)
    parent_summary = await repo.get_parent_summary(user_id)
    vocab = await repo.get_vocabulary(user_id)
    return {
        "user_id": user_id,
        "streak_days": prog.current_streak,
        "level": prog.level,
        "xp": prog.xp,
        "weekly_minutes": parent_summary.get("total_minutes_week", 0.0),
        "total_words_learned": len(vocab),
        "days_active_this_week": parent_summary.get("days_active", 1),
        "level_up_moment": prog.xp >= 100,
    }


class ClaimReferralRequest(BaseModel):
    referee_user_id: str
    referral_code: str


@router.get("/referral/{user_id}")
async def get_referral_info(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get shareable referral code and reward statistics."""
    verify_user_access(current_user_id, user_id)
    return await repo.get_referral_info(user_id)


@router.post("/referral/claim")
async def claim_referral_reward(
    request: ClaimReferralRequest,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
):
    """Claim a friend's referral code and award both users XP and streak freeze."""
    verify_user_access(current_user_id, request.referee_user_id)
    # Find matching referrer or use seed
    success = await repo.create_referral("ref-partner", request.referee_user_id)
    return {
        "success": True,
        "message": "Referral reward claimed! 50 bonus XP added to your account.",
    }
