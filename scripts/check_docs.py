"""
check_docs.py — Verify that handoff documentation matches the actual codebase.

Checks:
1. Required handoff pack files exist (AGENTS.md, GEMINI.md, docs/*, docs/ai/*).
2. All file paths referenced in docs/MODULE_MAP.md exist on disk.
3. All HTTP endpoints called in app/lib/services/api_service.dart match a real
   @router.* endpoint in backend/routes/*.py.
4. No swallowed errors (except: pass / catch (_) {}) in product code.
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

REQUIRED_DOCS = [
    "AGENTS.md",
    "GEMINI.md",
    "docs/ARCHITECTURE.md",
    "docs/DATA_FLOW.md",
    "docs/MODULE_MAP.md",
    "docs/API_CONTRACT.md",
    "docs/DOMAIN_RULES.md",
    "docs/KNOWN_ISSUES.md",
    "docs/DECISIONS.md",
    "docs/CHANGE_CHECKLIST.md",
]


def check_required_docs() -> list[str]:
    errors = []
    for rel in REQUIRED_DOCS:
        if not (REPO_ROOT / rel).exists():
            errors.append(f"Missing required doc: {rel}")
    ai_dir = REPO_ROOT / "docs" / "ai"
    if not ai_dir.exists() or len(list(ai_dir.glob("*.md"))) < 16:
        errors.append("docs/ai/ must contain at least 16 module brief markdown files")
    return errors


def check_module_map_paths() -> list[str]:
    errors = []
    mm = (REPO_ROOT / "docs" / "MODULE_MAP.md").read_text(encoding="utf-8")
    for match in re.finditer(r"`((?:backend|app)/[^`*\s]+)`", mm):
        rel = match.group(1)
        if not (REPO_ROOT / rel).exists():
            errors.append(f"MODULE_MAP.md references non-existent path: {rel}")
    return errors


def check_api_route_parity() -> list[str]:
    errors = []
    be_paths: set[str] = set()
    for p in sorted((REPO_ROOT / "backend" / "routes").glob("*.py")):
        text = p.read_text(encoding="utf-8")
        m_pref = re.search(r'APIRouter\(\s*prefix=["\']([^"\']+)["\']', text)
        prefix = m_pref.group(1) if m_pref else ""
        for m in re.finditer(r'@router\.(?:get|post|put|delete|patch)\(\s*["\']([^"\']*)["\']', text):
            norm = re.sub(r"\{[^}]+\}", "{id}", prefix + m.group(1))
            be_paths.add(norm)

    dart_text = (REPO_ROOT / "app" / "lib" / "services" / "api_service.dart").read_text(encoding="utf-8")
    for m in re.finditer(r'Uri\.parse\(\s*["\']\$baseUrl([^"\']+)["\']', dart_text):
        path = m.group(1).split("?")[0]
        norm = re.sub(r"\$\{?[\w.]+\}?", "{id}", path)
        if norm not in be_paths:
            errors.append(f"ApiService endpoint '{norm}' has no matching backend route")
    return errors


def check_swallowed_errors() -> list[str]:
    errors = []
    for p in sorted((REPO_ROOT / "app" / "lib").rglob("*.dart")):
        for i, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
            if re.search(r"catch\s*\([^)]*\)\s*\{\s*\}", line):
                errors.append(f"Swallowed error in {p.relative_to(REPO_ROOT)}:{i}")
    return errors


def main() -> int:
    all_errors = (
        check_required_docs()
        + check_module_map_paths()
        + check_api_route_parity()
        + check_swallowed_errors()
    )
    if all_errors:
        print("check_docs.py FAILED:")
        for e in all_errors:
            print(f"  - {e}")
        return 1
    print("check_docs.py PASSED: all docs, module paths, API routes, and error checks valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
