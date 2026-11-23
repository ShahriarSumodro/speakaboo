"""
Privacy Policy, Parental Consent, and Data Deletion routes for Speakaboo.

Adheres strictly to Hard Rule 6 (Kid Safety) and Child Privacy regulations:
- Raw audio is NEVER stored.
- No personal identifying information (school, phone, address) is collected.
- Immediate, complete data deletion on request.
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Any

from backend.repositories import get_repository
from backend.repositories.sqlite_repo import BaseRepository
from backend.engine.auth_token import get_current_user_id, verify_user_access

router = APIRouter(prefix="/api/privacy", tags=["privacy"])


class DeleteDataResponse(BaseModel):
    user_id: str
    status: str
    message: str


PRIVACY_POLICY_TEXT = """
# Speakaboo Privacy Policy

Last updated: November 2026

At Speakaboo, the safety and privacy of young learners is our highest commitment.

## 1. No Voice Audio Storage
We respect the voice privacy of children and students. Spoken audio transmitted to Speakaboo is processed in real-time memory strictly for transcription and speech scoring. We do NOT save, store, or sell raw audio recordings of your child.

## 2. No Personal Data Collection
Speakaboo operates on anonymous, device-based accounts by default. Our companions and our systems will NEVER ask a child for:
- Home address or location
- School name or grade
- Phone number or parent's phone number
- Social media profiles or photos

## 3. Child Safety Filters
Every word spoken by learners and characters passes through our strict safety filter. Any inappropriate, harmful, violent, or sensitive topic is immediately redirected with friendly, age-appropriate guidance.

## 4. Full Data Deletion & Parental Rights
Parents and guardians have the absolute right to view learner activity and request immediate, irreversible deletion of all learner progress, vocabulary, and stats at any time through the Parent Dashboard or via DELETE /api/privacy/user/{user_id}.

## 5. Contact
For privacy inquiries or parental support: privacy@speakaboo.app
"""

PARENTAL_CONSENT_TEXT = """
# Speakaboo Parental Consent Agreement

By allowing your child to practice spoken English with Speakaboo, you acknowledge and agree that:
1. Speakaboo uses artificial intelligence companions strictly for spoken English practice and constructive grammar feedback.
2. Voice inputs are processed live in-memory for speech-to-text transcription and immediately discarded.
3. You have access to the Parent Dashboard to monitor practice minutes, streaks, vocabulary learned, and safety moderation summaries.
4. You may request complete deletion of your child's learning records at any time.
"""


@router.get("/policy")
async def get_privacy_policy() -> Dict[str, str]:
    """Retrieve full Speakaboo privacy policy."""
    return {
        "title": "Speakaboo Privacy Policy",
        "last_updated": "2026-11-23",
        "content_markdown": PRIVACY_POLICY_TEXT.strip(),
    }


@router.get("/parental-consent")
async def get_parental_consent() -> Dict[str, str]:
    """Retrieve parental consent agreement text."""
    return {
        "title": "Speakaboo Parental Consent Agreement",
        "content_markdown": PARENTAL_CONSENT_TEXT.strip(),
    }


@router.get("/export/{user_id}")
async def export_user_data(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
) -> Dict[str, Any]:
    """Export complete learner data archive for data portability (GDPR/COPPA compliance)."""
    verify_user_access(current_user_id, user_id)
    user = await repo.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    profile = await repo.get_profile(user_id)
    progress = await repo.get_progress(user_id)
    vocab = await repo.get_vocabulary(user_id)
    summary = await repo.get_parent_summary(user_id)
    flags = await repo.get_safety_flags(user_id)

    return {
        "user": {
            "id": user.id,
            "created_at": user.created_at,
            "plan": user.plan.value if hasattr(user.plan, "value") else str(user.plan),
        },
        "profile": profile.__dict__ if profile else None,
        "progress": progress.__dict__ if progress else None,
        "vocabulary_count": len(vocab),
        "vocabulary": [v.__dict__ for v in vocab],
        "weekly_summary": summary,
        "safety_flags": [f.__dict__ for f in flags],
        "raw_audio_stored": False,
        "data_retention_policy": "Zero raw audio stored. Learner owns all data.",
    }


@router.delete("/user/{user_id}", response_model=DeleteDataResponse)
async def delete_user_account_and_data(
    user_id: str,
    repo: BaseRepository = Depends(get_repository),
    current_user_id: str = Depends(get_current_user_id),
) -> DeleteDataResponse:
    """
    Completely and irreversibly purge all learner data:
    user profile, conversation history, turn transcripts, gamification progress,
    missions, vocabulary notebook, mistakes, and safety logs.
    """
    verify_user_access(current_user_id, user_id)
    user = await repo.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    await repo.delete_user_data(user_id)

    return DeleteDataResponse(
        user_id=user_id,
        status="purged",
        message="All user data, transcripts, vocabulary, and progress have been permanently deleted.",
    )
