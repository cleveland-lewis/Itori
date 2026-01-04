# [BUG] AppTask Initializer Call Sites Out of Sync

## Priority
🔴 **Critical** - Blocks all unit tests

## Description
Multiple call sites creating `AppTask` instances have mismatched arguments with the initializer signature, causing compilation failures.

## Error Messages
```
Extra arguments at positions #1, #2, #3, ... #21 in call
Missing argument for parameter 'from' in call
'nil' requires a contextual type (2 occurrences)
```

## Affected Files
- Test files throughout `Tests/` directory
- Production code creating AppTask instances

## Root Cause
The `AppTask` initializer signature was modified but not all call sites were updated:

**Current Initializer:**
```swift
init(
    id: UUID,
    title: String,
    courseId: UUID?,
    due: Date?,
    estimatedMinutes: Int,
    minBlockMinutes: Int,
    maxBlockMinutes: Int,
    difficulty: Double,
    importance: Double,
    type: TaskType,
    locked: Bool,
    attachments: [Attachment] = [],
    isCompleted: Bool = false,
    gradeWeightPercent: Double? = nil,
    gradePossiblePoints: Double? = nil,
    gradeEarnedPoints: Double? = nil,
    category: TaskType? = nil,
    dueTimeMinutes: Int? = nil,
    recurrence: RecurrenceRule? = nil,  // ⚠️  Note: RecurrenceRule doesn't exist
    recurrenceSeriesID: UUID? = nil,
    recurrenceIndex: Int? = nil
)
```

**Issues:**
1. New parameters added (`recurrence`, `recurrenceSeriesID`, `recurrenceIndex`) but old call sites not updated
2. Some call sites may be passing arguments positionally instead of by name
3. Confusion between `init()` and `init(from: Decoder)` in test code

## Examples of Breaking Calls
```swift
// ❌ Old style - missing new parameters
let task = AppTask(
    id: UUID(),
    title: "Test",
    courseId: nil,
    due: Date(),
    estimatedMinutes: 60,
    minBlockMinutes: 20,
    maxBlockMinutes: 120,
    difficulty: 0.5,
    importance: 0.5,
    type: .homework,
    locked: false
)

// ❌ Wrong initializer - trying to use decoder init incorrectly
let task = AppTask(from: someData)  // Missing decoder parameter

// ❌ Nil literal without type context
let task = someFunction(recurrence: nil)  // Type can't be inferred
```

## Fix Strategy

### Option A: Update All Call Sites (Recommended)
1. Search for all `AppTask(` initializations
2. Add default values for new parameters
3. Use labeled arguments

```swift
// ✅ Correct - all parameters labeled, new ones have defaults
let task = AppTask(
    id: UUID(),
    title: "Test",
    courseId: nil,
    due: Date(),
    estimatedMinutes: 60,
    minBlockMinutes: 20,
    maxBlockMinutes: 120,
    difficulty: 0.5,
    importance: 0.5,
    type: .homework,
    locked: false,
    attachments: [],
    isCompleted: false,
    recurrence: nil  // Or use .none from TaskRecurrence if converted
)
```

### Option B: Add Convenience Initializers
```swift
extension AppTask {
    // Minimal initializer for tests
    static func test(
        title: String = "Test Task",
        due: Date? = nil,
        type: TaskType = .homework
    ) -> AppTask {
        AppTask(
            id: UUID(),
            title: title,
            courseId: nil,
            due: due,
            estimatedMinutes: 60,
            minBlockMinutes: 20,
            maxBlockMinutes: 120,
            difficulty: 0.5,
            importance: 0.5,
            type: type,
            locked: false
        )
    }
}
```

## Finding All Affected Call Sites
```bash
# Search for AppTask initializations
grep -r "AppTask(" --include="*.swift" Tests/
grep -r "AppTask(" --include="*.swift" SharedCore/
grep -r "AppTask(" --include="*.swift" Platforms/
```

## Steps to Reproduce
1. Run unit tests: `xcodebuild test -scheme ItoriTests -destination 'platform=macOS'`
2. Build fails with argument mismatch errors

## Impact
- ❌ Unit tests cannot compile
- ❌ Cannot create new AppTask instances
- ❌ Test coverage broken

## Related Issues
- Depends on: #[RecurrenceRule Missing Issue]
- Once RecurrenceRule is defined, recurrence parameter type will be resolved

## Environment
- macOS
- Xcode (current version)
- Test suite: ItoriTests

---

**Labels:** `bug`, `critical`, `build-failure`, `testing`, `refactoring`, `models`
