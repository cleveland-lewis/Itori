# TODO: Remaining Work After Crash Fix

## Critical: Runtime Crash Fix ✅ COMPLETE
All persistence and initialization issues have been resolved. App should now build and run.

---

## Phase 1: Active Semesters UI (HIGH PRIORITY)

### What's Done
✅ Data model supports Set<UUID> activeSemesterIds  
✅ CoursesStore has activeSemesters computed property  
✅ CoursesStore has activeCourses computed property  
✅ Initialization logic ensures activeSemesterIds is never empty  
✅ Methods: toggleActiveSemester(), setActiveSemesters()

### What's Needed

#### 1.1 Semester Selector Component (macOS & iOS)
**File to Create:** `SharedCore/Views/ActiveSemesterPicker.swift`

**Requirements:**
- Replace segmented control with scalable multi-select picker
- Show checkmark next to active semesters
- Display summary in toolbar/header:
  - 1 active: "Fall 2025"
  - 2 active: "Fall 2025 + 1"
  - 3+: "3 Active Semesters"
- Popover/sheet on macOS, sheet on iOS
- Filter to non-deleted, non-archived semesters

**Pseudocode:**
```swift
struct ActiveSemesterPicker: View {
    @ObservedObject var coursesStore: CoursesStore
    @State private var showingPicker = false
    
    var body: some View {
        Button(summaryText) {
            showingPicker = true
        }
        .popover(isPresented: $showingPicker) {
            List(availableSemesters) { semester in
                Button {
                    coursesStore.toggleActiveSemester(semester)
                } label: {
                    HStack {
                        Text(semester.displayName)
                        Spacer()
                        if coursesStore.activeSemesterIds.contains(semester.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
    
    var summaryText: String {
        let count = coursesStore.activeSemesterIds.count
        if count == 0 { return "No Active Semester" }
        if count == 1, let first = coursesStore.activeSemesters.first {
            return first.displayName
        }
        if count == 2, let first = coursesStore.activeSemesters.first {
            return "\(first.displayName) + 1"
        }
        return "\(count) Active Semesters"
    }
}
```

#### 1.2 Update CoursesView (macOS)
**File:** `Platforms/macOS/Scenes/CoursesView.swift`

**Changes:**
- Replace semester segmented control with ActiveSemesterPicker
- Update course filtering to use `coursesStore.activeCourses`
- Update toolbar to include semester picker button

#### 1.3 Update CoursesView (iOS)
**File:** `Platforms/iOS/Views/CoursesTabView.swift` (or equivalent)

**Changes:**
- Add semester picker to navigation bar trailing item
- Filter courses by activeSemesterIds
- Update empty state if no active semesters

#### 1.4 Update Dashboard
**File:** `Platforms/iOS/Views/DashboardView.swift`

**Changes:**
- Replace "Current Semester" section with "Active Semesters"
- Show stats across all active semesters:
  - Total courses
  - GPA across active semesters
  - Upcoming deadlines from active courses

#### 1.5 Update AddAssignmentView
**File:** (Find the add/edit assignment view)

**Changes:**
- Course picker should filter to `coursesStore.activeCourses`
- Or add option to "Show all courses" if needed

---

## Phase 2: Soft Delete UI (MEDIUM PRIORITY)

### 2.1 Confirm Delete Dialog
**Where:** Course delete action in CoursesView

**Changes:**
- Add alert when deleting a course
- Show count of related tasks that will be soft-deleted
- "Delete" button calls `coursesStore.softDeleteCourse(id:)`
- Option: "Archive Instead" button as alternative

**Example:**
```swift
.alert("Delete Course?", isPresented: $showingDeleteAlert) {
    Button("Cancel", role: .cancel) {}
    Button("Archive", role: .none) {
        coursesStore.toggleArchiveCourse(selectedCourse)
    }
    Button("Delete", role: .destructive) {
        coursesStore.softDeleteCourse(id: selectedCourse.id)
    }
} message: {
    Text("This will delete \(relatedTaskCount) assignments. You can restore this course later.")
}
```

### 2.2 Restore Functionality (Optional)
**File to Create:** `SharedCore/Views/DeletedItemsView.swift` (admin/debug only)

**Requirements:**
- List deleted semesters, courses, tasks
- Show deletedAt timestamp
- Restore button for each item
- Clear button for hard delete (after confirmation)

---

## Phase 3: Developer Mode UI (LOW PRIORITY)

### 3.1 Dev Mode Settings Panel
**File:** `Platforms/macOS/Settings/DeveloperSettingsView.swift` (if it exists)

**Requirements:**
- Toggle for devModeEnabled
- Sub-toggles:
  - UI Logging
  - Data Logging
  - Scheduler Logging
  - Performance Metrics
  - LLM Usage Logging
- Console output viewer (optional)

### 3.2 LLM Usage Display
**File to Create:** `SharedCore/Views/DevLLMUsageView.swift`

**Requirements:**
- Real-time display when LLM is used
- Show:
  - Feature that triggered LLM
  - Model used
  - Token count
  - Latency
  - Success/failure
  - Output preview
- Only visible when devModeEnabled

---

