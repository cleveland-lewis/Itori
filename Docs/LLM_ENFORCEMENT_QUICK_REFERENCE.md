# LLM Enforcement — Quick Reference

## The Invariant (Memorize This)

```
IF enableLLMAssistance == false
THEN providerAttemptCountTotal MUST == 0
```

**Always. No exceptions.**

---

## For Developers

### ✅ DO:
- Read `Docs/Architecture/LLM_ENFORCEMENT_INVARIANT.md` before touching AI code
- Use `AIEngine.request(...)` for all AI operations
- Add tests for new ports (toggle OFF → fallback)
- Run `LLMToggleEnforcementTests` after AI changes
- Implement `supportsDeterministicFallback` for new ports

### ❌ DON'T:
- Call `provider.execute(...)` directly (bypass engine)
- Remove or move the toggle check in `_executeWithGuards`
- Import provider implementations outside `AIEngine`
- Skip testing toggle OFF behavior

---

## For Reviewers

### Check These in Every PR:

1. **Invariant comment intact?**
   - Location: `AIEngine._executeWithGuards` (lines ~67-89)
   - Should say "CRITICAL SYSTEM INVARIANT"

2. **Toggle check BEFORE provider selection?**
   - Toggle check must be FIRST thing in execution path
   - No provider logic before `if !enableLLMAssistance { ... }`

3. **New ports have tests?**
   - Test toggle OFF → uses fallback
   - Test toggle OFF → 0 provider attempts

4. **CI passing?**
   - `LLMToggleEnforcementTests` must pass
   - Static analysis must pass

---

## For QA

### Before Every Release:

1. Build Release
2. Disable toggle (Settings → Privacy → "Enable LLM Assistance" = OFF)
3. Use app heavily (30+ minutes, all AI features)
4. Check Developer Settings → LLM Call Counter:
   - **Provider Attempts: MUST BE 0**
   - Suppressed: > 0
   - Fallback-Only: > 0
5. If Provider Attempts > 0: **STOP. DO NOT SHIP.**

See: `Docs/PRODUCTION_VERIFICATION_CHECKLIST_LLM.md`

---

## If Tests Fail

### CI Fails:
1. Read workflow logs (detailed diagnostics)
2. Check `AIEngine._executeWithGuards` (lines ~67-117)
3. Verify toggle check is FIRST
4. Fix bug, push, re-run CI

### DEBUG Build Crashes:
1. Read assertion message (detailed diagnostics)
2. Check call stack → find where provider was called
3. Verify enforcement gate was bypassed
4. Fix bug, test again

### Production Checklist Fails:
1. **DO NOT SHIP**
2. File P0 bug
3. Run `LLMToggleEnforcementTests` locally
4. Debug with instrumented build
5. Fix, re-test, re-run checklist

---

## Key Files

| File | Purpose |
|------|---------|
| `Docs/Architecture/LLM_ENFORCEMENT_INVARIANT.md` | Canonical docs |
| `SharedCore/AIEngine/Core/AIEngine.swift` | Enforcement gate |
| `Tests/LLMToggleEnforcementTests.swift` | Test suite |
| `.github/workflows/llm-enforcement.yml` | CI workflow |
| `Docs/PRODUCTION_VERIFICATION_CHECKLIST_LLM.md` | QA checklist |

---

## Enforcement Layers

1. **Code Gate** — Toggle check in `_executeWithGuards`
2. **DEBUG Canary** — Assertion before `provider.execute()`
3. **CI Tests** — Automated suite (build-blocking)
4. **Static Analysis** — Checks for violations
5. **Health Monitor** — Runtime counters (observable)
6. **Audit Log** — Event provenance (traceable)
7. **QA Checklist** — Manual verification (release gate)

---

## Common Mistakes

| Mistake | Impact | Detection |
|---------|--------|-----------|
| Moved toggle check | Providers called | CI fails |
| Direct provider call | Bypassed gate | Static analysis warns |
| No fallback | Crash on toggle OFF | Tests fail |
| Race condition | Intermittent calls | DEBUG canary fires |
| Missing test | Regression risk | CI doesn't catch |

---

## Debug Commands

```bash
# Run enforcement tests locally
xcodebuild test -scheme Itori -destination 'platform=macOS' \
  -only-testing:ItoriTests/LLMToggleDisablesProviderAttemptsTests

# Check for unauthorized imports
grep -r "import.*Provider" --include="*.swift" \
  --exclude-dir="AIEngine" --exclude-dir="Tests" SharedCore/

# Verify toggle check exists
grep -n "enableLLMAssistance" SharedCore/AIEngine/Core/AIEngine.swift
```

---

## Get Help

- **Questions?** Read `Docs/Architecture/LLM_ENFORCEMENT_INVARIANT.md`
- **Bug?** Check DEBUG canary output, run tests
- **PR blocked?** Review CI logs, fix violations
- **Release blocked?** Run QA checklist, debug counters

---

**This guarantee is permanent. Respect the invariant.**
