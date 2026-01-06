# Dashboard Weekly Workload Label Fix

## Issue
The Weekly Workload chart on the macOS Dashboard displayed "practiceTest" (camelCase) in the legend instead of the properly formatted "Practice Test".

## Root Cause
The chart was using `.rawValue` on the `TaskType` enum, which returns the internal enum case name rather than a user-friendly display string.

**Problematic code:**
```swift
.foregroundStyle(by: .value("Category", item.category.rawValue))
//                                                  ^^^^^^^^ Shows "practiceTest"

.chartForegroundStyleScale(
    domain: TaskType.allCases.map { $0.rawValue },
    //                                 ^^^^^^^^ Shows "practiceTest"
    range: TaskType.allCases.map { mutedCategoryColor($0) }
)
```

## Solution
Added a `displayName` computed property to `TaskType` enum that returns properly formatted names for UI display.

### Files Modified

#### 1. SharedCore/Features/Scheduler/AIScheduler.swift
Added `displayName` property to TaskType enum:

```swift
var displayName: String {
    switch self {
    case .project: return "Project"
    case .exam: return "Exam"
    case .quiz: return "Quiz"
    case .homework: return "Homework"
    case .reading: return "Reading"
    case .review: return "Review"
    case .study: return "Study"
    case .practiceTest: return "Practice Test"  // ✓ Properly formatted
    }
}
```

#### 2. Platforms/macOS/Scenes/DashboardView.swift
Updated chart to use `.displayName`:

```swift
.foregroundStyle(by: .value("Category", item.category.displayName))
//                                                  ^^^^^^^^^^^ Now shows "Practice Test"

.chartForegroundStyleScale(
    domain: TaskType.allCases.map { $0.displayName },
    //                                 ^^^^^^^^^^^ Now shows "Practice Test"
    range: TaskType.allCases.map { mutedCategoryColor($0) }
)
```

## Benefits

### 1. Consistent Display Names
All TaskType values now have proper formatting:
- ✅ "Practice Test" (not "practiceTest")
- ✅ "Project" (not "project")
- ✅ "Homework" (not "homework")
- etc.

### 2. Reusable Across App
The `displayName` property can be used anywhere in the app that needs to show task type labels to users, ensuring consistency.

### 3. Maintains Data Integrity
The `.rawValue` is still used for:
- Data persistence (Core Data, JSON encoding)
- Internal logic and comparisons
- API communication

Only UI display uses `.displayName`.

## Testing
Verify on macOS:
1. Open Dashboard
2. Scroll to "Weekly Workload" chart
3. Check chart legend at bottom
4. Confirm "Practice Test" appears (not "practiceTest")
5. Verify all other category names are properly capitalized

## Future Localization
For internationalization, the `displayName` property can be updated to use `NSLocalizedString`:

```swift
var displayName: String {
    switch self {
    case .practiceTest: 
        return NSLocalizedString("task.type.practice_test", 
                                value: "Practice Test", 
                                comment: "Practice test task type")
    // ... etc
    }
}
```

## Date
2026-01-06
