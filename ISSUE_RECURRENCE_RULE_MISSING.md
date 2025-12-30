# [BUG] Missing RecurrenceRule Type Breaks Build

## Priority
🔴 **Critical** - Blocks all unit tests

## Description
The `RecurrenceRule` type is referenced throughout the codebase but is never defined, causing compilation failures that prevent running unit tests.

## Error Messages
```
Cannot find type 'RecurrenceRule' in scope (3 occurrences)
Cannot find 'RecurrenceRule' in scope
```

## Affected Files
- `SharedCore/Features/Scheduler/AIScheduler.swift` (lines 62, 71, 149, 211-226)
- `SharedCore/State/CalendarManager.swift`
- `SharedCore/Views/Legacy/UIStubs.swift`

## Context
`AppTask` struct references `RecurrenceRule`:
```swift
struct AppTask: Codable, Equatable, Hashable {
    // ...
    let recurrence: RecurrenceRule?  // ❌ Type not defined
    // ...
}
```

The code expects `RecurrenceRule` to support:
- `.preset(.daily)`, `.preset(.weekly)`, `.preset(.monthly)`, `.preset(.yearly)`
- `RecurrenceRule(frequency: .weekly, interval: 2, end: .never, skipPolicy: .init())`
- Properties: `frequency`, `interval`, `end`, `skipPolicy`

## Possible Confusion
There are TWO similar types in the codebase:
1. **`TaskRecurrence`** (simple enum) - Recently created in `SharedCore/Models/TaskRecurrence.swift`
   - Cases: `.none`, `.daily`, `.weekly`, `.biweekly`, `.monthly`
   - Simple string-based enum
   
2. **`RecurrenceRule`** (complex struct) - Referenced but not defined
   - Should have frequency, interval, end date, skip policy
   - More powerful EventKit-style recurrence

## Proposed Solution
**Option A:** Define RecurrenceRule struct
```swift
public struct RecurrenceRule: Codable, Equatable, Hashable {
    public enum Frequency: String, Codable {
        case daily, weekly, monthly, yearly
    }
    
    public enum End: Codable, Equatable, Hashable {
        case never
        case afterOccurrences(Int)
        case onDate(Date)
    }
    
    public struct SkipPolicy: Codable, Equatable, Hashable {
        // Define skip behavior for recurring tasks
    }
    
    public let frequency: Frequency
    public let interval: Int  // e.g., every 2 weeks
    public let end: End
    public let skipPolicy: SkipPolicy
    
    public static func preset(_ frequency: Frequency) -> RecurrenceRule {
        RecurrenceRule(frequency: frequency, interval: 1, end: .never, skipPolicy: .init())
    }
}
```

**Option B:** Unify with TaskRecurrence
- Extend `TaskRecurrence` to handle all cases
- Replace all `RecurrenceRule` references with `TaskRecurrence`
- Add backward compatibility for complex rules if needed

## Steps to Reproduce
1. Run unit tests: `xcodebuild test -scheme RootsTests -destination 'platform=macOS'`
2. Build fails with "Cannot find type 'RecurrenceRule'"

## Impact
- ❌ Unit tests cannot run
- ❌ CI/CD blocked
- ❌ Test-driven development blocked

## Related
- May be related to recent work on recurring tasks
- `TaskRecurrence` enum was created but `RecurrenceRule` was not migrated

## Environment
- macOS
- Xcode (current version)
- Test suite: RootsTests

---

**Labels:** `bug`, `critical`, `build-failure`, `testing`, `models`
