# [DISCUSSION] TaskRecurrence vs RecurrenceRule - Type Confusion

## Priority
🟡 **Medium** - Architectural clarity needed

## Description
The codebase has two competing types for task recurrence with unclear boundaries and responsibilities. This creates confusion and inconsistent usage.

## The Two Types

### 1. TaskRecurrence (Simple Enum)
**Location:** `SharedCore/Models/TaskRecurrence.swift`  
**Created:** Recently (as part of recurring tasks feature)

```swift
public enum TaskRecurrence: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
}
```

**Characteristics:**
- ✅ Simple, easy to use
- ✅ Works well for UI (picker, form field)
- ✅ Already implemented and working
- ❌ Limited expressiveness (no "every 3 days", no end dates)

**Used In:**
- `IOSCorePages.swift` - Form picker
- `PlannerPageView.swift` - Task drafts

### 2. RecurrenceRule (Complex Struct)
**Location:** ❌ **Not Defined** (only referenced)

**Expected Structure:**
```swift
public struct RecurrenceRule: Codable, Equatable, Hashable {
    let frequency: Frequency  // daily, weekly, monthly, yearly
    let interval: Int        // every N days/weeks/months
    let end: End            // never, after N times, or by date
    let skipPolicy: SkipPolicy
}
```

**Characteristics:**
- ✅ Powerful, flexible
- ✅ Can express complex patterns (EventKit-style)
- ❌ Not implemented
- ❌ More complex API
- ❌ Overkill for most use cases?

**Referenced In:**
- `AIScheduler.swift` - AppTask.recurrence property
- Legacy migration code - Converting old string-based recurrence

## The Problem

### Current State
- `AppTask.recurrence` expects `RecurrenceRule?` (doesn't exist)
- UI uses `TaskRecurrence` enum (exists, works)
- No bridge between the two types
- Build fails because RecurrenceRule is missing

### Questions to Answer
1. **Do we need both?**
   - Complex rules needed? → Yes, keep both
   - Simple patterns only? → Use TaskRecurrence everywhere

2. **If we need both, how do they relate?**
   ```swift
   // Option A: TaskRecurrence is a simplified preset
   enum TaskRecurrence {
       var asRule: RecurrenceRule {
           switch self {
           case .daily: return .preset(.daily)
           case .weekly: return .preset(.weekly)
           // ...
           }
       }
   }
   
   // Option B: RecurrenceRule can serialize to/from TaskRecurrence
   extension RecurrenceRule {
       var simplified: TaskRecurrence? {
           // Return TaskRecurrence if simple pattern, nil if complex
       }
   }
   ```

3. **What do users actually need?**
   - Homework every week? → TaskRecurrence sufficient
   - Every other Tuesday until finals? → Need RecurrenceRule
   - Skip weekends? → Need RecurrenceRule

## Proposed Solutions

### Option A: Keep Both (Recommended if complex rules needed)
```swift
// Simple UI-friendly presets
public enum TaskRecurrence: String, Codable {
    case none, daily, weekly, biweekly, monthly
    
    func toRule() -> RecurrenceRule? {
        switch self {
        case .none: return nil
        case .daily: return .preset(.daily)
        case .weekly: return .preset(.weekly)
        case .biweekly: return RecurrenceRule(frequency: .weekly, interval: 2, ...)
        case .monthly: return .preset(.monthly)
        }
    }
}

// Powerful backing model
public struct RecurrenceRule: Codable, Equatable, Hashable {
    // Full EventKit-style implementation
}

// AppTask stores the complex version
struct AppTask {
    let recurrence: RecurrenceRule?
    
    // Convenience for UI
    var simpleRecurrence: TaskRecurrence {
        recurrence?.simplified ?? .none
    }
}
```

### Option B: Use Only TaskRecurrence (Simpler)
```swift
// Extend TaskRecurrence with more options if needed
public enum TaskRecurrence: String, Codable {
    case none, daily, weekly, biweekly, monthly
    // Add more presets as needed
    case workdays  // Mon-Fri
    case weekends  // Sat-Sun
}

// Update AppTask
struct AppTask {
    let recurrence: TaskRecurrence  // Simpler, no optional
}
```

### Option C: Rename and Unify
```swift
// Rename TaskRecurrence → RecurrencePreset
public enum RecurrencePreset: String, Codable {
    case none, daily, weekly, biweekly, monthly
}

// Define RecurrenceRule as complex type
public struct RecurrenceRule: Codable {
    // Can be created from preset or custom
    static func preset(_ p: RecurrencePreset) -> RecurrenceRule?
}
```

## Decision Criteria

### Use Option A (Both Types) If:
- ✅ Need to support complex rules (skip dates, end conditions)
- ✅ Want EventKit parity
- ✅ Have bandwidth to implement full RecurrenceRule

### Use Option B (TaskRecurrence Only) If:
- ✅ Simple recurrence is sufficient for v1
- ✅ Want faster implementation
- ✅ Can add complexity later if needed

## Impact
- **Build:** Blocks tests until RecurrenceRule exists OR AppTask migrated to TaskRecurrence
- **UX:** Simple enum probably sufficient for most students
- **Data Migration:** Existing tasks may have string-based recurrence that needs converting

## Next Steps
1. **Decide:** Which option to implement
2. **Implement:** Create RecurrenceRule OR migrate to TaskRecurrence
3. **Migrate:** Update all AppTask initializer call sites
4. **Test:** Ensure recurring tasks work end-to-end

## Related Issues
- Blocks: #[RecurrenceRule Missing Issue]
- Blocks: #[AppTask Init Call Sites Issue]

---

**Labels:** `discussion`, `architecture`, `models`, `recurring-tasks`, `decision-needed`