## Phase 4: Task Alarm System (DEFERRED - Phase 4.3)

### Status
❌ NOT STARTED - Requires separate implementation phase

### Files Expected
- `Platforms/iOS/Services/TaskAlarmScheduling.swift`
- `Platforms/iOS/Services/TaskAlarmScheduler.swift`
- `Platforms/iOS/Views/TaskCheckboxRow.swift`
- `Platforms/iOS/Views/TaskAlarmPickerView.swift`
- Timer Page updates

### Prerequisites
- Current crash fix (done)
- Active semesters (in progress)

---

## Phase 5: Calendar Grid Conflict Resolution

### Issue
`Platforms/macOS/Views/CalendarGrid.swift` has merge conflicts between:
- `main` branch
- `fix/calendar-month-grid-visual-corrections` branch

### Resolution Steps
1. Check out fix/calendar-month-grid-visual-corrections
2. Manually review both versions of CalendarGrid.swift
3. Merge visual corrections into main
4. Test calendar rendering

---

## Quick Reference: Branch Status

| Branch | Status | Merge Ready? | Blockers |
|--------|--------|--------------|----------|
| `feature/data-integrity-soft-delete` | ✅ Fixed | Yes | None |
| `feature/active-semesters-multi-select` | ⚠️ Incomplete | No | Need UI components |
| `fix/calendar-month-grid-visual-corrections` | ⚠️ Conflicts | No | Merge conflicts |
| `feature/dev-mode-llm-logging` | ✅ Complete | Yes | None |

---

## Recommended Implementation Order

1. **TEST CRASH FIX FIRST** ⭐ CRITICAL
   - Build app
   - Test on clean simulator
   - Test with existing data
   - Verify soft delete works
   
2. **Active Semesters UI** (2-3 hours)
   - Create ActiveSemesterPicker component
   - Update CoursesView (macOS + iOS)
   - Update Dashboard
   - Update AddAssignmentView

3. **Soft Delete UI Polish** (1 hour)
   - Add delete confirmation dialogs
   - Show cascade counts
   - Test restore functionality

4. **Resolve Calendar Conflicts** (30 minutes)
   - Manual merge of CalendarGrid.swift
   - Test calendar rendering

5. **Developer Mode UI** (1-2 hours, optional)
   - Add settings panel
   - Add LLM usage viewer

6. **Task Alarm System** (4-6 hours, separate phase)
   - Full Phase 4.3 implementation

---

## Testing Priorities

### Must Test Before Merge
1. App launches successfully ✅
2. Existing data loads ✅
3. Soft delete cascade works ✅
4. activeSemesterIds initializes ✅

### Should Test After UI Updates
1. Semester picker shows correct semesters
2. Selecting multiple semesters filters courses correctly
3. Dashboard shows stats for active semesters
4. Assignment creation shows correct courses

### Can Test Later
1. Developer mode logging
2. LLM usage tracking
3. Deleted items view
4. Restore functionality

---

## Files That Need Updates (Summary)

### HIGH PRIORITY (Active Semesters UI)
- [ ] `SharedCore/Views/ActiveSemesterPicker.swift` (CREATE)
- [ ] `Platforms/macOS/Scenes/CoursesView.swift` (UPDATE)
- [ ] `Platforms/iOS/Views/CoursesTabView.swift` (UPDATE)
- [ ] `Platforms/iOS/Views/DashboardView.swift` (UPDATE)
- [ ] (Find and update AddAssignmentView)

### MEDIUM PRIORITY (Polish)
- [ ] Delete confirmation dialogs in course actions
- [ ] Cascade count display
- [ ] `SharedCore/Views/DeletedItemsView.swift` (CREATE, optional)

### LOW PRIORITY (Dev Mode)
- [ ] `Platforms/macOS/Settings/DeveloperSettingsView.swift` (UPDATE/CREATE)
- [ ] `SharedCore/Views/DevLLMUsageView.swift` (CREATE, optional)

### DEFERRED (Phase 4.3)
- [ ] Task alarm system (entire phase)

---

## Estimated Time to Complete

| Task | Estimated Time |
|------|---------------|
| Test crash fix | 15-20 min |
| Active Semesters UI | 2-3 hours |
| Soft Delete UI | 1 hour |
| Calendar conflicts | 30 min |
| Dev Mode UI | 1-2 hours |
| **Total (excluding alarms)** | **5-7 hours** |

---

## Success Metrics

### Phase 1 Complete When:
- ✅ App doesn't crash on launch
- ✅ Soft delete cascade works
- ✅ activeSemesterIds is never incorrectly empty

### Phase 2 Complete When:
- ✅ Users can select multiple active semesters
- ✅ UI correctly filters to active semesters
- ✅ Dashboard shows active semester stats

### Phase 3 Complete When:
- ✅ Delete confirmations show cascade impact
- ✅ Users understand what will be deleted

### Phase 4 Complete When:
- ✅ Developer mode logging works
- ✅ LLM usage is visible to devs

---

**Document Created:** 2026-01-04  
**Status:** Crash fix complete, UI work remaining  
**Next Action:** Build and test, then implement Active Semesters UI
