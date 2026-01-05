# Production Prep Execution Plan
**Date:** 2026-01-05  
**Status:** READY TO EXECUTE

This document turns the audit into mechanical actions. No ambiguity, just binary gates.

---

## Current State

**Scripts Created:**
- ✅ `Scripts/check_release_hygiene.sh` (enhanced)
- ✅ `Scripts/check_threading_safety.sh` (new)
- ✅ `Scripts/check_version_sync.sh` (new)

**Documentation Created:**
- ✅ `PRODUCTION_PREP.md` (gate checklist)
- ✅ `RELEASE_SCOPE_v1.md` (feature freeze)
- ✅ `Docs/THREADING_AUDIT.md` (audit framework)
- ✅ `Docs/LAYOUT_STRESS_RESULTS.md` (test matrix)
- ✅ `Docs/ERROR_STATE_AUDIT.md` (failure modes)
- ✅ `Docs/ICLOUD_SYNC_STRATEGY.md` (conflict resolution)
- ✅ `VERSION` file (1.0.0)
- ✅ `CHANGELOG.md` (release notes)

**CI Pipeline:**
- ✅ `.github/workflows/ci.yml` (hygiene + build gates)

**Script Results (Baseline):**
```
❌ 1 .orig file found
❌ 60+ .backup files found
⚠️ 39 force unwraps in critical paths
⚠️ 44 untracked TODOs
```

---

## Critical Path (Fast Track = 1 Week)

### Day 1: Repository Hygiene (4 hours)

#### 1.1 Delete Backup/Orig Files
**Command:**
```bash
cd /Users/clevelandlewis/Desktop/Itori
find . -name "*.backup" -o -name "*.orig" | grep -v ".git" | xargs rm -v
git add -u
git commit -m "chore: remove backup files for production prep"
```

**Verification:**
```bash
bash Scripts/check_release_hygiene.sh | grep "backup\|orig"
# Should show ✅
```

**Time:** 15 minutes

---

#### 1.2 Audit TODOs
**Action:** Review all 44 untracked TODOs

**Process:**
1. Find all TODOs: `grep -r "// TODO:" --include="*.swift" Platforms/ SharedCore/ Shared/ | grep -v "Test\|Deprecated"`
2. For each TODO, decide:
   - **Ship:** Convert to `TODO(#1): description` (create GitHub issue)
   - **Defer:** Move to `BACKLOG.md`
   - **Delete:** Remove if obsolete

**Commands:**
```bash
# Create BACKLOG.md
touch BACKLOG.md

# For each TODO to defer, move to BACKLOG
# For each TODO to track, create issue and update format
# For each TODO to delete, remove line
```

**Verification:**
```bash
bash Scripts/check_release_hygiene.sh | grep "untracked TODO"
# Should show ✅ or ⚠️ with lower count
```

**Time:** 2-3 hours

---

#### 1.3 Feature Freeze Decision
**Action:** Apply cuts from `RELEASE_SCOPE_v1.md`

**Decision Required:**
- **activeSemesterIds:** Remove or finish?
- **TaskAlarmScheduler:** Remove or flag?

**If REMOVE (recommended for fast track):**

```bash
# Revert activeSemesterIds changes
git log --oneline --all --grep="activeSemester" | head -5
# Review commits, decide on revert or manual removal

# Delete TaskAlarmScheduler files
rm -v Platforms/iOS/Services/TaskAlarmScheduler.swift
rm -v Platforms/iOS/Services/TaskAlarmScheduling.swift
rm -v Platforms/iOS/PlatformAdapters/TimerAlarmScheduler.swift
git add -u
git commit -m "feat: remove TaskAlarmScheduler (deferred to v1.1)"
```

**Verification:**
```bash
# Build should succeed
xcodebuild -project ItoriApp.xcodeproj -scheme Itori -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO clean build
```

**Time:** 1 hour

---

### Day 2: Threading Safety (4 hours)

#### 2.1 Add @MainActor to AppModel
**File:** `SharedCore/State/AppModel.swift`

**Change:**
```swift
@MainActor
final class AppModel: ObservableObject {
    // ...
}
```

**Verification:**
```bash
bash Scripts/check_threading_safety.sh | grep "AppModel"
# Should not warn about AppModel
```

**Time:** 15 minutes

---

#### 2.2 Audit State Classes
**Action:** Check each State/ class with @Published

**Files to Check:**
- `AppSettingsModel.swift`
- `CoursesStore.swift`
- `AssignmentsStore.swift`
- `TimerPageViewModel.swift`
- `CalendarManager.swift`
- (All 31 State/ files)

**Process:**
1. Open each file
2. If has `@Published`, ensure `@MainActor` on class
3. If intentionally isolated, document why

**Verification:**
```bash
bash Scripts/check_threading_safety.sh
# Should show ✅ or minimal warnings
```

**Time:** 2 hours

---

#### 2.3 Instrument Hot Paths
**Action:** Run Time Profiler on critical flows

**Steps:**
1. Open Xcode → Product → Profile → Time Profiler
2. Launch app, navigate to:
   - Dashboard
   - Courses list
   - Assignment list
   - Timer page
3. Check "Main Thread" row for blocking calls
4. Screenshot any main thread blocking >16ms

**Outcome:** Document in `Docs/THREADING_AUDIT.md`

**Time:** 1 hour

---

### Day 3: Layout + Error States (4 hours)

#### 3.1 Run Layout Stress Matrix
**Action:** Manual testing on real devices

