# LLM Enforcement Invariant

## Status: CRITICAL SYSTEM INVARIANT

This document defines the **canonical, non-negotiable invariant** for LLM provider usage in Roots.

---

## The Invariant

```
IF enableLLMAssistance == false
THEN providerAttemptCountTotal MUST == 0
```

### In Plain English:
**When the "Enable LLM Assistance" toggle is OFF, zero LLM provider attempts may occur.**

This includes:
- No provider availability checks beyond initialization
- No provider `execute(...)` calls
- No network requests to LLM services
- No attempt to route requests to providers

**Only deterministic fallbacks may execute.**

---

## Why This Invariant Exists

### User Guarantee
Users who disable LLM assistance receive an **absolute guarantee**:
- No data leaves their device to LLM providers
- No AI models are queried
- No usage is metered or logged by external services
- Only local, deterministic algorithms run

This is not a preference—it's a **privacy contract**.

### Regulatory Compliance
- GDPR: Users can opt out of AI processing entirely
- CCPA: No data sharing with third parties when disabled
- Educational institutions: Some require AI to be fully disabled

### Safety Critical
- In production: Silent fallback, no unexpected AI failures
- In development: Loud failure, immediate detection of violations

---

## Where Enforcement Happens

### Single Enforcement Point
**Location:** `SharedCore/AIEngine/Core/AIEngine.swift`
**Method:** `_executeWithGuards<P: AIPort>(...)`
**Lines:** ~67-100

```swift
private func _executeWithGuards<P: AIPort>(
    portType: P.Type,
    input: P.Input,
    context: AIRequestContext
) async throws -> AIResult<P.Output> {
    /// INVARIANT:
    /// If enableLLMAssistance == false,
    /// providerAttemptCount MUST remain 0.
    /// Any violation is a critical bug.
    
    if !AppSettingsModel.shared.enableLLMAssistance {
        // KILL-SWITCH PATH: Skip all provider logic
        // Record suppression
        // Execute fallback-only
        // No provider selection, no network
        ...
    }
    
    // ... provider logic only if toggle is ON
}
```

**This is the ONLY place where the toggle is checked for enforcement.**

---

## How CI Guarantees It

### Test Suite: `Tests/LLMToggleEnforcementTests.swift`

**Tests prove:**
1. Toggle OFF → `providerAttemptCountTotal == 0` (always)
2. Toggle OFF → `suppressedByLLMToggleCount > 0`
3. Toggle OFF → All results have provenance `.fallback`
4. Toggle OFF → No `providerAttempt` audit events
5. Stress test: 100+ requests, still 0 attempts

**CI Configuration:** See `.github/workflows/llm-enforcement.yml`
- Tests run on every commit (pre-merge)
- Failures are **build-blocking** (not flaky, not retryable)
- No PR can merge if these tests fail

### Runtime Canary (DEBUG-Only)
**Location:** `SharedCore/AIEngine/Core/AIEngine.swift` (within provider execution path)

```swift
#if DEBUG
// Canary: Assert if invariant violated at runtime
if !AppSettingsModel.shared.enableLLMAssistance {
    let total = await AIEngine.healthMonitor.getLLMCounters().providerAttemptCountTotal
    assert(total == 0, """
        INVARIANT VIOLATION:
        LLM toggle is OFF but providerAttemptCount = \(total)
        This is a critical bug. Check AIEngine._executeWithGuards.
        """)
}
#endif
```

This catches violations during development **before they reach production**.

---

## Provider Entry Point Restrictions

### Provider Protocol
**Location:** `SharedCore/AIEngine/Providers/Provider.swift`

```swift
public protocol AIEngineProvider: Sendable {
    func execute(port: AIPortID, inputJSON: Data, context: AIRequestContext) 
        async throws -> (outputJSON: Data, diagnostic: AIDiagnostic)
}
```

**Rules:**
1. Providers are `internal` or restricted in scope
2. Only `AIEngine._executeWithGuards` may call `provider.execute(...)`
3. No feature, view, or service may bypass the engine

**Enforcement:**
- Architecture review enforces this
- Any direct provider import outside `AIEngine` is flagged
- CI can check for unauthorized imports (grep-based rule)

---

## Observable Behavior

### Health Monitor
**Location:** `SharedCore/AIEngine/Core/HealthMonitor.swift`

