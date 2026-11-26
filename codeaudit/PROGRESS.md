# Code Truth Loop — Progress

## Status: Phase 2 — Core Logic Audit

## Phase Checklist
- [x] Phase 0: Baseline (create state files, verify_all.ps1, run baseline, fix broken tests)
- [x] Phase 1: Map the codebase (inventory, dependency graph, dead code, big files, smells)
- [ ] Phase 2: Core logic audit (16 units, specs, tests, verdicts)
- [ ] Phase 3: Clean-code refactor (split big files, fix smells, one commit per refactor)
- [ ] Phase 4: Architecture handoff pack (AGENTS.md, docs/*)
- [ ] Phase 5: Prove docs match code (check_docs.py, handoff test)
- [ ] Phase 6: Guard rails (linting, layering tests)
- [ ] Phase 7: Final re-check (all tests green, all docs current)

## Current Task
Phase 0: Creating state files and baseline verification script.

## NEXT ACTION
Run baseline checks (backend pytest, dart analyze, flutter test).

## Module Table (Phase 2)
| # | Unit | Spec | Tests | Verdict | Evidence |
|---|------|------|-------|---------|----------|
| 1 | Conversation turn pipeline | - | - | - | - |
| 2 | Correction logic | - | - | - | - |
| 3 | Safety filter | - | - | - | - |
| 4 | Providers STT/AI/TTS | - | - | - | - |
| 5 | Auth + tokens | - | - | - | - |
| 6 | Entitlements + caps | - | - | - | - |
| 7 | Streaks/XP/levels/missions | - | - | - | - |
| 8 | Vocabulary + spaced repetition | - | - | - | - |
| 9 | Shadowing scoring | - | - | - | - |
| 10 | Payments + billing | - | - | - | - |
| 11 | Parent dashboard + privacy | - | - | - | - |
| 12 | Retention + experiments | - | - | - | - |
| 13 | Database layer | - | - | - | - |
| 14 | App state machines | - | - | - | - |
| 15 | App API client route matching | - | - | - | - |
| 16 | Config + secrets | - | - | - | - |
