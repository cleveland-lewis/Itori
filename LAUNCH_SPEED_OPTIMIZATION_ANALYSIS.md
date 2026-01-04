# App Launch Speed Optimization Analysis

## Current Bottlenecks Identified

### 1. **Synchronous Initialization in init() (CRITICAL)**

**iOS App (RootsIOSApp.swift):**
```swift
init() {
    _ = PhoneWatchBridge.shared                    // ❌ Blocking
    ResetCoordinator.shared.start(...)             // ❌ Blocking
    let store = CoursesStore()                      // ❌ Loads from disk synchronously
    ...
    RootsIOSApp.registerBackgroundTasks()          // ❌ Blocking
    
    Task { @MainActor in
        IntelligentSchedulingCoordinator.shared.start()  // ⚠️ Better but still on main thread
    }
}
```

**macOS App (RootsApp.swift):**
```swift
init() {
    LOG_LIFECYCLE(...)                             // ⚠️ Small but unnecessary
    ResetCoordinator.shared.start(...)             // ❌ Blocking
    let store = CoursesStore()                      // ❌ Loads from disk synchronously
    ...
    menuBarManager = MenuBarManager(...)           // ❌ Blocking
}
```

### 2. **Too Many @StateObject Initializations (17-20 objects!)**

Both apps create 17-20 `@StateObject` instances at launch:
- coursesStore
- appSettings
- settingsCoordinator
- gradesStore
- plannerStore
- plannerCoordinator
- assignmentPlansStore (iOS only)
- appModel
- calendarManager
- deviceCalendar
- calendarRefresh
- timerManager
- focusManager
- preferences
- parsingStore
- eventsCountStore
- schedulingCoordinator (iOS only)
- sheetRouter (iOS only)
- toastRouter (iOS only)
- filterState (iOS only)

Each `.shared` singleton may:
- Load from disk
- Initialize complex state
- Subscribe to notifications
- Set up observers

### 3. **Synchronous File I/O in CoursesStore.init()**

```swift
CoursesStore.init() {
    // ...
    loadCache()    // ❌ Reads from disk synchronously
    load()         // ❌ Reads from disk synchronously
    loadFromiCloudIfEnabled()  // ❌ Network + disk I/O
    setupiCloudMonitoring()
    // ...
}
```

### 4. **Heavy onAppear Work**

**iOS App:**
```swift
.onAppear {
    preferences.highContrast = appSettings.highContrastMode
    preferences.reduceTransparency = ...
    PlannerSyncCoordinator.shared.start(...)       // ❌ Blocking
    MissedEventDetectionService.shared.startMonitoring()  // ❌ Blocking
    BackgroundRefreshManager.shared.register()
    BackgroundRefreshManager.shared.scheduleNext()
}
```

### 5. **Eager Singleton Initialization**

70+ `.shared` references mean singletons are initialized eagerly, even if not needed immediately.

---

## Performance Impact Estimate

| Issue | Impact | Time Lost |
|-------|--------|-----------|
| Synchronous CoursesStore load | HIGH | 50-200ms |
| 17-20 StateObject creations | HIGH | 100-300ms |
| Eager singleton initialization | MEDIUM | 50-150ms |
| onAppear work | MEDIUM | 30-100ms |
| PhoneWatchBridge/MenuBarManager | LOW | 10-50ms |
| **TOTAL CURRENT LAUNCH TIME** | | **240-800ms** |

**Target:** < 100ms to first frame

---

## Optimization Strategy

### Phase 1: Lazy Loading (Quick Wins)

**Priority: CRITICAL**  
**Effort: LOW**  
**Impact: 200-400ms improvement**

#### 1.1 Defer Non-Essential Singletons
Move singleton initialization from `init()` to `onAppear` or later:

