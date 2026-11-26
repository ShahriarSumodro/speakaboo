# Speakaboo — Change Checklist

Before committing any change:
- [ ] Does it obey layer boundaries? (`engine`/`models`/`repositories`/`providers` do not import `routes`; Flutter `models`/`services` do not import `material.dart`)
- [ ] Are there zero mocks in non-test product code? (Mocks only in `tests/` or gated by `TEST_MODE=true`)
- [ ] Are all exceptions logged or surfaced? (No `except: pass` or `catch (_) {}`)
- [ ] If you added/changed a backend route or `ApiService` method, did you run `scripts/check_docs.py`?
- [ ] Did you add/update tests for the new or fixed behavior?
- [ ] Does `powershell -ExecutionPolicy Bypass -File scripts/verify_all.ps1` pass?
