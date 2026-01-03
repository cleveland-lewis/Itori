# iOS Time Estimation Label Update

**Status:** COMPLETE ✅  
**Date:** December 23, 2025  
**Platform:** iOS + iPadOS only

---

## Overview

Updated the time estimation labels in both the assignment detail view and editor to be context-aware based on assignment type. The label now changes between "Estimated Work Time" and "Estimated Study Time" depending on the task category.

---

## Changes

### Label Logic

**"Estimated Study Time"** - Used for:
- Exam
- Quiz

**"Estimated Work Time"** - Used for:
- Homework (practiceHomework)
- Reading
- Project
- Review

---

## Implementation

### Files Modified

**File:** `iOS/Scenes/IOSCorePages.swift`

### 1. IOSTaskDetailView (Detail Sheet)

**Before:**
```swift
DetailRow(label: "Estimated Time", value: "\(task.estimatedMinutes) minutes")
```

**After:**
```swift
DetailRow(label: timeEstimateLabel(task.type), value: "\(task.estimatedMinutes) minutes")
```

**Added Helper Function:**
```swift
private func timeEstimateLabel(_ type: TaskType) -> String {
    switch type {
    case .exam, .quiz:
        return "Estimated Study Time"
    case .practiceHomework, .reading, .project, .review:
        return "Estimated Work Time"
    }
}
```

---

### 2. IOSTaskEditorView (Editor Form)

**Before:**
```swift
Stepper("Estimated Minutes: \(draft.estimatedMinutes)", value: $draft.estimatedMinutes, in: 15...360, step: 15)
```

**After:**
```swift
Stepper("\(timeEstimateLabel(draft.type)): \(draft.estimatedMinutes) min", value: $draft.estimatedMinutes, in: 15...360, step: 15)
```

**Added Helper Function:**
```swift
private func timeEstimateLabel(_ type: TaskType) -> String {
    switch type {
    case .exam, .quiz:
        return "Estimated Study Time"
    case .practiceHomework, .reading, .project, .review:
        return "Estimated Work Time"
    }
}
```

**Also changed:**
- "Estimated Minutes" → Dynamic label
- Display format: "\(draft.estimatedMinutes) min" instead of just the number

---

## Visual Examples

### Detail View - Homework Assignment
```
┌─────────────────────────────────────┐
│ TIME & EFFORT                       │
│ Estimated Work Time   60 minutes    │ ← For Homework
│ Importance            High          │
│ Difficulty            Medium        │
└─────────────────────────────────────┘
```

### Detail View - Exam
```
┌─────────────────────────────────────┐
│ TIME & EFFORT                       │
│ Estimated Study Time  90 minutes    │ ← For Exam
│ Importance            Critical      │
│ Difficulty            Hard          │
└─────────────────────────────────────┘
```

### Editor - Homework Assignment
```
┌─────────────────────────────────────┐
│ SCHEDULE                            │
│ ☑ Has Due Date                      │
│ Due        January 15, 2025         │
│ Estimated Work Time: 60 min  [-][+] │ ← For Homework
└─────────────────────────────────────┘
```

### Editor - Quiz
```
┌─────────────────────────────────────┐
│ SCHEDULE                            │
│ ☑ Has Due Date                      │
│ Due        January 20, 2025         │
│ Estimated Study Time: 45 min [-][+] │ ← For Quiz
└─────────────────────────────────────┘
```

---

## Type Mapping

| Task Type          | Label                    | Use Case                |
|--------------------|--------------------------|-------------------------|
| Homework           | Estimated Work Time      | Active work required    |
| Reading            | Estimated Work Time      | Active reading/notes    |
| Project            | Estimated Work Time      | Building/creating       |
| Review             | Estimated Work Time      | Review materials        |
| Exam               | Estimated Study Time     | Preparation time        |
| Quiz               | Estimated Study Time     | Preparation time        |

---

## Rationale

### Work Time vs Study Time

**"Estimated Work Time"** indicates:
- Active production/creation
- Completing deliverables
- Reading and taking notes
- Building projects
- Reviewing materials actively

**"Estimated Study Time"** indicates:
- Preparation for assessment
- Reviewing for exam/quiz
- Practice problems
- Memorization time
- Test preparation

### User Clarity

The distinction helps users understand:
1. **What they're estimating** - Work output vs. preparation
2. **Planning accuracy** - Different mental models for work vs. study
3. **Task nature** - Productive work vs. preparatory study

---

## Dynamic Behavior

### In Editor

The label **updates immediately** when the user changes the task type:

1. Create new assignment → Default type (Homework) → "Estimated Work Time"
2. Change type to "Exam" → Label changes to "Estimated Study Time"
3. Change type back to "Reading" → Label changes to "Estimated Work Time"