**Checklist:**
- [ ] iOS: Dynamic Type AX5 (Dashboard, Courses, Assignments, Timer)
- [ ] iOS: Reduce Transparency ON
- [ ] iPadOS: Split view narrow ↔ wide resize
- [ ] iPadOS: Rotation mid-interaction
- [ ] macOS: Window resize tiny → huge

**Outcome:** Fill in `Docs/LAYOUT_STRESS_RESULTS.md` with ✅ or ❌ + screenshots

**Time:** 2 hours

---

#### 3.2 Audit Empty States
**Action:** Launch app with no data, check each screen

**Checklist:**
- [ ] Dashboard with no courses
- [ ] Courses list with no semesters
- [ ] Assignments list with no tasks
- [ ] Timer with no activities

**Outcome:** Note in `Docs/ERROR_STATE_AUDIT.md` which screens have empty states, which don't

**Time:** 1 hour

---

#### 3.3 Audit Error States
**Action:** Trigger error conditions, observe behavior

**Scenarios:**
- [ ] LLM disabled (settings)
- [ ] Calendar permission denied
- [ ] Network offline (airplane mode)
- [ ] iCloud disabled

**Outcome:** Document in `Docs/ERROR_STATE_AUDIT.md` what user sees

**Time:** 1 hour

---

### Day 4: CI + Version Discipline (2 hours)

#### 4.1 Verify CI Pipeline
**Action:** Push changes, watch CI run

**Steps:**
1. Commit all changes: `git commit -m "chore: production prep hygiene"`
2. Push to branch: `git push origin production-prep`
3. Open PR to main
4. Watch CI run: https://github.com/[USERNAME]/Itori/actions
5. Fix any failures

**Verification:**
- [ ] Hygiene job passes
- [ ] Build iOS job passes
- [ ] Build macOS job passes
- [ ] Tests run (even if some fail)

**Time:** 1 hour

---

#### 4.2 Update VERSION + CHANGELOG
**Action:** Finalize release notes

**Files:**
- `VERSION`: Already `1.0.0`
- `CHANGELOG.md`: Add release date, finalize features/fixes

**Example:**
```markdown
## [1.0.0] - 2026-01-12

### Added
- Dashboard with upcoming tasks
- (etc)

### Fixed
- Removed backup files
- Added threading safety
```

**Time:** 30 minutes

---

#### 4.3 Document Release Process
**Create:** `Docs/RELEASE_PROCESS.md`

**Content:**
- How to cut a release
- Git tag format (e.g., `v1.0.0`)
- Branch protection rules
- Release checklist

**Time:** 30 minutes

---

### Day 5: QA Pass (4 hours)

#### 5.1 Manual Testing
**Action:** Full app walkthrough on clean install

**Steps:**
1. Delete app from device/simulator
2. Install fresh build
3. Complete onboarding
4. Test critical flows:
   - Add semester
   - Add course
   - Add assignment
   - Start timer
   - View calendar
   - Enable iCloud sync

**Outcome:** Document bugs in GitHub issues

**Time:** 2 hours

---

#### 5.2 Cross-Platform Parity
**Action:** Test on all platforms

**Checklist:**
- [ ] iOS: Core flows work
- [ ] iPadOS: Core flows work
- [ ] macOS: Core flows work
- [ ] Data syncs via iCloud

**Outcome:** Note platform-specific issues

**Time:** 1 hour

---

#### 5.3 Final Hygiene Check
**Action:** Run all scripts one last time

**Commands:**
```bash
bash Scripts/check_release_hygiene.sh
bash Scripts/check_threading_safety.sh
bash Scripts/check_version_sync.sh
```

**Verification:**
- All should pass (or warnings only, no errors)

**Time:** 15 minutes

---

#### 5.4 Sign-Off
**Action:** Update gate documents with ✅

**Files to Update:**
- `PRODUCTION_PREP.md` → Mark completed items ✅
- `Docs/THREADING_AUDIT.md` → Add sign-off
- `Docs/LAYOUT_STRESS_RESULTS.md` → Add sign-off
- `Docs/ERROR_STATE_AUDIT.md` → Add sign-off

**Time:** 30 minutes

---

## Success Metrics

**You're Ready to Ship When:**
- [ ] All scripts pass (or warnings only)
- [ ] CI is green
- [ ] No .backup or .orig files
- [ ] All TODOs tracked or removed
- [ ] Feature scope frozen (cuts applied)
- [ ] AppModel is @MainActor
- [ ] Layout stress tests documented
- [ ] Empty/error states audited
- [ ] Manual QA pass complete
- [ ] VERSION + CHANGELOG finalized
- [ ] All gate docs signed off

**If All Checked:** Ship.

---

## Alternative: Full Path (2-3 Weeks)

If feature cuts are unacceptable, extend timeline:

**Additional Work:**
- Complete activeSemesterIds UI (2-3 days)
- Complete TaskAlarmScheduler (2-3 days)
- Add snapshot tests (1-2 days)
- Advanced layout stress tests (1 day)
- Comprehensive error handling (2 days)

**Total:** +1-2 weeks

---

## Next Immediate Action

**Start here:**
```bash
cd /Users/clevelandlewis/Desktop/Itori
bash Scripts/check_release_hygiene.sh > hygiene_baseline.txt
find . -name "*.backup" -o -name "*.orig" | grep -v ".git" | wc -l
# Delete them after review
```

**Then:**
1. Remove backup files (15 min)
2. Audit 44 TODOs (2-3 hours)
3. Apply feature cuts (1 hour)
4. Add @MainActor to AppModel (15 min)

**By end of Day 1:** Repository is clean, CI is watching.

---

**Document Owner:** Production Prep Team  
**Last Updated:** 2026-01-05  
**Status:** READY TO EXECUTE
