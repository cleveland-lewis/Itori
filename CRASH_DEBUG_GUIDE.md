# Runtime Crash Debugging Guide

## Error
```
Thread 1: EXC_BREAKPOINT (code=1, subcode=0x105348ec4)
Consecutive statements on a line must be separated by ';'
```

## Potential Root Causes

### 1. Persistence Decoding Failure (Most Likely)
New `deletedAt` fields were added to models. If existing save files don't have these fields, decoding might fail.

**Check:**
- Look in Console for decode errors
- Check if crash happens in `CoursesStore.load()` or `AssignmentsStore.load()`

**Fix:**
Ensure all new optional fields use `decodeIfPresent`:

```swift
// In CourseModels.swift and AssignmentModels.swift
public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    // ... existing fields ...
    deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
}
```

### 2. activeSemesterIds Not Initialized
If `activeSemesterIds` is empty on launch, views might try to access courses from no semesters.

**Check:**
- Add breakpoint in `CoursesStore.init()`
- Verify `activeSemesterIds` gets populated

**Fix:**
Add initialization in CoursesStore:

```swift
public init() {
    // ... load data ...
    
    // Initialize activeSemesterIds if empty
    if activeSemesterIds.isEmpty {
        if let currentId = currentSemesterId {
            activeSemesterIds = [currentId]
        } else if let mostRecent = semesters
            .filter({ !$0.isArchived && !$0.isDeleted })
            .sorted(by: { $0.startDate > $1.startDate })
            .first {
            activeSemesterIds = [mostRecent.id]
        }
    }
}
```

### 3. Syntax Error in AppSettingsModel (Less Likely)
The error message mentions "Consecutive statements" which could be a compiler error, not runtime.

**Check:**
- Look at `AppSettingsModel.swift` line 221-224
- Ensure comment and static let are properly formatted

**Current Code:**
```swift
final class AppSettingsModel: ObservableObject, Codable {
    /// Shared singleton used across the app. Loaded from persisted storage when available.
    static let shared: AppSettingsModel = {
        return AppSettingsModel.load()
    }()
```

This looks correct. If compiler complains, try:
```swift
final class AppSettingsModel: ObservableObject, Codable {
    // Shared singleton used across the app.
    static let shared: AppSettingsModel = {
        return AppSettingsModel.load()
    }()
```

### 4. Force Unwrap in Modified Code
Check for any `!` operators added in modified files.

**Files to Check:**
- CoursesStore.swift (lines with softDeleteCourse, restoreCourse)
- AssignmentsStore.swift (lines with cascade operations)
- DataIntegrityCoordinator.swift

**Pattern to Avoid:**
```swift
let course = courses.first(where: { $0.id == id })!  // BAD
```

**Better:**
```swift
guard let course = courses.first(where: { $0.id == id }) else { return }  // GOOD
```

### 5. Missing CodingKeys
If you added `deletedAt` but didn't add it to CodingKeys enum, encoding/decoding will fail.

**Check:**
```swift
enum CodingKeys: String, CodingKey {
    // ... existing keys ...
    case deletedAt  // Must be present
}
```

### 6. AppStorage Key Conflict
The LOG_DEV function accesses `AppSettingsModel.shared.devModeEnabled`. If this is called before AppSettings is initialized, it could crash.

**Fix:**
Make LOG_DEV check more defensive:
```swift
func LOG_DEV(...) {
    guard let settings = try? AppSettingsModel.shared,
          settings.devModeEnabled else { return }
    // ... logging code ...
}
```

## Debugging Steps

### Step 1: Enable Exception Breakpoint
1. In Xcode, open Breakpoint Navigator (⌘8)
2. Click + and add "Exception Breakpoint"
3. Set to break on "All Objective-C Exceptions"
4. Run app - it will stop at exact crash line

### Step 2: Check Console Output
Look for:
- `Fatal error: ...`
- `keyNotFound(...)`
- `typeMismatch(...)`
- `valueNotFound(...)`

### Step 3: Clean Build
1. Product → Clean Build Folder (⌘⇧K)
2. Delete DerivedData: `~/Library/Developer/Xcode/DerivedData`
3. Rebuild

### Step 4: Reset Simulator
If crash is persistence-related:
1. Simulator → Device → Erase All Content and Settings
2. Rebuild and run - should work with fresh data

### Step 5: Temporary Disable New Features
Comment out:
```swift
// In CoursesStore
// @Published public var activeSemesterIds: Set<UUID> = []

// In models
// public var deletedAt: Date?
```

If app runs, re-enable one at a time to isolate issue.

## Quick Fixes to Try

### Fix 1: Safe Initialization
In `CoursesStore.swift`, add after loading:
```swift
private func load() {
    // ... existing load code ...
    
    // Ensure activeSemesterIds is never empty
    if activeSemesterIds.isEmpty, let firstSemester = semesters.first(where: { !$0.isDeleted }) {
        activeSemesterIds = [firstSemester.id]
    }
}
```

### Fix 2: Safe Decoding
In `CourseModels.swift` and `AssignmentModels.swift`:
```swift
// Add to CodingKeys
case deletedAt

// In init(from decoder:)
deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)

// In encode(to encoder:)
try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
```

### Fix 3: Defensive LOG_DEV
In `DeveloperLogging.swift`:
```swift
func LOG_DEV(...) {
    // Add safety check
    guard let settings = AppSettingsModel.shared as? AppSettingsModel,
          settings.devModeEnabled else {
        return
    }
    // ... rest of logging ...
}
```

### Fix 4: Remove LOG_DEV Temporarily
Comment out all LOG_DEV calls in AIEngine.swift temporarily to see if that's the issue:
```swift
// LOG_DEV(.info, "LLM", "Message", metadata: [...])
```

## Expected Crash Locations

Most likely crash points:
1. `CoursesStore.init()` - Loading from disk
2. `AppSettingsModel.load()` - Decoding settings
3. First view that accesses `activeCourses` or `activeSemesters`
4. AIEngine init if LOG_DEV is called too early

## Testing After Fix

1. Fresh install (clean simulator) should work
2. Upgrade from old data should work (backward compatibility)
3. Delete course → tasks cascade
4. Multiple active semesters work
5. Dev mode logging works when enabled

## If All Else Fails

Revert specific commits:
```bash
git log --oneline -10  # Find recent commits
git revert <commit-hash>  # Revert problematic commit
```

Or create a new branch from last known good state:
```bash
git checkout -b hotfix/crash-fix main
git cherry-pick <good-commits>  # Selectively apply working changes
```

---

**Priority:** Fix crash first, then complete features.
**Estimated Time:** 30-60 minutes to identify and fix.