Counters always available (dev-only UI):
```swift
public struct LLMProviderCounters {
    var providerAttemptCountTotal: Int = 0
    var suppressedByLLMToggleCount: Int = 0
    var fallbackOnlyCount: Int = 0
    ...
}
```

**Invariant validation:**
```
IF enableLLMAssistance == false:
  EXPECT:
    providerAttemptCountTotal == 0
    suppressedByLLMToggleCount > 0
    fallbackOnlyCount > 0
```

### Audit Log
**Location:** `SharedCore/AIEngine/Core/AIAuditLog.swift`

Every request logs:
```swift
struct AIAuditEntry {
    let eventType: EventType  // .suppressed, .providerAttempt, .fallback
    let reasonCode: ReasonCode // .llmDisabled, .success, .error
    let providerID: String?    // nil if suppressed
    let fallbackUsed: Bool
    ...
}
```

**Invariant validation:**
- Filter by `eventType == .suppressed`
- Filter by `reasonCode == .llmDisabled`
- Ensure NO `eventType == .providerAttempt` when toggle is OFF

---

## Production Verification Checklist

Before each release:

### 1. Build Release Configuration
```bash
xcodebuild -scheme Roots -configuration Release build
```

### 2. Disable LLM Toggle
In Settings → Privacy → "Enable LLM Assistance" = OFF

### 3. Heavy App Usage (30+ minutes)
- Create 10+ assignments
- Run planner scheduling
- Upload/ingest documents
- Navigate all major pages
- Trigger every AI-enabled feature

### 4. Verify Counters
Open Developer Settings → LLM Call Counter

**MUST show:**
```
Provider Attempts Total: 0
Suppressed by Toggle: > 0
Fallback-Only Count: > 0
```

**If Provider Attempts > 0 → DO NOT SHIP. Critical bug.**

### 5. Check Console Logs
No provider/network logs should appear:
```
# Should NOT appear:
"Calling provider..."
"Provider response..."
"Network request to..."
```

---

## Regression Prevention

### What Could Break the Invariant?

1. **New port bypasses engine:** Direct provider call
   - **Prevention:** Architecture review, CI grep checks
   
2. **Refactor moves toggle check:** Toggle check removed or moved after provider selection
   - **Prevention:** Test suite fails immediately
   
3. **Async race condition:** Provider called before toggle check completes
   - **Prevention:** Toggle check is synchronous, early in execution path
   
4. **Provider called during init:** Provider availability check at startup
   - **Prevention:** Availability checks are metadata-only (no execute)

### How to Maintain

- **Never remove** the toggle check in `_executeWithGuards`
- **Always run** `LLMToggleEnforcementTests` in CI
- **Review carefully** any changes to:
  - `AIEngine._executeWithGuards`
  - `AIPortRegistry` (port routing)
  - Provider implementations
- **Add tests** for new ports that verify toggle OFF → fallback

---

## Summary

**The invariant is:**
```
enableLLMAssistance == false ⟹ providerAttemptCountTotal == 0
```

**This is enforced by:**
1. Single kill-switch gate in `_executeWithGuards`
2. CI-blocking test suite (`LLMToggleEnforcementTests`)
3. DEBUG-only runtime canary (assertion)
4. Observable counters (Health Monitor)
5. Audit log (provenance tracking)

**This is documented in:**
- This file (canonical reference)
- Code comments (implementation notes)
- Test file (behavioral spec)

**This is verified by:**
- Automated tests (every commit)
- Manual checklist (every release)
- Runtime monitoring (every execution)

**If violated:**
- CI fails (pre-merge)
- DEBUG builds assert (development)
- Production silently uses fallback (no user impact, but observable)

**This guarantee is permanent and non-negotiable.**

---

## References

- Implementation: `SharedCore/AIEngine/Core/AIEngine.swift` (~L67-100)
- Tests: `Tests/LLMToggleEnforcementTests.swift`
- Monitoring: `SharedCore/AIEngine/Core/HealthMonitor.swift`
- Audit: `SharedCore/AIEngine/Core/AIAuditLog.swift`
- Counter UI: `SharedCore/Views/LLMCallCounterView.swift`
- CI Workflow: `.github/workflows/llm-enforcement.yml`

---

**Last Updated:** 2025-12-30
**Owner:** AI Engine Team
**Reviewers:** Privacy Team, Security Team
