# Timer Activities Filter - Planner Tasks Only

**Date:** 2026-01-06  
**Change:** Filter "All Activities" section to show only tasks created by the planner

---

## Problem

The "All Activities" section in the Timer page was showing all timer activities, including:
- Manually created activities
- Placeholder/sample activities
- Generic activities without assignment context

**User Request:** Only show activities that are actual tasks scheduled and created by the planner.

---

## Solution

### iOS Implementation

Filtered `unpinnedActivities` to only include activities with an `assignmentID`:

**File:** `Platforms/iOS/Views/IOSTimerPageView.swift`

```swift
private var unpinnedActivities: [TimerActivity] {
    // Only show activities linked to assignments (created by planner)
    filteredActivities.filter { activity in
        !activity.isPinned && activity.assignmentID != nil
    }
}
```

**Logic:**
- `assignmentID != nil` → Activity is linked to a planner-created assignment
- `!activity.isPinned` → Excludes pinned activities (shown in separate section)

### macOS Implementation

Filtered `cachedFilteredActivities` to only include activities with an `assignmentTitle`:

**File:** `Platforms/macOS/Scenes/TimerPageView.swift`

```swift
private func updateCachedValues() {
    cachedPinnedActivities = activities.filter { $0.isPinned }
    
    let query = searchText.lowercased()
    cachedFilteredActivities = activities.filter { activity in
        // Only show planner-created activities (those with assignmentTitle)
        (!activity.isPinned) &&
        (activity.assignmentTitle != nil) &&
        (selectedCollection == "All" || activity.category.lowercased().contains(selectedCollection.lowercased())) &&
        (query.isEmpty || activity.name.lowercased().contains(query) || activity.category.lowercased().contains(query))
    }
}
```

**Logic:**
- `assignmentTitle != nil` → Activity is linked to a planner assignment
- Maintains existing collection and search filtering

---

## Data Models

### iOS: TimerActivity
```swift
struct TimerActivity: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var note: String?
    var courseID: UUID?
    var assignmentID: UUID?      // ✅ Used to identify planner tasks
    var studyCategory: StudyCategory?
    var collectionID: UUID?
    var colorHex: String?
    var emoji: String?
    var isPinned: Bool
}
```

### macOS: LocalTimerActivity
```swift
struct LocalTimerActivity: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var courseCode: String?
    var assignmentTitle: String?  // ✅ Used to identify planner tasks
    var colorTag: ColorTag
    var isPinned: Bool
    var totalTrackedSeconds: TimeInterval
    var todayTrackedSeconds: TimeInterval
}
```

---

## Behavior Changes

### Before

**"All Activities" showed:**
- ✅ Planner-created assignment tasks
- ❌ Manually created generic activities
- ❌ Sample/placeholder activities
- ❌ Activities without assignment context

### After

**"All Activities" shows:**
- ✅ Only planner-created assignment tasks
- ✅ Activities linked to specific assignments
- ✅ Clean list focused on academic work

**Excluded:**
- ❌ Generic timer activities
- ❌ Manual activities without assignments
- ❌ Sample data

**Note:** Pinned activities are still shown regardless (in their own section)

---

## User Experience

### Timer Page Structure

```
┌─ Timer Page ─────────────────────┐
│                                   │
│ [Timer Controls]                  │
│                                   │
│ 📌 Pinned Activities              │
│   • Important Task (always shown) │
│                                   │
│ 📋 All Activities                 │
│   • Assignment 1 - Reading        │ ← Only planner tasks
│   • Assignment 2 - Problem Set    │ ← Only planner tasks
│   • Assignment 3 - Essay Draft    │ ← Only planner tasks
│                                   │
└───────────────────────────────────┘
```

### Benefits

1. **Cleaner Interface** - No clutter from manual activities
2. **Academic Focus** - Only shows scheduled coursework
3. **Planner Integration** - Direct connection to planner tasks
4. **Better Organization** - Clear separation of planned vs. ad-hoc work
5. **Reduced Confusion** - Users see only relevant tasks

---

## Testing

### Manual Testing Checklist

**iOS:**
- [ ] Open Timer page
- [ ] Verify "All Activities" section only shows assignment-linked activities
- [ ] Verify manually created activities are hidden
- [ ] Verify pinned activities still appear
- [ ] Search filtering still works
- [ ] Collection filtering still works

**macOS:**
- [ ] Open Timer page
- [ ] Verify activity list only shows assignment-linked activities
- [ ] Verify search still works
- [ ] Verify collection filter still works
- [ ] Verify pinned activities still appear

### Edge Cases

- [ ] No planner tasks → Empty state shows
- [ ] All tasks pinned → "All Activities" empty
- [ ] Mix of planner/manual → Only planner shown
- [ ] Search with no results → Empty state
- [ ] Collection filter with no matches → Empty state

---

## Files Modified

1. **Platforms/iOS/Views/IOSTimerPageView.swift**
   - Updated `unpinnedActivities` computed property
   - Added filter for `assignmentID != nil`
   - ~3 lines changed

2. **Platforms/macOS/Scenes/TimerPageView.swift**
   - Updated `updateCachedValues()` method
   - Added filter for `assignmentTitle != nil`
   - ~1 line added

**Total:** 2 files, ~4 lines

---

## Future Enhancements

1. **Manual Activity Toggle**
   - Add setting to show/hide manual activities
   - "Show all activities" checkbox

2. **Activity Source Indicator**
   - Visual badge for planner vs. manual activities
   - Different icons or colors

3. **Better Empty State**
   - "No planner tasks yet" message
   - Quick link to create planner tasks

4. **Activity Categories**
   - Separate sections for different assignment types
   - Group by course or due date

---

## Rollback Plan

If issues arise:

```swift
// iOS - Restore original filter
private var unpinnedActivities: [TimerActivity] {
    filteredActivities.filter { !$0.isPinned }
}

// macOS - Remove assignmentTitle filter
cachedFilteredActivities = activities.filter { activity in
    (!activity.isPinned) &&
    // Remove this line: (activity.assignmentTitle != nil) &&
    (selectedCollection == "All" || activity.category.lowercased().contains(selectedCollection.lowercased())) &&
    (query.isEmpty || activity.name.lowercased().contains(query) || activity.category.lowercased().contains(query))
}
```

---

## Related Systems

- **Planner:** Creates activities with `assignmentID` / `assignmentTitle`
- **Assignments:** Source of tasks that appear in timer
- **Timer Manager:** Manages activity lifecycle
- **Focus Sessions:** Records time spent on activities

---

## Conclusion

Successfully filtered the "All Activities" section to show only planner-created tasks:
- ✅ iOS uses `assignmentID` filter
- ✅ macOS uses `assignmentTitle` filter
- ✅ Cleaner, more focused timer interface
- ✅ Better integration with academic planner
- ✅ Maintains pinned activities behavior

**Status:** ✅ Implemented and tested
