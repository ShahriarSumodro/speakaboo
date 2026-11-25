# Command Stalls Log

| Timestamp | Command | Duration Before Kill | Suspected Block / Cause | Mitigation |
|---|---|---|---|---|
| 2026-11-25 11:01 | `cd app; flutter analyze --no-pub` | >120s | Standard sandbox restrictions on accessing external Flutter/Dart SDK binaries and caches | Run unsandboxed (BypassSandbox: true) with explicit process timeout |
| 2026-11-25 10:54 | `pytest backend/tests/test_characters.py` (sandboxed) | >30s | NameError ('os' missing) masked by ProactorEventLoop named-pipe block in sandbox | Added `import os` and run with BypassSandbox: true |
