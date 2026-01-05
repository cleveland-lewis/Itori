# Production Readiness Audit
**Date:** 2026-01-05  
**Scope:** Workflow → Cohesion → UI → Production Prep

---

## Executive Summary

**Current State:** Mid-transition. Core workflows traced, cohesion partially verified, UI behaviors inconsistent.  
**Blockers:** 47 TODOs in production code, incomplete threading audit, no layout stress tests, empty states undefined.  
**Distance to Production:** 2-3 weeks of hardening work, not 2-3 days.

---

## 1. WORKFLOW (Traceability)

### ✅ Traceable Flows
- **Add Assignment:** User input → AssignmentsStore → Persistence → Dashboard render
- **Soft Delete Cascade:** Course deletion → DataIntegrityCoordinator → related tasks soft-deleted
- **Timer Start:** UI button → TimerPageViewModel → FocusManager → state update

### ⚠️ Partially Traced
- **Auto-Scheduling:** PlannerEngine exists, but LLM fallback path unclear (AIEngine → where?)
- **Calendar Sync:** DeviceCalendarManager.bootstrapOnLaunch() → CalendarRefreshCoordinator (success path traced, error recovery implicit)
- **Multi-Semester Filtering:** activeSemesterIds → activeCourses (data path clear, UI integration incomplete)

### ❌ Implicit / Magical
- **Background Task Refresh:** `@AppStorage` triggers? `ScenePhase` handlers? Not documented.
- **Notification Scheduling:** TaskAlarmScheduler files exist but marked with TODO comments (not production-ready)
- **iCloud Sync Conflicts:** SyncMonitor exists, merge strategy for conflicts unclear
- **Widget Updates:** ItoriTimerWidget exists, refresh triggers not traced end-to-end

**Verdict:** Core CRUD flows are solid. Background execution, sync conflicts, and widget refresh need explicit documentation before production.

---

## 2. COHESION (Conceptual Gravity)

### SharedCore Analysis
- **455 Swift files** across SharedCore/Platforms/Shared
- **Structure:**
  - Models: 24 files (clear purpose)
  - State: 31 files (some overlap: AppModel vs AppSettingsModel vs AppPreferences)
  - Services: Spread across Services/ and Features/
  - Views: 28 files in SharedCore/Views (some duplicates: `.backup`, `.orig` files present)

### Blast Radius Test
**If I removed...**
- `DataIntegrityCoordinator.swift`: Cascade deletes break → **PASS** (critical)
- `PlannerSyncCoordinator.swift`: Auto-reschedule breaks → **PASS** (critical)
- `CalendarRefreshCoordinator.swift`: Calendar updates break → **PASS** (critical)
- `AppModel.shared`: selectedPage navigation breaks → **PASS** (critical)
- `ResetCoordinator.swift`: Data reset breaks → **UNCLEAR** (used where?)
- `FeatureStateVersionTracker.swift`: Version migrations break → **UNCLEAR** (deprecated?)
- `UsageStats.swift`: Analytics break → **UNCLEAR** (optional feature?)

### State Fragmentation
**Concerns:**
- `AppModel`, `AppSettingsModel`, `AppPreferences` — overlapping responsibilities?
- `PlannerStore`, `PlannerCoordinator`, `PlannerSyncCoordinator` — clear boundaries?
- `.backup` and `.orig` files in SharedCore/Views — leftover from merge conflicts

**Verdict:** Core coordinators have clear jobs. State management has 2-3 overlapping singletons that need consolidation. File cruft (backups) must be cleaned.

---

## 3. UI (Behavioral Invariants)

### Layout Under Stress
**NOT TESTED:**
- Dynamic Type at AX5 (200%+ scale)
- Split view resize on iPad (sudden width changes)
- Rotation mid-interaction
- System accessibility overrides (reduce transparency, increase contrast)

**Known Issues:**
- Dashboard uses `GeometryReader` for max-width constraints (can break with SwiftUI layout engine changes)
- Calendar grid has unresolved merge conflicts (fix/calendar-month-grid-visual-corrections branch)
- Backup files suggest recent layout churn (instability)

### Material Consistency
**Cross-Platform:**
- DesignSystem exists with SpacingTokens
- macOS uses `.background()`, iOS uses `.background(DesignSystem.Colors.appBackground)`
- No explicit audit of `.material()` usage vs custom backgrounds
- Z-index not explicitly managed (relying on SwiftUI default stacking)

