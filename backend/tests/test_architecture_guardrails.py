"""
Architecture and code-truth guard rail tests.

Enforces layer boundaries, zero swallowed errors, and doc/API parity.
"""

import ast
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def test_backend_layering_boundaries():
    """engine/, models/, repositories/, and providers/ must never import backend.routes."""
    violations = []
    for layer in ("engine", "models", "repositories", "providers"):
        layer_dir = REPO_ROOT / "backend" / layer
        for py_file in layer_dir.rglob("*.py"):
            if "__pycache__" in py_file.parts:
                continue
            tree = ast.parse(py_file.read_text(encoding="utf-8"))
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        if alias.name.startswith("backend.routes"):
                            violations.append(f"{py_file.name}:{node.lineno} imports {alias.name}")
                elif isinstance(node, ast.ImportFrom):
                    if node.module and node.module.startswith("backend.routes"):
                        violations.append(f"{py_file.name}:{node.lineno} imports {node.module}")
    assert not violations, f"Backend layering violations: {violations}"


def test_flutter_layering_boundaries():
    """app/lib/models/ and app/lib/services/ must never import package:flutter/material.dart."""
    violations = []
    for layer in ("models", "services"):
        layer_dir = REPO_ROOT / "app" / "lib" / layer
        for dart_file in layer_dir.rglob("*.dart"):
            text = dart_file.read_text(encoding="utf-8")
            if "package:flutter/material.dart" in text:
                violations.append(str(dart_file.relative_to(REPO_ROOT)))
    assert not violations, f"Flutter layering violations: {violations}"


def test_no_swallowed_dart_catches():
    """Ensure zero empty catch (_) {} blocks exist in app/lib/."""
    violations = []
    for dart_file in (REPO_ROOT / "app" / "lib").rglob("*.dart"):
        for idx, line in enumerate(dart_file.read_text(encoding="utf-8").splitlines(), 1):
            if re.search(r"catch\s*\([^)]*\)\s*\{\s*\}", line):
                violations.append(f"{dart_file.relative_to(REPO_ROOT)}:{idx}")
    assert not violations, f"Swallowed catch blocks found: {violations}"


def test_docs_and_route_parity():
    """Run scripts/check_docs.py checks programmatically."""
    import sys
    sys.path.insert(0, str(REPO_ROOT / "scripts"))
    import check_docs
    assert check_docs.main() == 0
