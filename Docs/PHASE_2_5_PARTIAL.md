# Phase 2.5: activeSemesterIds Removal - IN PROGRESS

**Date:** 2026-01-05  
**Status:** ⚠️ IN PROGRESS (Build broken, needs completion)

---

## Goal

Remove incomplete activeSemesterIds feature (multi-semester support) and revert to single currentSemesterId.

---

## Work Completed

### UI Files Updated ✅
1. `SharedCore/Views/SemesterPickerView.swift` - Replace activeSemesterIds checks with currentSemesterId
2. `Platforms/iOS/Root/IOSRootView.swift` - Partially updated
3. `Platforms/iOS/Scenes/IOSCorePages.swift` - Partially updated
4. `Platforms/macOS/Scenes/CoursesView.swift` - Updated

**Pattern Applied:**
- `activeSemesterIds.contains(id)` → `currentSemesterId == id`
- `activeSemesterIds.isEmpty` → `currentSemesterId == nil`
- `activeSemesters.first` → `currentSemester`

---

## Work Remaining

### CoursesStore.swift - NOT STARTED ❌

**Must Remove:**
1. `@Published var activeSemesterIds: Set<UUID>`  property
2. `activeSemesterIds` from InitialCoursesSnapshot struct
3. Migration logic in `currentSemesterId` didSet
4. Initialization/persistence of activeSemesterIds
5. Toggle active semester logic

**Must Update:**
```swift
var activeSemesters: [Semester] {
    // Current: semesters.filter { activeSemesterIds.contains($0.id) ... }
    // Should be: Return array with currentSemester if exists
    if let currentId = currentSemesterId,
       let semester = semesters.first(where: { $0.id == currentId && !$0.isArchived }) {
        return [semester]
    }
    return []
}
```

### Build Errors Remaining

**Error Count:** 3 compilation errors in iOS

**Locations:**
- Remaining `currentSemester(...)` function calls (should be `semesters.first(where: ...)`)
- Potentially broken CoursesStore state after partial updates

---

## Recommended Approach

1. **Revert CoursesStore.swift** to clean state
2. **Manually remove** activeSemesterIds property and references
3. **Update** activeSemesters computed property
4. **Test build** after each change
5. **Fix remaining** UI callsites

**Estimated Time:** 1-2 hours

---

## Current Build Status

❌ **iOS:** BUILD FAILED (3 errors)  
❌ **macOS:** Not tested  

---

## Decision Point

**Option A:** Complete Phase 2.5 now (1-2 hours)
- Remove activeSemesterIds completely
- Get builds passing
- Full scope cut achieved

**Option B:** Defer to v1.1
- Revert all Phase 2.5 changes
- Keep activeSemesterIds as-is
- Ship v1.0 with partial multi-semester support

**Recommendation:** Complete Phase 2.5 (Option A)
- Feature is already incomplete/non-functional
- Leaving partial code increases tech debt
- Clean removal is better than half-finished feature

---

**Status:** Paused - Awaiting decision and completion