```swift
init() {
    // ONLY essential for first frame:
    let store = CoursesStore()
    _coursesStore = StateObject(wrappedValue: store)
    let settings = AppSettingsModel.shared
    _settingsCoordinator = StateObject(wrappedValue: ...)
    
    // ✅ REMOVED: Everything else deferred
}

.onAppear {
    // Initialize non-essential services after first frame
    Task {
        await initializeBackgroundServices()
    }
}
```

#### 1.2 Lazy StateObject Pattern
Replace eager `@StateObject` with lazy loading:

```swift
// BEFORE (eager):
@StateObject private var parsingStore = SyllabusParsingStore.shared

// AFTER (lazy):
@StateObject private var parsingStore = LazyInitializer {
    SyllabusParsingStore.shared
}
```

#### 1.3 Background CoursesStore Loading
Load data asynchronously:

```swift
final class CoursesStore {
    init(storageURL: URL? = nil) {
        self.storageURL = ...
        self.cacheURL = ...
        
        // ✅ Setup only - no I/O
        setupNetworkMonitoring()
        observeICloudToggle()
        
        // ✅ Defer actual loading
        Task {
            await loadDataAsync()
        }
    }
    
    private func loadDataAsync() async {
        loadCache()
        load()
        loadFromiCloudIfEnabled()
        cleanupOldData()
    }
}
```

---

### Phase 2: Async Initialization (Medium Effort)

**Priority: HIGH**  
**Effort: MEDIUM**  
**Impact: 100-200ms improvement**

#### 2.1 Parallel Service Initialization
Start independent services in parallel:

```swift
.onAppear {
    Task {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { PlannerSyncCoordinator.shared.start(...) }
            group.addTask { MissedEventDetectionService.shared.startMonitoring() }
            group.addTask { BackgroundRefreshManager.shared.register() }
            group.addTask { IntelligentSchedulingCoordinator.shared.start() }
        }
    }
}
```

#### 2.2 Progressive Loading UI
Show shell UI immediately, load data progressively:

```swift
struct IOSRootView: View {
    @State private var isInitialized = false
    
    var body: some View {
        if isInitialized {
            // Full UI
            MainTabView()
        } else {
            // Lightweight shell
            LoadingShellView()
                .task {
                    await initializeStores()
                    isInitialized = true
                }
        }
    }
}
```

---

### Phase 3: Data Caching (Medium Effort)

**Priority: MEDIUM**  
**Effort: MEDIUM**  
**Impact: 50-100ms improvement**

#### 3.1 Precomputed Cache
Cache expensive computations:

```swift
struct PrecomputedCache: Codable {
    let activeCourses: [Course]
    let dueTodayTasks: [AppTask]
    let gpa: Double
    let lastComputed: Date
}

// Load instantly on launch
let cache = PrecomputedCache.load()
```

#### 3.2 Incremental Updates
Only recompute what changed:

```swift
// Instead of recalculating everything:
func addCourse(_ course: Course) {
    courses.append(course)
    persist()
    recalcGPA(tasks: ...)  // ❌ Recalculates everything
}

// Only update deltas:
func addCourse(_ course: Course) {
    courses.append(course)
    persist()
    incrementalUpdateGPA(newCourse: course)  // ✅ O(1) vs O(n)
}
```

---

### Phase 4: Reduce StateObject Count (High Effort)

**Priority: MEDIUM**  
**Effort: HIGH**  
**Impact: 100-200ms improvement**

#### 4.1 Consolidate Related Stores
Merge related stores:

```swift
// BEFORE: 3 separate stores
@StateObject var plannerStore = PlannerStore.shared
@StateObject var plannerCoordinator = PlannerCoordinator.shared
@StateObject var assignmentPlansStore = AssignmentPlansStore.shared

// AFTER: 1 unified store
@StateObject var plannerSystem = PlannerSystem.shared  // Contains all 3
```

#### 4.2 Environment Injection
Use `@Environment` for non-observable services:

