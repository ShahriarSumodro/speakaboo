# Spec 02: Correction Logic (`backend/engine/correction.py`)

## Purpose
Parses and validates the LLM's JSON turn output into `TurnResponse` and `Correction`, enforcing:
1. Extraction of JSON from markdown fences or surrounding prose (`_extract_json`).
2. Basic JSON repair for trailing commas, unquoted keys, or single-quoted JSON (`_repair_json`).
3. Required `reply` field; replies >200 chars are truncated at sentence boundaries (or 200 chars hard cap).
4. Single-focus error guard: if LLM returns `corrections` list, pick the single highest-priority mistake according to `PEDAGOGICAL_ERROR_PRIORITY`:
   `tenses_and_verbs` (1) > `subject_verb_agreement` (2) > `prepositions` (3) > `articles` (4) > `word_choice` (5).
5. Error categorization (`categorize_error`) inspects `reason` keywords first, then *changed/differing* words between `original` and `better` (so unchanged prepositions like `"to"` in `"I went to a park"` -> `"I went to the park"` do not shadow article errors).
6. `feedback_level` defaults to `"gentle"` if invalid.

## Invariants
- Never raises on valid or repairable JSON with non-empty `reply`; raises `ValueError` on unparseable JSON or missing `reply`.
- At most one `Correction` is attached to a `TurnResponse`.
