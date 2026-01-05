# MainActor Recursive Lock Analysis

## Critical Issue: App Crashes on Launch (macOS + Tests)

**Status:** BLOCKING - App cannot launch, tests cannot run  
**Error:** `libdispatch.dylib: BUG IN CLIENT OF LIBDISPATCH: trying to lock recursively`  
**Affects:** macOS app launch, all test execution

---

## Root Cause

`ItoriApp.init()` synchronously accesses multiple `@MainActor` singleton stores during static initialization:

```swift
@main
struct ItoriApp: App {
    @StateObject private var appSettings = AppSettingsModel.shared
    @StateObject private var gradesStore = GradesStore.shared        // @MainActor
    @StateObject private var plannerStore = PlannerStore.shared      // @MainActor
    @StateObject private var plannerCoordinator = PlannerCoordinator.shared  // @MainActor
    @StateObject private var appModel = AppModel.shared
    @StateObject private var calendarManager = CalendarManager.shared  // @MainActor
    // ... 8 more @MainActor singletons
    
    init() {
        let assignments = AssignmentsStore.shared  // @MainActor - recursive lock!
        // ...
    }
}
```

### Why It Crashes

1. Test framework or SwiftUI initializes `ItoriApp` on MainActor
2. `ItoriApp.init()` runs synchronously and accesses `AssignmentsStore.shared`
3. `AssignmentsStore` is marked `@MainActor`, so `static let shared = AssignmentsStore()` tries to acquire MainActor executor
4. **But we're already inside MainActor context from step 1**
5. Dispatch tries to "lock recursively" → `EXC_BREAKPOINT` crash

### Affected Stores (@MainActor)

- `AssignmentsStore`
- `GradesStore`
- `PlannerStore`
- `CoursesStore`
- `EventsCountStore`
- `SyllabusParsingStore`
- `PlannerCoordinator`
- `CalendarManager`
- `StorageAggregateStore`
- `AssignmentPlansStore`
- `AssignmentPlanStore`

---

## Attempted Fixes (Failed)

### ❌ Removed LOG_DEV Calls
- **Rationale:** LOG_DEV accesses `Diagnostics.shared` which has `@MainActor @Published` properties
- **Result:** Still crashes - LOG_DEV was not the culprit

### ❌ Disabled iCloud Observer Setup
- **Rationale:** `setupICloudObserver()` registers NotificationCenter observer during init
- **Result:** Still crashes - observer registration was not the issue

### ❌ Removed @MainActor from AssignmentsStore
- **Rationale:** Prevent MainActor isolation during static initialization
- **Result:** Still crashes - other @MainActor stores still accessed

### ❌ Attempted Test Architecture Refactor
- **Rationale:** Create test-only app entry point without singleton dependencies
- **Result:** Incomplete - requires full lazy initialization pattern

---

## Proper Solution (v1.1)

### Lazy Initialization Pattern

**Goal:** Defer `@MainActor` singleton initialization until after app launch completes.

#### Phase 1: Dependency Injection Container

```swift
@MainActor
final class AppDependencies {
    static let production = AppDependencies()
    
    // Lazy-initialized singletons (not accessed during init)
    private(set) lazy var appSettings: AppSettingsModel = .shared
    private(set) lazy var assignmentsStore: AssignmentsStore = .shared
    private(set) lazy var gradesStore: GradesStore = .shared
    private(set) lazy var plannerStore: PlannerStore = .shared
    // ... all other stores
    
    private init() {}
}
```

#### Phase 2: Refactor ItoriApp

**Before (broken):**
```swift
init() {
    let assignments = AssignmentsStore.shared  // Recursive lock!
    _timerManager = StateObject(wrappedValue: TimerManager())
}
```

**After (fixed):**
```swift
@StateObject private var dependencies = AppDependencies.production

var body: some Scene {
    WindowGroup {
        ContentView()
            .environmentObject(dependencies.assignmentsStore)  // Lazy access
            .environmentObject(dependencies.gradesStore)
            // ...
    }
}
```

#### Phase 3: Update Views

**Before:**
```swift
@StateObject private var assignmentsStore = AssignmentsStore.shared
```

**After:**
```swift
@EnvironmentObject private var assignmentsStore: AssignmentsStore
```

---

## Temporary Workaround (v1.0)

**Status:** Tests disabled, app launches manually

1. ✅ Removed `@MainActor` from `AssignmentsStore` (temporary, not thread-safe)
2. ✅ Disabled iCloud observer in `AppSettingsModel.init()` (temporary, no sync)
3. ✅ Replaced `LOG_DEV` with `print` in AppSettingsModel (cleaner logging)
4. ❌ Tests remain disabled - cannot run until lazy init implemented

**Risk Level:** MEDIUM
- App builds and can be manually launched from Xcode
- Tests fail immediately on initialization
- `AssignmentsStore` now lacks MainActor thread safety guarantees
- iCloud sync disabled for energy settings

---

## Timeline

- **v1.0 (current):** Ship with workaround, manual QA only, no automated tests
- **v1.1 (2-3 weeks):** Implement lazy initialization pattern, restore tests
- **v1.2+:** Full concurrency audit and MainActor correctness verification

---

## References

- `ItoriApp.swift` (Platforms/macOS/ItoriApp.swift) - app entry point
- `AssignmentsStore.swift` - primary @MainActor store
- `AppSettingsModel.swift` - iCloud observer setup
- Test logs: `/Users/clevelandlewis/Library/Developer/Xcode/DerivedData/.../Logs/Test/`
- Error message: "libdispatch.dylib: BUG IN CLIENT OF LIBDISPATCH: trying to lock recursively"

---

**Last Updated:** 2026-01-05  
**Severity:** CRITICAL (blocking tests + fragile launch)  
**Owner:** Architecture/Concurrency workstream
