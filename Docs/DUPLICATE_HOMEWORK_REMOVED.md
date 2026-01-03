# Duplicate Homework Category Removed - COMPLETE ✅

## Summary
Removed the duplicate "Homework" option from the assignment category dropdown. There were two enum cases (`homework` and `practiceHomework`) both displaying as "Homework", causing confusion in the UI.

## Problem
The category picker showed duplicate "Homework" entries:
```
Reading
Exam
Homework  ← First occurrence
✓ Homework  ← Second occurrence (selected)
Quiz
Review
Project
```

## Root Cause
Two separate enum cases mapped to the same display name:

**AssignmentCategory enum:**
```swift
case reading, exam, homework, practiceHomework, quiz, review, project

case .homework, .practiceHomework: return "Homework"  // Both showed "Homework"
```

**TaskType enum (AIScheduler.swift):**
```swift
case practiceHomework  // Also mapped to "Homework"
```

## Solution
Consolidated to single `homework` case:

### 1. AssignmentCategory (SharedPlanningModels.swift)
**Before:**
```swift
case reading, exam, homework, practiceHomework, quiz, review, project

case .homework, .practiceHomework: return "Homework"
```

**After:**
```swift
case reading, exam, homework, quiz, review, project

case .homework: return "Homework"
```

### 2. TaskType (AIScheduler.swift)
**Before:**
```swift
case practiceHomework
```

**After:**
```swift
case homework

// Decoder handles backward compatibility
case "homework", "problemSet", "practiceHomework": self = .homework
```

### 3. Global Replacement
Replaced all 68 occurrences of `.practiceHomework` with `.homework` across the codebase.

## Files Modified

### Core Models
- `SharedCore/Models/SharedPlanningModels.swift`
  - Removed `practiceHomework` from enum
  - Updated display name logic
  - Updated default parameters

### Scheduler
- `SharedCore/Features/Scheduler/AIScheduler.swift`
  - Renamed `practiceHomework` to `homework`
  - Added backward compatibility in decoder

### All References (68 total)
- macOS views and scenes
- iOS views and scenes  
- Test files
- Extensions
- View models

## Backward Compatibility

### Data Migration
The decoder handles old data:
```swift
case "homework", "problemSet", "practiceHomework": self = .homework
```

Existing assignments with `practiceHomework` will automatically map to `homework`.

## UI Result

### Before
```
Category picker:
- Reading
- Exam
- Homework
- Homework  ← DUPLICATE
- Quiz
- Review
- Project
```

### After
```
Category picker:
- Reading
- Exam
- Homework  ← Single entry
- Quiz
- Review
- Project
```

## Testing

To verify:
1. Create new assignment
2. Click Category dropdown
3. Verify only ONE "Homework" option appears
4. Select Homework and save
5. Edit existing assignments with old `practiceHomework`
6. Verify they show "Homework" correctly

## Build Status
✅ **BUILD SUCCEEDED** - All platforms

## Summary
Successfully removed the duplicate "Homework" category by consolidating `homework` and `practiceHomework` into a single `homework` enum case. All 68 references updated, backward compatibility maintained through decoder logic.