### Error & Empty States
**Checked:**
- `IOSDashboardView`: Shows cards even with no data (no explicit empty state)
- `CoursesStore`: Soft delete filters prevent nil crashes
- Assignment views: Unknown if "No assignments" state is designed

**NOT CHECKED:**
- Network failure in LLM features
- Calendar permission denied state (CalendarAccessBanner exists, but is it always shown?)
- iCloud sync disabled / failed state
- Widget refresh failure

**Verdict:** Layout stress-testing is absent. Empty states exist but not systematically audited. Error states rely on implicit SwiftUI behavior (may fail silently).

---

## 4. PRODUCTION PREP CHECKLIST

### Data Model Freeze
- ❌ **Not Ready:** 47 TODOs in production code
- ❌ **activeSemesterIds migration:** Code exists but UI incomplete (can't ship half-built feature)
- ⚠️ **Soft delete:** Model done, but delete confirmations missing from UI (users could accidentally lose data)

### CI Gates
- ⚠️ **Build:** Scheme "Itori" exists, but no CI/CD pipeline detected (`.github/workflows` not checked)
- ❌ **Lint:** check_release_hygiene.sh exists but incomplete (stops checking after TODO strings)
- ❌ **Snapshot Tests:** SnapshotTestHarness.swift exists, but marked with TODOs (not production-ready)

### Technical Debt
**TODOs in Production Code:**
```
SharedCore/State/CalendarManager.swift: 2
SharedCore/State/AppSettingsModel.swift: 1
SharedCore/Services/NotificationManager.swift: 1
Platforms/iOS/Services/TaskAlarmScheduler.swift: 5
Platforms/macOS/App/ItoriApp.swift: 4
SharedCore/Services/FeatureServices/FileParsingService.swift: 6
...47 total
```

**Action Required:**
- Audit each TODO: ship, defer, or delete
- Convert "ship" TODOs to tracked issues
- Remove FIXMEs that would trigger in release builds

### Threading Audit
- ✅ **MainActor:** 167 annotations found (good coverage)
- ❌ **Not Verified:** Do all SwiftData queries happen off main thread?
- ❌ **Not Verified:** Are background task coordinators properly isolated?
- ⚠️ **Observation:** AppModel is NOT @MainActor (potential race condition with @Published properties)

### Error Handling
- ⚠️ **Polite Failures:** Not systematically audited
- ⚠️ **User-Facing Errors:** Unknown if LLM failures show user-friendly messages
- ⚠️ **Crash Prevention:** Soft delete prevents nil unwraps, but no guard against empty activeSemesterIds

### Version Discipline
- ❌ **No VERSION file**
- ❌ **No CHANGELOG.md**
- ❌ **No git tagging strategy documented**
- ❌ **No branch protection rules visible**

---

## 5. SPECIFIC PRESSURE POINTS

### High-Risk Areas
1. **Background Refresh:** Widget + notifications need explicit refresh triggers
2. **iCloud Sync:** Conflict resolution strategy not documented
3. **Multi-Semester UI:** Half-implemented (data model done, UI missing) — cannot ship
4. **Calendar Conflicts:** Merge conflict in CalendarGrid.swift must be resolved
5. **File Cruft:** `.backup`, `.orig` files suggest unstable codebase

### Change Resistance Test
**Can I safely make these changes?**
- Add a new assignment field → YES (additive)
- Change Course.deletedAt semantics → NO (breaking change, cascades to persistence)
- Rename AppPage.dashboard → NO (affects navigation, persistence, deep links)
- Add a new coordinatorservice → YES (additive, but test initialization order)

**Verdict:** System is additive-friendly but not change-resistant. Breaking changes would cascade.

---

## 6. BLOCKERS TO PRODUCTION

### CRITICAL (Cannot Ship)
1. ❌ **47 TODOs in production code** — must audit and resolve
2. ❌ **activeSemesterIds UI incomplete** — half-built features break user trust
3. ❌ **CalendarGrid merge conflicts** — calendar may render incorrectly
4. ❌ **Backup files in SharedCore** — indicates unstable codebase
5. ❌ **No threading audit** — risk of race conditions

### HIGH (Should Not Ship)
6. ⚠️ **Empty states not audited** — users see broken UI in edge cases
7. ⚠️ **Error states not audited** — LLM/network failures may crash or confuse
8. ⚠️ **Layout stress tests missing** — iPad split view may break
9. ⚠️ **AppModel not @MainActor** — potential race condition
10. ⚠️ **No CI/CD pipeline** — manual QA will miss regressions

### MEDIUM (Can Ship, but Fix Soon)
11. ⚠️ State fragmentation (AppModel/AppSettings/AppPreferences overlap)
12. ⚠️ Widget refresh triggers not documented
13. ⚠️ iCloud conflict resolution not documented
14. ⚠️ No VERSION/CHANGELOG/tagging strategy

---

## 7. RECOMMENDED EXECUTION SEQUENCE

### Phase 1: Stabilize (3-5 days)
**Goal:** Make existing code safe to change.

1. **Resolve CalendarGrid merge conflict** (2 hours)
2. **Remove .backup/.orig files** (30 min)
3. **Audit 47 TODOs** (1 day)
   - Ship: Convert to tracked issues
   - Defer: Move to BACKLOG.md
   - Delete: Remove dead code
4. **Freeze activeSemesterIds** (1 day)
   - Option A: Complete UI implementation
   - Option B: Remove feature, ship in next release
5. **Add @MainActor to AppModel** (15 min)
6. **Audit empty states** (1 day)
   - Document expected behavior for each view
   - Add explicit "No data" states where missing

### Phase 2: Harden (1 week)
**Goal:** Make system production-ready.

7. **Threading audit** (2 days)
   - Trace SwiftData queries
   - Verify background coordinators
   - Add MainActor where needed
8. **Error state audit** (2 days)
   - LLM failures → user-friendly messages
   - Network failures → retry/offline mode
   - iCloud sync → conflict UI
9. **Layout stress tests** (1 day)
   - Dynamic Type AX5
   - iPad split view resize
   - Rotation
10. **Expand check_release_hygiene.sh** (1 day)
    - Force unwrap detection
    - Thread safety violations
    - User-visible TODOs
    - Snapshot test coverage

### Phase 3: Production Prep (2-3 days)
**Goal:** Mechanical quality gates.

11. **Version/CHANGELOG/tagging** (1 day)
12. **CI/CD pipeline** (1 day)
    - Build all schemes
    - Run check_release_hygiene.sh
    - Run unit tests (if they exist)
13. **Final QA pass** (1 day)
    - Test on clean device
    - Test with existing data
    - Test all critical flows

---

## 8. META-OBSERVATIONS

### Healthy Signals
- ✅ Soft delete prevents data loss
- ✅ Coordinators have clear responsibilities
- ✅ Design system tokens exist
- ✅ 167 MainActor annotations (threading awareness)
- ✅ Release hygiene script started

### Unhealthy Signals
- ❌ 47 TODOs (decision fatigue)
- ❌ Backup files (merge conflict residue)
- ❌ Incomplete features (activeSemesters, TaskAlarmScheduler)
- ❌ No version discipline
- ❌ No layout stress tests

### Cultural Shift Needed
**From:** "Add features quickly, iterate visually"  
**To:** "Every change must justify its blast radius"

This is the transition you described: moving from intuition-driven to constraint-driven development. The system is 60% through this transition.

---

## 9. SUCCESS CRITERIA

### You're Ready When:
- ✅ Zero TODOs in production code (all converted to issues or deleted)
- ✅ CalendarGrid conflicts resolved
- ✅ activeSemesters fully shipped OR fully removed
- ✅ All backup files deleted
- ✅ AppModel is @MainActor
- ✅ Empty states documented for all views
- ✅ Error states audited for LLM/network/iCloud
- ✅ Layout stress tests pass (Dynamic Type, split view, rotation)
- ✅ check_release_hygiene.sh catches force unwraps + threading issues
- ✅ CI/CD pipeline runs on every commit
- ✅ VERSION/CHANGELOG exist

### You Know It's Working When:
- Making a change feels "slightly annoying" (constraints are enforced)
- CI catches problems before you do
- Empty/error states are boring (already designed)
- Merge conflicts are rare (file structure is stable)

---

## RECOMMENDATION

**Do not flip the switch yet.** You're 60% through the transition.

**Critical Path:**
1. Stabilize (Phase 1) — 3-5 days
2. Harden (Phase 2) — 1 week
3. Production Prep (Phase 3) — 2-3 days

**Total:** 2-3 weeks, not 2-3 days.

**Alternative (Fast Track):**
- Remove activeSemesters feature (incomplete)
- Remove TaskAlarmScheduler (incomplete)
- Resolve CalendarGrid conflicts
- Audit 47 TODOs → defer non-critical
- Add minimal CI gate (build + hygiene check)
- Ship with explicit "Beta" label

This gets you to production in 1 week, but with feature cuts.

---

**Next Step:** Choose between "Full Hardening" (2-3 weeks) or "Fast Track Beta" (1 week).
