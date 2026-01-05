# Threading Audit Results
**Date:** 2026-01-05  
**Status:** IN PROGRESS

This document records the threading safety audit for production readiness.

---

## Audit Criteria

### Critical Requirements
1. All `@Published` properties on UI-accessed classes must be on `@MainActor`
2. SwiftData fetches in hot paths must not block main thread
3. Background coordinators must not directly mutate `@Published` state
4. No race conditions in state management

---

## Findings

### 1. @MainActor Coverage

**Checked By:** `Scripts/check_threading_safety.sh`

#### Classes with @Published (State/)
- `AppModel.swift` → ❌ **Missing @MainActor**
- `AppSettingsModel.swift` → Status TBD
- `CoursesStore.swift` → Status TBD
- `AssignmentsStore.swift` → Status TBD
- `TimerPageViewModel.swift` → Status TBD
- `CalendarManager.swift` → Status TBD
- (Others TBD)

**Action Required:**
- Add `@MainActor` to `AppModel`
- Audit remaining State classes
- Verify all are either:
  - Annotated with `@MainActor`, OR
  - Deliberately isolated with documented concurrency design

---

### 2. SwiftData Query Patterns

**Manual Check Required:**

#### Hot Path Queries (Must Not Block Main)
- [ ] Dashboard data fetch on app launch
- [ ] Assignment list refresh
- [ ] Course list refresh
- [ ] Calendar event fetch
- [ ] Planner view queries

**Action Required:**
- Instrument app with Time Profiler
- Verify no main thread hangs on data fetch
- Add `nonisolated` or background queue patterns if needed

---

### 3. Background Coordinators

**Checked Manually:**

#### Coordinators with Async Operations
- `CalendarRefreshCoordinator` → Uses `Task` but mutates what?
- `PlannerSyncCoordinator` → Background scheduling, state updates?
- `DataIntegrityCoordinator` → Cascade operations blocking?

**Action Required:**
- Trace each coordinator's state mutation path
- Ensure background work uses `Task` or `DispatchQueue`
- Ensure UI updates go through `@MainActor` boundaries

---

### 4. Known Race Conditions

**None Identified Yet** (audit incomplete)

**To Check:**
- `AppModel.selectedPage` mutations (is access serialized?)
- `activeSemesterIds` Set mutations (concurrent access?)
- Timer state updates from background refresh

---

## Threading Rules (Established)

### Rule 1: UI State Must Be @MainActor
**All classes with `@Published` properties consumed by SwiftUI must be `@MainActor`.**

Rationale: SwiftUI expects state updates on main thread. Violating this causes crashes or rendering bugs.

### Rule 2: Heavy Work Must Be Isolated
**Disk I/O, network, decoding, and SwiftData fetches must not happen on main thread.**

Rationale: Blocks UI rendering, causes ANR (Application Not Responding).

### Rule 3: Background → Main Handoff
**Background work must explicitly hop to main thread before mutating `@Published` state.**

Pattern:
```swift
Task {
    let result = await heavyWork() // background
    await MainActor.run {
        self.state = result // main thread
    }
}
```

### Rule 4: No DispatchQueue.main in New Code
**Use async/await + @MainActor instead of legacy GCD patterns.**

Rationale: Better compile-time safety, easier to reason about.

---

## Verification Steps

### Automated
- [x] Run `Scripts/check_threading_safety.sh` (warnings found)
- [ ] Fix AppModel missing @MainActor
- [ ] Re-run script until clean

### Manual
- [ ] Instrument app with Time Profiler
- [ ] Launch app, navigate to each screen
- [ ] Check main thread time (should be <16ms per frame)
- [ ] Identify any blocking operations

### Testing
- [ ] Run app on slow device (simulate low performance)
- [ ] Check for UI freezes during data load
- [ ] Verify background tasks don't block UI

---

## Action Items

### CRITICAL (Must Fix Before Ship)
1. Add `@MainActor` to `AppModel` (15 min)
2. Audit all State/ classes for @MainActor (2 hours)
3. Instrument hot paths for main thread blocking (2 hours)

### HIGH (Should Fix Before Ship)
4. Document background coordinator concurrency design (1 hour)
5. Add threading assertions in critical paths (1 hour)
6. Test on low-end device (30 min)

### MEDIUM (Can Defer)
7. Migrate DispatchQueue.main to async/await (if time permits)
8. Add SwiftUI threading tests (future)

---

## Sign-Off

**Threading Audit Complete When:**
- [ ] All State classes with @Published are @MainActor or documented
- [ ] Time Profiler shows no main thread blocking
- [ ] Background coordinators documented
- [ ] Scripts pass without warnings

**Auditor:** [NAME]  
**Date:** [DATE]
