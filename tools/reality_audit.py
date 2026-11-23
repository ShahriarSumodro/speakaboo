#!/usr/bin/env python3
"""
Reality Audit tool for Speakaboo codebase.
Scans app and backend code for mock strings, retired models, and hardcoded placeholders.
Exits with code 1 if any forbidden pattern is detected.
"""

import sys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Files or folders to exclude from scan
EXCLUDE_DIRS = {
    ".git",
    ".idea",
    ".dart_tool",
    "build",
    ".pytest_cache",
    "__pycache__",
    "venv",
    ".venv",
    "tools",
}

# Specific test files allowed to use mocks
TEST_EXCLUDE_FILES = [
    "widget_test.dart",
    "data_layer_test.dart",
    "test_e2e.py",
    "test_providers.py",
    "test_phase1_security_and_streaming.py",
    "test_gamification.py",
    "test_payment.py",
    "test_learning_modes.py",
    "test_parent_dashboard.py",
    "test_missions.py",
    "test_vocabulary.py",
    "test_characters.py",
    "test_conversation.py",
    "test_correction.py",
    "test_device_and_group_chat.py",
    "test_hardening.py",
    "test_health.py",
    "test_level.py",
    "test_repository.py",
    "test_safety.py",
    "test_config.py",
    "PROGRESS.md",
    "AUDIT_V2.md",
    "ARCHITECTURE.md",
    "README.md",
    "app/lib/config/app_config.dart",
    "tools/reality_audit.py",
    "reality_audit.py",
]

# Forbidden patterns: (regex, error_message, only_in_app)
FORBIDDEN_RULES = [
    (r"playai-tts", "Retired TTS model 'playai-tts' found! Use Orpheus v1.", False),
    (r"Arista-PlayAI", "Retired voice 'Arista-PlayAI' found! Use official Orpheus voices.", False),
    (r"llama-4-scout-17b", "Retired LLM model 'llama-4-scout' found! Use openai/gpt-oss-120b.", False),
    (r"Mock payment initiated", "Mock payment string found in production UI!", False),
    (r"MockClient\(", "MockClient found outside tests!", True),
    (r"http://10\.0\.2\.2", "Hardcoded emulator IP found! Use AppConfig or dynamic URL.", True),
]

def scan_files():
    violations = []
    
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
            
        parts = set(path.parts)
        if any(d in parts for d in EXCLUDE_DIRS):
            continue
            
        rel_path = path.relative_to(ROOT).as_posix()
        
        # Check if in allowed test / doc files
        if any(rel_path.endswith(f) for f in TEST_EXCLUDE_FILES):
            continue
            
        # Only check code files
        if not (path.suffix in [".dart", ".py", ".json", ".yaml"]):
            continue

        try:
            content = path.read_text(encoding="utf-8", errors="ignore")
        except Exception as e:
            continue
            
        for pattern, msg, only_in_app in FORBIDDEN_RULES:
            if only_in_app and not rel_path.startswith("app/lib/"):
                continue
            matches = re.finditer(pattern, content)
            for m in matches:
                # Find line number
                line_no = content[:m.start()].count("\n") + 1
                violations.append((rel_path, line_no, msg, m.group(0)))

    return violations

def main():
    print("Running Speakaboo Reality Audit...")
    violations = scan_files()
    
    if not violations:
        print("REALITY AUDIT PASSED: 0 violations detected.")
        return 0
        
    print(f"REALITY AUDIT FAILED: {len(violations)} violation(s) found:\n")
    for file, line, msg, match in violations:
        print(f"  [VIOLATION] {file}:{line} -> {msg} (matched: '{match}')")
        
    return 1

if __name__ == "__main__":
    sys.exit(main())