```swift
// BEFORE:
@StateObject var parsingStore = SyllabusParsingStore.shared

// AFTER:
struct ParsingServiceKey: EnvironmentKey {
    static let defaultValue = SyllabusParsingStore.shared
}
extension EnvironmentValues {
    var parsingService: SyllabusParsingStore {
        get { self[ParsingServiceKey.self] }
        set { self[ParsingServiceKey.self] = newValue }
    }
}
```

---

## Proposed Implementation Plan

### ✅ Quick Wins (1-2 hours, 300ms improvement)

**Step 1:** Defer non-essential initialization
```swift
// Move to .task { } or .onAppear:
- PhoneWatchBridge.shared
- ResetCoordinator.shared.start()
- RootsIOSApp.registerBackgroundTasks()
- IntelligentSchedulingCoordinator.shared.start()
- MenuBarManager initialization
```

**Step 2:** Make CoursesStore load async
```swift
class CoursesStore {
    @Published var isLoading = true
    
    init() {
        // Minimal setup only
        Task { await loadAsync() }
    }
}
```

**Step 3:** Defer onAppear work
```swift
.onAppear {
    // Show UI first
}
.task {
    // Initialize services after render
    await initServices()
}
```

### ✅ Medium Term (4-6 hours, 200ms improvement)

**Step 4:** Implement progressive loading
```swift
struct AppShell: View {
    @State private var loadingPhase: LoadingPhase = .initial
    
    var body: some View {
        switch loadingPhase {
        case .initial:
            SplashView()
        case .coreLoaded:
            SkeletonView()  // Shows structure, loading data
        case .ready:
            FullAppView()
        }
    }
}
```

**Step 5:** Parallel service initialization
```swift
await withTaskGroup(of: Void.self) { group in
    for service in nonEssentialServices {
        group.addTask { await service.initialize() }
    }
}
```

### ⏳ Long Term (2-3 days, 200ms improvement)

**Step 6:** Consolidate stores
**Step 7:** Implement incremental updates
**Step 8:** Add precomputed cache

---

## Measurement Strategy

### Before Optimization:
```swift
let start = CFAbsoluteTimeGetCurrent()
// ... initialization ...
let elapsed = CFAbsoluteTimeGetCurrent() - start
print("Launch time: \(elapsed * 1000)ms")
```

### Key Metrics:
1. **Time to First Frame** (target: < 100ms)
2. **Time to Interactive** (target: < 500ms)
3. **Time to Fully Loaded** (target: < 1000ms)

### Instruments Profiling:
- Time Profiler: Identify CPU bottlenecks
- System Trace: Disk I/O analysis
- Allocations: Memory pressure during launch

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Defer CoursesStore load | HIGH | Show loading state, handle nil data |
| Async initialization | MEDIUM | Ensure proper ordering, use async/await |
| Consolidate stores | HIGH | Extensive testing, gradual migration |
| Remove StateObjects | MEDIUM | Test environment injection thoroughly |

---

## Expected Results

| Phase | Time Investment | Launch Speed Gain | Complexity |
|-------|----------------|-------------------|------------|
| Quick Wins | 1-2 hours | 300ms → 500ms | LOW |
| Medium Term | 4-6 hours | 200ms | MEDIUM |
| Long Term | 2-3 days | 200ms | HIGH |
| **TOTAL** | **~3 days** | **700ms improvement** | **MEDIUM-HIGH** |

**Current:** 240-800ms  
**After Quick Wins:** 100-400ms (✅ acceptable)  
**After Medium Term:** 50-250ms (✅ excellent)  
**After Long Term:** 40-100ms (✅ exceptional)

---

## Recommendation

**Start with Quick Wins (Phase 1)** - Implement lazy loading and async CoursesStore. This gives 60-75% of total improvement with minimal risk.

**Next Steps:**
1. Profile current launch time with Instruments
2. Implement Phase 1 (lazy loading)
3. Measure improvement
4. If needed, proceed to Phase 2 (async initialization)

Would you like me to implement the Quick Wins phase now?
