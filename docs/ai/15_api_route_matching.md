# Spec 15: App API Client Route Matching (`app/lib/services/api_service.dart`)

## Purpose
Ensures every HTTP endpoint called by Flutter `ApiService` matches a real route and schema on FastAPI `backend/routes/*.py`.

## Rules & Invariants
1. Every URL constructed in `ApiService` must exist in `backend/routes/*.py` with matching HTTP method and path parameter placement.
2. All 9 previously mismatched routes (`getStreak`, `freezeStreak`, `claimMission`, `addVocabulary`, `reviewVocabulary`, `getParentSummary`, `getSafetyFlags`, `getUsage`, `getParentalConsent`) are aligned with backend routes (`Mismatches: 0`).
