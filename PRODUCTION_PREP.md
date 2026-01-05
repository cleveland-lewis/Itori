# Production Readiness Gate
**Last Updated:** 2026-01-05  
**Status:** IN PROGRESS

This document defines what "ready to ship" means. Every item must be checkable by a script, test, or CI job.

---

## Exit Criteria (Binary Gates)

### 1. Build Gates
- [ ] `xcodebuild -scheme Itori -configuration Release` succeeds (iOS)
- [ ] `xcodebuild -scheme Itori -configuration Release` succeeds (macOS)
- [ ] `xcodebuild -scheme ItoriWatch -configuration Release` succeeds (watchOS) *OR* watchOS target removed
- [ ] Zero compiler warnings in Release mode

**Enforced By:** `.github/workflows/ci.yml` (to be created)

---

### 2. Code Hygiene Gates
- [ ] `scripts/check_release_hygiene.sh` exits 0
- [ ] No `.backup`, `.orig`, or conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- [ ] No user-visible `TODO` strings in UI code (`Text("TODO")`, `.title("FIXME")`)
- [ ] All TODOs follow format: `TODO(#issue): description` or removed
- [ ] No force unwraps (`!`) in SharedCore/Views, SharedCore/State, Platforms/*/Scenes
- [ ] No `fatalError()` reachable in user flows

**Enforced By:** `scripts/check_release_hygiene.sh` (enhanced)

---

### 3. Threading Safety Gates
- [ ] All `@Published` properties owned by UI-accessed classes are on `@MainActor`
- [ ] `AppModel` is `@MainActor`
- [ ] No SwiftData fetches on main thread in hot paths (verified by instrument or assertion)
- [ ] Background coordinators do not directly mutate `@Published` state

**Enforced By:**
- `scripts/check_threading_safety.sh` (to be created)
- Manual instrument run documented in `docs/THREADING_AUDIT.md`

---

### 4. Feature Scope Gates
- [ ] `docs/RELEASE_SCOPE_v1.md` exists and defines what's in/out
- [ ] All half-built features either:
  - Completed and tested, OR
  - Removed from codebase, OR
  - Hidden behind `#if DEBUG` or feature flag

**Current Half-Built Features:**
- `activeSemesterIds` (UI incomplete)
- `TaskAlarmScheduler` (marked with TODOs)

**Decision Required:** Finish, remove, or flag each by [DATE]

**Enforced By:** Manual review + CI check for TODO-marked files in Release builds

---

### 5. Layout Stress Gates
- [ ] Stress matrix test pass documented in `docs/LAYOUT_STRESS_RESULTS.md`
- [ ] Tests include:
  - iOS: Dynamic Type AX5 (200%)
  - iOS: Reduce Transparency ON
  - iPadOS: Split view narrow ↔ wide resize
  - iPadOS: Rotation mid-interaction
  - macOS: Window resize tiny → huge
- [ ] At least one automated layout snapshot test exists

**Enforced By:**
- Manual checklist (initially)
- Snapshot tests via `ItoriUITests` (future)

---

### 6. Error & Empty State Gates
- [ ] All screens with dynamic data have explicit empty states (not just blank)
- [ ] All network-dependent features show error UI on failure (not crash)
- [ ] LLM failures show user-friendly message (not raw error)
- [ ] iCloud sync conflicts have defined behavior (documented)
- [ ] Calendar permission denied shows banner (verified)

**Enforced By:** Manual QA checklist → `docs/ERROR_STATE_AUDIT.md`

---

### 7. Data Integrity Gates
- [ ] Soft delete cascade tested (Course → Tasks)
- [ ] Restore functionality tested
- [ ] activeSemesterIds never empty (initialization tested)
- [ ] Migration from old save format tested (backward compat)

**Enforced By:** Unit tests in `Tests/Unit/ItoriTests/DataIntegrityTests.swift`

---

### 8. Versioning Gates
- [ ] `VERSION` file exists with format `MAJOR.MINOR.PATCH`
- [ ] `CHANGELOG.md` exists with current release notes
- [ ] Git tag strategy documented in `docs/RELEASE_PROCESS.md`
- [ ] Version number matches Xcode target settings

**Enforced By:** `scripts/check_version_sync.sh` (to be created)

---

### 9. CI/CD Gates
- [ ] `.github/workflows/ci.yml` runs on every PR
- [ ] CI runs: build + tests + hygiene script
- [ ] CI fails PR if any gate fails
- [ ] Main branch is protected (requires CI pass to merge)

**Enforced By:** GitHub branch protection rules

---

### 10. Documentation Gates
- [ ] `docs/THREADING_AUDIT.md` documents concurrency rules
- [ ] `docs/LAYOUT_STRESS_RESULTS.md` documents stress test results
- [ ] `docs/ERROR_STATE_AUDIT.md` documents failure modes
- [ ] `docs/RELEASE_PROCESS.md` documents tag/version workflow

**Enforced By:** CI check for file existence

---

## Current Blockers (Must Resolve Before Ship)

### CRITICAL
1. **CalendarGrid merge conflicts** → Resolve manually
2. **47 TODOs in production code** → Audit and convert or remove
3. **Backup files in SharedCore** → Delete and prevent recurrence
4. **AppModel not @MainActor** → Add annotation
5. **activeSemesterIds UI incomplete** → Finish or remove

### HIGH
6. **No CI pipeline** → Create `.github/workflows/ci.yml`
7. **Hygiene script incomplete** → Enhance `check_release_hygiene.sh`
8. **Empty states not audited** → Complete manual audit
9. **Layout stress not tested** → Run stress matrix
10. **Threading not verified** → Run instruments + add assertions

---

## Scripts Required

### Existing (Need Enhancement)
- `scripts/check_release_hygiene.sh` → Add force unwrap check, conflict marker check

### New (Must Create)
- `scripts/check_threading_safety.sh` → Detect @Published without @MainActor
- `scripts/check_version_sync.sh` → Verify VERSION matches Xcode
- `.github/workflows/ci.yml` → Run all checks on PR

---

## Test Coverage Required

### Unit Tests
- `Tests/Unit/ItoriTests/DataIntegrityTests.swift` → Soft delete cascade
- `Tests/Unit/ItoriTests/ThreadingSafetyTests.swift` → MainActor verification

### UI Tests
- `Tests/ItoriUITests/LayoutStressTests.swift` → Dynamic Type, split view
- `Tests/ItoriUITests/EmptyStateTests.swift` → Empty state rendering

---

## Success Criteria

**Production Prep is COMPLETE when:**
- All checkboxes above are ✅
- CI passes on main branch
- All scripts exit 0
- Manual QA checklist complete

**You know it's working when:**
- CI catches problems before you do
- Merging requires no manual gate-keeping
- Adding a TODO without an issue breaks CI
- Build failures are loud and immediate

---

## Fast Track Option (1 Week)

If speed is critical, remove scope instead of finishing work:

**Actions:**
1. Remove `activeSemesterIds` feature (revert to single currentSemesterId)
2. Remove or `#if DEBUG` wrap `TaskAlarmScheduler`
3. Resolve CalendarGrid conflicts
4. Delete backup files
5. Convert TODOs → issues or delete
6. Add minimal CI (build + hygiene only)
7. Ship with explicit "v1.0" scope (no beta label needed if disciplined)

**Result:** Smaller feature set, same quality bar.

---

## Timeline Estimate

**Full Path (All Features):** 2-3 weeks  
**Fast Track (Feature Cuts):** 1 week  

**Critical Path (Both):**
1. Resolve conflicts + delete cruft (4 hours)
2. Audit TODOs (1 day)
3. Freeze feature scope (1 day)
4. Add @MainActor to AppModel (15 min)
5. Enhance hygiene script (4 hours)
6. Create CI pipeline (4 hours)
7. Run stress tests (4 hours)
8. QA pass (1 day)

---

**Next Action:** Choose feature scope (full or fast track), then execute critical path.
