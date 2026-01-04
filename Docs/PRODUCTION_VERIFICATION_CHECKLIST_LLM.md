# LLM Enforcement — Production Verification Checklist

## Purpose
This checklist verifies that the LLM kill-switch invariant holds in production builds.

**Invariant:** `IF enableLLMAssistance == false THEN providerAttemptCountTotal MUST == 0`

**Run this checklist before every release.**

---

## Checklist

### 1. Build Release Configuration

```bash
cd /path/to/Itori
xcodebuild -scheme Itori -configuration Release build
```

- [ ] Build succeeds without errors
- [ ] Build warnings reviewed and acceptable
- [ ] Release optimizations enabled

---

### 2. Launch App in Release Mode

- [ ] Launch the Release build (not Debug)
- [ ] Verify app launches successfully
- [ ] Navigate to Settings

---

### 3. Disable LLM Toggle

**Location:** Settings → Privacy → "Enable LLM Assistance"

- [ ] Toggle "Enable LLM Assistance" to **OFF**
- [ ] Verify toggle visually shows OFF state
- [ ] App does not crash or show errors

---

### 4. Heavy App Usage (30+ minutes)

Perform all AI-enabled operations multiple times:

#### Assignments
- [ ] Create 10+ assignments with various types
- [ ] Edit assignment details
- [ ] Mark assignments complete/incomplete
- [ ] Delete assignments

#### Planner
- [ ] Trigger planner scheduling (multiple times)
- [ ] Add/remove calendar events
- [ ] Modify planner horizon settings
- [ ] Force re-schedule

#### Document Ingestion (if applicable)
- [ ] Upload syllabus documents
- [ ] Parse PDFs
- [ ] Extract assignment data

#### Timer & Focus
- [ ] Start/stop timer sessions
- [ ] Complete Pomodoro cycles
- [ ] Review study analytics

#### Navigation
- [ ] Visit every major page (Dashboard, Calendar, Assignments, Courses, Planner, Practice, Timer, Settings)
- [ ] Trigger quick actions
- [ ] Use search (if applicable)

---

### 5. Open Developer Settings

**Location:** Settings → Developer → "LLM Call Counter"

- [ ] Developer settings accessible
- [ ] LLM Call Counter view loads

---

### 6. Verify Counters

**CRITICAL: These values MUST match expectations**

```
Expected Values (Toggle OFF):
- Provider Attempts Total: 0
- Suppressed by Toggle: > 0
- Fallback-Only Count: > 0
```

**Actual Values:**
- Provider Attempts Total: ________
- Suppressed by Toggle: ________
- Fallback-Only Count: ________

#### ❌ If Provider Attempts > 0:
```
STOP. DO NOT SHIP THIS BUILD.

This is a critical privacy bug. The LLM kill-switch is broken.

Action Required:
1. File a P0 bug
2. Review AIEngine._executeWithGuards
3. Run LLMToggleEnforcementTests locally
4. Fix the issue
5. Re-run this checklist from step 1
```

#### ✅ If Provider Attempts == 0:
- [ ] Continue to step 7

---

### 7. Check Console Logs

Open Console.app or Xcode Console and filter for the app.

**Should NOT appear:**
- `"Calling provider..."`
- `"Provider response..."`
- `"Network request to..."`
- `"Attempting LLM provider..."`
- Any provider names (OpenAI, Anthropic, Apple Intelligence, etc.)

**Should appear:**
- `"LLM suppressed by toggle"`
- `"Using fallback"`
- `"Fallback-only execution"`

- [ ] No provider/network logs found
- [ ] Suppression logs present
- [ ] Fallback logs present

---

### 8. Enable LLM Toggle (Positive Control)

**Toggle "Enable LLM Assistance" to ON**

- [ ] Perform 5+ AI operations (assignments, planner, etc.)
- [ ] Open LLM Call Counter
- [ ] Verify Provider Attempts > 0 now (proves system works when ON)

**Actual Values (Toggle ON):**
- Provider Attempts Total: ________ (should be > 0 if providers available)

- [ ] System behaves correctly when toggle is ON

---

### 9. Re-Disable Toggle (Final Verification)

**Toggle "Enable LLM Assistance" to OFF again**

- [ ] Reset counters (if available) OR note current values
- [ ] Perform 5+ AI operations
- [ ] Verify Provider Attempts remains at previous value (no new attempts)

---

### 10. Test Across Platforms (if applicable)

Repeat steps 2-7 on:

- [ ] macOS (if applicable)
- [ ] iOS iPhone
- [ ] iOS iPad
- [ ] All supported OS versions

---

### 11. Sign-Off

**Tester Name:** ___________________________  
**Date:** ___________________________  
**Release Version:** ___________________________  

**Result:**
- [ ] ✅ PASS - All checks passed, LLM kill-switch works correctly
- [ ] ❌ FAIL - Kill-switch broken, DO NOT SHIP

**Notes:**
```
(Add any observations, edge cases, or issues found)
```

---

## What If Tests Fail?

### Failure Scenarios

1. **Provider Attempts > 0 when toggle OFF:**
   - **Severity:** P0 Critical Bug
   - **Action:** DO NOT SHIP, file bug, fix immediately
   - **Root Cause:** Kill-switch in `AIEngine._executeWithGuards` is bypassed

2. **Suppression Count == 0 when toggle OFF:**
   - **Severity:** P0 Critical Bug
   - **Action:** Kill-switch not recording suppressions correctly
   - **Root Cause:** Health monitor not being called

3. **App crashes when toggle OFF:**
   - **Severity:** P0 Critical Bug
   - **Action:** Fallback implementations missing or broken
   - **Root Cause:** Ports require fallback implementation

4. **Console shows provider logs when toggle OFF:**
   - **Severity:** P1 High Priority
   - **Action:** Review logging infrastructure
   - **Root Cause:** Logging happens before kill-switch check

### Debug Steps

1. Run `LLMToggleEnforcementTests` locally:
   ```bash
   xcodebuild test -scheme Itori -destination 'platform=macOS' \
     -only-testing:ItoriTests/LLMToggleDisablesProviderAttemptsTests
   ```

2. Enable DEBUG canary in Development build:
   - Build with DEBUG configuration
   - Disable toggle
   - Trigger AI operation
   - Check for assertion failures

3. Review audit log:
   - Export audit log from developer settings
   - Filter for `eventType == .providerAttempt` with `reasonCode == .llmDisabled`
   - Should find ZERO entries

---

## References

- **Invariant Documentation:** `Docs/Architecture/LLM_ENFORCEMENT_INVARIANT.md`
- **Test Suite:** `Tests/LLMToggleEnforcementTests.swift`
- **Implementation:** `SharedCore/AIEngine/Core/AIEngine.swift` (lines ~67-117)
- **CI Workflow:** `.github/workflows/llm-enforcement.yml`

---

## History

| Date | Tester | Version | Result | Notes |
|------|--------|---------|--------|-------|
| 2025-12-30 | Initial | - | - | Checklist created |
|  |  |  |  |  |
|  |  |  |  |  |

---

**This checklist is mandatory for every release.**
