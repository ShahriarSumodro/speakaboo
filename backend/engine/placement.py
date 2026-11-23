"""
Placement and diagnostic engine for Speakaboo.

Estimates learner CEFR level (A1, A2, B1, B2) from a spoken diagnostic sample.
Evaluates:
- Vocabulary range & complexity
- Mean sentence length & clause indicators
- Speech pace / fluency (Words Per Minute)
- Accuracy indicators
"""

import re
from dataclasses import dataclass
from typing import Optional

# Common A1/A2 foundation words
A1_WORDS = {
    "i", "you", "he", "she", "it", "we", "they", "am", "is", "are", "was", "were",
    "have", "has", "had", "do", "does", "did", "will", "can", "the", "a", "an",
    "this", "that", "my", "your", "his", "her", "and", "but", "or", "yes", "no",
    "hello", "hi", "good", "bad", "big", "small", "go", "come", "see", "like",
    "want", "food", "water", "home", "family", "school", "friend", "happy", "day"
}

# Common B1/B2 transitional and complex words
B_LEVEL_INDICATORS = {
    "because", "although", "however", "therefore", "especially", "usually", "probably",
    "actually", "definitely", "frequently", "experience", "opportunity", "environment",
    "development", "improve", "decision", "opinion", "prefer", "consider", "explain",
    "describe", "suggest", "recommend", "participate", "achieve", "success", "future",
    "technology", "education", "community", "relationship", "comfortable", "confidence"
}


@dataclass
class PlacementResult:
    level: str  # "beginner", "intermediate", "advanced"
    cefr_level: str  # "A1", "A2", "B1", "B2"
    cefr_score: float  # 1.0 to 4.0
    wpm: float
    vocabulary_variety: float
    summary: str
    strengths: list[str]
    recommendations: list[str]


def evaluate_placement(spoken_text: str, duration_seconds: float = 30.0) -> PlacementResult:
    """Evaluate a spoken placement transcript.
    
    Args:
        spoken_text: Transcript of the learner's spoken response.
        duration_seconds: Duration of the audio in seconds.
        
    Returns:
        PlacementResult with estimated level and coaching advice.
    """
    clean_text = spoken_text.strip()
    words = re.findall(r"\b[a-zA-Z']+\b", clean_text.lower())
    total_words = len(words)

    # Empty or minimal speech
    if total_words < 4:
        return PlacementResult(
            level="beginner",
            cefr_level="A1",
            cefr_score=1.0,
            wpm=round((total_words / max(1.0, duration_seconds)) * 60.0, 1),
            vocabulary_variety=0.0,
            summary="You are at the start of your English journey (CEFR A1).",
            strengths=["Courage to speak and take the first step!"],
            recommendations=[
                "Practice saying short phrases with Reggie Rule Farmer.",
                "Build daily speaking habits with 2-minute talks.",
            ],
        )

    # Calculate metrics
    dur_min = max(0.1, duration_seconds / 60.0)
    wpm = round(total_words / dur_min, 1)
    unique_words = set(words)
    ttr = round(len(unique_words) / total_words, 2)  # Type-Token Ratio
    avg_word_len = round(sum(len(w) for w in words) / total_words, 2)

    # Sentences and clauses
    sentences = [s.strip() for s in re.split(r"[.!?]+", clean_text) if s.strip()]
    sentence_count = max(1, len(sentences))
    avg_sentence_len = round(total_words / sentence_count, 1)

    # B-level indicator count
    b_count = sum(1 for w in words if w in B_LEVEL_INDICATORS)

    # Calculate composite score (1.0 = A1, 2.0 = A2, 3.0 = B1, 4.0 = B2)
    score = 1.0

    # Length and pace score
    if total_words >= 35 and wpm >= 75:
        score += 1.0
    elif total_words >= 15 and wpm >= 45:
        score += 0.5

    # Complexity score
    if avg_sentence_len >= 10:
        score += 0.8
    elif avg_sentence_len >= 6:
        score += 0.4

    # Vocabulary sophistication score
    if b_count >= 3 or (avg_word_len >= 4.6 and ttr >= 0.7):
        score += 1.0
    elif b_count >= 1 or avg_word_len >= 4.1:
        score += 0.5

    # Cap score
    score = min(4.0, max(1.0, round(score, 1)))

    strengths = []
    recommendations = []

    if score < 1.8:
        level = "beginner"
        cefr = "A1"
        summary = "Beginner (CEFR A1): You can communicate basic ideas with simple words."
        strengths.append("Willingness to speak and express foundational thoughts.")
        recommendations.append("Focus on expanding daily conversational nouns and verbs.")
        recommendations.append("Practice short, clear answers with Reggie Rule Farmer.")
    elif score < 2.6:
        level = "beginner"
        cefr = "A2"
        summary = "Elementary (CEFR A2): You construct sentences on everyday familiar topics."
        strengths.append(f"Steady speaking pace ({wpm:.0f} WPM).")
        strengths.append("Able to link basic sentences together.")
        recommendations.append("Work on past tense consistency (e.g., went, had, saw).")
        recommendations.append("Try Roleplay Scenarios to practice real-world situations.")
    elif score < 3.4:
        level = "intermediate"
        cefr = "B1"
        summary = "Intermediate (CEFR B1): You speak comfortably on familiar topics and share opinions."
        strengths.append(f"Good conversational fluency ({wpm:.0f} WPM).")
        strengths.append("Expressive vocabulary with connecting words.")
        recommendations.append("Practice expressing complex opinions and reasoning.")
        recommendations.append("Converse with Kabir Chowdhury on solving mystery cases.")
    else:
        level = "advanced"
        cefr = "B2"
        summary = "Upper Intermediate (CEFR B2): You speak fluently with nuanced sentence structures."
        strengths.append(f"Natural speaking cadence ({wpm:.0f} WPM) and rich vocabulary.")
        strengths.append("Complex sentence formation with subordinate clauses.")
        recommendations.append("Debate abstract ideas and IELTS topics with Professor Anika.")
        recommendations.append("Fine-tune prepositions and natural idiomatic phrasing.")

    return PlacementResult(
        level=level,
        cefr_level=cefr,
        cefr_score=score,
        wpm=wpm,
        vocabulary_variety=ttr,
        summary=summary,
        strengths=strengths,
        recommendations=recommendations,
    )