This provides instant feedback about what kind of time they're estimating.

---

## Code Quality

### Consistency

Both views (detail and editor) use the **same helper function logic**:
```swift
private func timeEstimateLabel(_ type: TaskType) -> String {
    switch type {
    case .exam, .quiz:
        return "Estimated Study Time"
    case .practiceHomework, .reading, .project, .review:
        return "Estimated Work Time"
    }
}
```

### Maintainability

- Explicit mapping for each task type
- Easy to add new types
- Clear separation of work vs. study
- Single source of truth per view

### Type Safety

- Exhaustive switch ensures all types handled
- Compiler enforces completeness
- No fallback case needed

---

## Testing Checklist

### Visual Testing ✅
- [x] Detail view shows "Work Time" for homework
- [x] Detail view shows "Work Time" for reading
- [x] Detail view shows "Work Time" for project
- [x] Detail view shows "Work Time" for review
- [x] Detail view shows "Study Time" for exam
- [x] Detail view shows "Study Time" for quiz

### Editor Testing ✅
- [x] Editor shows "Work Time" for homework (default)
- [x] Editor shows "Work Time" for reading
- [x] Editor shows "Work Time" for project
- [x] Editor shows "Work Time" for review
- [x] Editor shows "Study Time" for exam
- [x] Editor shows "Study Time" for quiz
- [x] Label updates when type picker changes

### Functional Testing ✅
- [x] Time estimation works correctly for all types
- [x] Saved tasks display correct label
- [x] Edited tasks update label if type changes
- [x] No impact on time calculation logic

---

## Edge Cases

### Type Changes
When editing an existing assignment and changing its type:
1. User opens editor for homework assignment
2. Sees "Estimated Work Time: 60 min"
3. Changes type to "Exam"
4. Label immediately updates to "Estimated Study Time: 60 min"
5. Time value remains the same (user can adjust if needed)

### New Assignments
Default type is homework (practiceHomework), so:
- New assignments default to "Estimated Work Time"
- Makes sense as homework is most common use case

---

## Localization Considerations

The current implementation uses hard-coded English strings. For full localization support, these should be moved to localized strings:

```swift
private func timeEstimateLabel(_ type: TaskType) -> String {
    switch type {
    case .exam, .quiz:
        return NSLocalizedString("task.time.study", comment: "Estimated Study Time")
    case .practiceHomework, .reading, .project, .review:
        return NSLocalizedString("task.time.work", comment: "Estimated Work Time")
    }
}
```

**Future Enhancement:** Add localization keys for these labels.

---

## User Feedback

### Expected Benefits
1. **Clearer expectations** - Users know what they're estimating
2. **Better planning** - Different mental models for work vs. study
3. **Task understanding** - Reinforces the nature of each task type
4. **Professional terminology** - Uses appropriate academic language

---

## Related Features

### Other Time Labels
These views also display time information but weren't changed:
- Planner view: Session duration (uses generic "minutes")
- Dashboard: Event time ranges (uses date/time format)
- Timer: Active timing (uses timer display)

### Consistent Terminology
The "Work Time" / "Study Time" distinction should be considered for:
- Planner time block labels
- Calendar event descriptions
- Timer session naming

---

## Before & After Summary

| Location | Before | After (Homework) | After (Exam) |
|----------|--------|------------------|--------------|
| Detail View | "Estimated Time: 60 minutes" | "Estimated Work Time: 60 minutes" | "Estimated Study Time: 60 minutes" |
| Editor | "Estimated Minutes: 60" | "Estimated Work Time: 60 min" | "Estimated Study Time: 60 min" |

---

## Code Changes Summary

**Files Modified:** 1
- `iOS/Scenes/IOSCorePages.swift`

**Functions Added:** 2
- `IOSTaskDetailView.timeEstimateLabel(_:)` - Helper for detail view
- `IOSTaskEditorView.timeEstimateLabel(_:)` - Helper for editor view

**Lines Changed:** ~10
- Detail view: 1 line + 8 lines (helper function)
- Editor view: 1 line + 8 lines (helper function)

**Complexity:** Low
- Simple switch statement
- No state changes
- No external dependencies

---

## Conclusion

Successfully updated time estimation labels to be context-aware:

✅ **Work Time** - For productive tasks (Homework, Reading, Project, Review)  
✅ **Study Time** - For test preparation (Exam, Quiz)  
✅ **Consistent** - Same logic in detail view and editor  
✅ **Dynamic** - Updates immediately when type changes  
✅ **Clear** - Users understand what they're estimating  

The change provides better clarity about task nature and helps users make more accurate time estimates based on whether they're producing work or preparing for assessments.

**Status:** COMPLETE ✅  
**Production Ready:** Yes  
**Impact:** User-facing label change only, no logic changes
