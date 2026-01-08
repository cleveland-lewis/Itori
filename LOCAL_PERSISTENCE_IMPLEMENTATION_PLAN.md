# Local Persistence Implementation Plan for iOS

**Date:** January 8, 2025  
**Status:** Planning Complete - Ready for Implementation

---

## Executive Summary

Itori currently uses a **hybrid persistence architecture**:
- **CoreData** for structured relational data (via `PersistenceController`)
- **JSON file storage** for app state (via individual Store classes)
- **iCloud CloudKit sync** (optional) for cross-device synchronization

**Current Status:**
- ✅ macOS: Fully functional with CoreData + JSON hybrid
- ⚠️ iOS: Partial implementation - CoreData exists but not utilized by stores
- ❌ Stores use JSON-only persistence with iCloud sync

**Goal:** Implement identical persistence semantics on iOS to match macOS behavior.

---

## Current Architecture Analysis

### 1. CoreData Layer (Shared)

**Location:** `SharedCore/Persistence/`

**Files:**
- `PersistenceController.swift` - Main CoreData stack manager
- `Itori.xcdatamodeld/` - CoreData model definition

**Entities Defined:**
- ✅ `Semester` (SemesterMO)
- ✅ `Course` (CourseMO) 
- ✅ `Assignment` (AssignmentMO)
- ✅ `CourseOutlineNode` (CourseOutlineNodeMO)
- ✅ `CourseFile` (CourseFileMO)
- ✅ `FileParseResult` (FileParseResultMO)
- ✅ `PlannerAnalysis` (PlannerAnalysisMO)
- ❌ `Event` - Not in CoreData (needs addition)
- ❌ `Grade` - Not in CoreData (needs addition)
- ❌ `Activity` - Not in CoreData (needs addition)
- ❌ `AppTask` - Not in CoreData (needs addition)

**Migration Support:**
- ✅ Automatic lightweight migrations enabled
- ✅ Version tracking via `.xccurrentversion`
- ✅ Current version: `Itori.xcdatamodel` (v1)

### 2. JSON Store Layer (Shared)

**Location:** `SharedCore/State/`

**Active Stores:**
- `CoursesStore.swift` - Semesters, Courses, Outline Nodes, Course Files
- `AssignmentsStore.swift` - Tasks (AppTask)
- `GradesStore.swift` - Grade entries
- `PlannerStore.swift` - Planner analysis and sessions
- `EventsCountStore.swift` - Event tracking
- `ScheduledTestsStore.swift` - Practice tests
- `PracticeTestStore.swift` - Test results

**Persistence Pattern:**
```swift
// Each store manages its own JSON file
private let storageURL: URL  // Local cache
private lazy var iCloudURL: URL?  // Optional iCloud sync

// Save pattern
func saveCache() {
    let data = try JSONEncoder().encode(model)
    try data.write(to: storageURL)
}

// iCloud sync pattern (optional)
func saveToiCloud() {
    guard AppSettingsModel.shared.enableICloudSync else { return }
    try data.write(to: iCloudURL)
}
```

### 3. Data Models (Shared)

**Location:** `SharedCore/Models/`

**Core Models (Codable structs):**
- ✅ `Semester` - CourseModels.swift
- ✅ `Course` - CourseModels.swift
- ✅ `AppTask` - AIScheduler.swift (assignments)
- ✅ `GradeEntry` - GradesStore.swift
- ✅ `TimerActivity` - TimerModels.swift
- ✅ `Event` - PlannerModels.swift (needs verification)

**All models use:**
- `Codable` for JSON serialization
- `Identifiable` with UUID-based IDs
- `Hashable` for collection operations

---

## Problem Statement

### Current Issues

1. **Data Duplication**
   - CoreData schema exists but is unused on iOS
   - Stores bypass CoreData and use direct JSON I/O
   - Same data models defined twice (Codable structs + CoreData MOs)

2. **Inconsistent Persistence**
   - macOS may use CoreData repositories (partially)
   - iOS uses only JSON stores
   - Different code paths = different behaviors

3. **Missing CoreData Entities**
   - `Event`, `Grade`, `Activity`, `AppTask` not in CoreData model
   - Can't migrate to CoreData without schema updates

4. **Migration Risk**
   - Moving from JSON to CoreData requires data migration
   - No rollback mechanism if migration fails
   - User data loss risk

---

## Recommended Approach

### Option A: Dual-Write with JSON Primary (Recommended)

Keep JSON stores as primary, add CoreData as secondary for queries.

**Advantages:**
- ✅ Zero breaking changes
- ✅ Existing data keeps working
- ✅ Can validate CoreData without risk
- ✅ Easy rollback if issues found

**Disadvantages:**
- ⚠️ More complex code (dual writes)
- ⚠️ Potential sync issues if not careful

**Implementation:**
```swift
// In each Store
func saveBoth() {
    // 1. Save to JSON (primary)
    saveCache()
    
    // 2. Sync to CoreData (secondary)
    if AppSettingsModel.shared.enableCoreDataSync {
        syncToCoreData()
    }
}

// Read from JSON, verify with CoreData
func load() {
    loadCache()  // Primary
    if AppSettingsModel.shared.enableCoreDataSync {
        validateWithCoreData()
    }
}
```

### Option B: Migrate to CoreData Fully

Replace JSON stores with CoreData repositories.

**Advantages:**
- ✅ One source of truth
- ✅ Better queries and relationships
- ✅ Cleaner architecture long-term

**Disadvantages:**
- ❌ High risk (data migration required)
- ❌ Significant code changes
- ❌ Breaks existing JSON sync
- ❌ No easy rollback

### Option C: Keep Current (Status Quo)

No changes - continue with JSON stores.

**Advantages:**
- ✅ Works today
- ✅ Zero development time

**Disadvantages:**
- ❌ CoreData model unused
- ❌ No benefit from relational queries
- ❌ Technical debt accumulates

---

## Implementation Plan (Option A - Recommended)

### Phase 1: Extend CoreData Schema (2 hours)

**Goal:** Add missing entities to CoreData model

**Tasks:**
1. Open `Itori.xcdatamodeld` in Xcode
2. Add new entities:
   - `Event` (EventMO)
   - `Grade` (GradeMO)
   - `Activity` (ActivityMO)
   - `Task` (TaskMO) - for AppTask

3. Define attributes matching Codable models:
   ```
   Event:
   - id: UUID
   - title: String
   - startDate: Date
   - endDate: Date
   - isAllDay: Bool
   - notes: String?
   - courseId: UUID?
   - ...

   Grade:
   - id: UUID (derived from courseId)
   - courseId: UUID
   - percent: Double?
   - letter: String?
   - updatedAt: Date

   Task:
   - id: UUID
   - title: String
   - courseId: UUID?
   - due: Date?
   - estimatedMinutes: Int16
   - isCompleted: Bool
   - ...
   ```

4. Add relationships:
   - Course ↔ Tasks (one-to-many)
   - Course ↔ Grades (one-to-one)
   - Course ↔ Events (one-to-many)

5. Test model compiles and migrations work

**Files Modified:**
- `SharedCore/Persistence/Itori.xcdatamodeld/Itori.xcdatamodel/contents`

**Testing:**
```bash
# Clean build to verify model changes
xcodebuild clean build -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Phase 2: Create CoreData Repositories (4 hours)

**Goal:** Build repository pattern for each store

**Pattern:**
```swift
// SharedCore/Persistence/Repositories/TaskRepository.swift
import CoreData

final class TaskRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // CRUD operations
    func save(_ task: AppTask) throws {
        let mo = fetchOrCreate(id: task.id)
        mo.update(from: task)
        try context.save()
    }
    
    func fetch(id: UUID) -> AppTask? {
        let request = TaskMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first?.toModel()
    }
    
    func fetchAll() -> [AppTask] {
        let request = TaskMO.fetchRequest()
        return (try? context.fetch(request))?.map { $0.toModel() } ?? []
    }
    
    func delete(id: UUID) throws {
        guard let mo = fetchMO(id: id) else { return }
        context.delete(mo)
        try context.save()
    }
    
    // Conversion helpers
    private func fetchOrCreate(id: UUID) -> TaskMO {
        if let existing = fetchMO(id: id) {
            return existing
        }
        let mo = TaskMO(context: context)
        mo.id = id
        return mo
    }
    
    private func fetchMO(id: UUID) -> TaskMO? {
        let request = TaskMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
}

// Extension for conversions
extension TaskMO {
    func toModel() -> AppTask {
        AppTask(
            id: id ?? UUID(),
            title: title ?? "",
            courseId: courseId,
            due: due,
            estimatedMinutes: Int(estimatedMinutes),
            // ... all fields
            isCompleted: isCompleted
        )
    }
    
    func update(from task: AppTask) {
        self.id = task.id
        self.title = task.title
        self.courseId = task.courseId
        self.due = task.due
        self.estimatedMinutes = Int16(task.estimatedMinutes)
        // ... all fields
        self.isCompleted = task.isCompleted
    }
}
```

**Files to Create:**
- `SharedCore/Persistence/Repositories/TaskRepository.swift`
- `SharedCore/Persistence/Repositories/GradeRepository.swift`
- `SharedCore/Persistence/Repositories/EventRepository.swift`
- `SharedCore/Persistence/Repositories/ActivityRepository.swift`

**Testing:**
```swift
// Tests/Unit/SharedCore/TaskRepositoryTests.swift
func testSaveAndFetch() {
    let repo = TaskRepository(context: testContext)
    let task = AppTask(...)
    try! repo.save(task)
    
    let fetched = repo.fetch(id: task.id)
    XCTAssertEqual(fetched, task)
}
```

### Phase 3: Integrate Stores with Repositories (4 hours)

**Goal:** Add CoreData sync to existing stores without breaking JSON

**Pattern:**
```swift
// SharedCore/State/AssignmentsStore.swift
@MainActor
final class AssignmentsStore: ObservableObject {
    @Published var tasks: [AppTask] = [] {
        didSet {
            guard !isLoadingFromDisk else { return }
            
            // Primary: Save to JSON
            saveCache()
            
            // Secondary: Sync to CoreData
            Task.detached(priority: .utility) {
                await self.syncToCoreData()
            }
            
            // Optional: iCloud sync
            if isOnline && isSyncEnabled {
                saveToiCloud()
            }
        }
    }
    
    private var taskRepository: TaskRepository {
        TaskRepository(context: PersistenceController.shared.viewContext)
    }
    
    private func syncToCoreData() async {
        guard AppSettingsModel.shared.enableCoreDataSync else { return }
        
        let context = PersistenceController.shared.newBackgroundContext()
        let repo = TaskRepository(context: context)
        
        await context.perform {
            do {
                // Delete removed tasks
                let existingIDs = Set(repo.fetchAll().map { $0.id })
                let currentIDs = Set(self.tasks.map { $0.id })
                for deletedID in existingIDs.subtracting(currentIDs) {
                    try repo.delete(id: deletedID)
                }
                
                // Save/update all current tasks
                for task in self.tasks {
                    try repo.save(task)
                }
                
                LOG_DATA(.debug, "Persistence", "CoreData sync complete: \(self.tasks.count) tasks")
            } catch {
                LOG_DATA(.error, "Persistence", "CoreData sync failed: \(error)")
            }
        }
    }
    
    // Add validation method
    func validateWithCoreData() {
        guard AppSettingsModel.shared.enableCoreDataSync else { return }
        
        Task.detached(priority: .utility) {
            let repo = TaskRepository(context: PersistenceController.shared.viewContext)
            let coreDataTasks = repo.fetchAll()
            
            if coreDataTasks.count != tasks.count {
                LOG_DATA(.warning, "Persistence", "CoreData mismatch: \(coreDataTasks.count) vs \(tasks.count) tasks")
            }
        }
    }
}
```

**Files Modified:**
- `SharedCore/State/AssignmentsStore.swift`
- `SharedCore/State/GradesStore.swift`
- `SharedCore/State/CoursesStore.swift`
- `SharedCore/State/PlannerStore.swift`

**Settings Addition:**
```swift
// SharedCore/Models/AppSettingsModel.swift
@Published var enableCoreDataSync: Bool = false {
    didSet {
        save()
    }
}
```

**Testing:**
```swift
func testDualWrite() {
    let store = AssignmentsStore()
    let task = AppTask(...)
    
    store.tasks = [task]
    
    // Verify JSON saved
    XCTAssertTrue(FileManager.default.fileExists(atPath: store.cacheURL.path))
    
    // Verify CoreData saved
    let repo = TaskRepository(context: testContext)
    let fetched = repo.fetch(id: task.id)
    XCTAssertEqual(fetched, task)
}
```

### Phase 4: iOS-Specific Optimizations (2 hours)

**Goal:** Optimize for iOS app lifecycle

**Tasks:**
1. Background context for all CoreData writes
2. Batch saves to reduce writes
3. Memory warnings handler

**Implementation:**
```swift
// SharedCore/Persistence/PersistenceBatchWriter.swift
actor PersistenceBatchWriter {
    private var pendingWrites: [(any Codable, String)] = []
    private var timer: Timer?
    
    func queue<T: Codable>(_ item: T, type: String) {
        pendingWrites.append((item, type))
        scheduleFlush()
    }
    
    private func scheduleFlush() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { await self?.flush() }
        }
    }
    
    func flush() async {
        guard !pendingWrites.isEmpty else { return }
        
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            // Write all pending items
            for (item, type) in pendingWrites {
                // ... write logic
            }
            try? context.save()
        }
        
        pendingWrites.removeAll()
    }
}
```

### Phase 5: Migration Safety (2 hours)

**Goal:** Ensure no data loss during deployment

**Tasks:**
1. Add schema version check
2. Backup JSON before first CoreData sync
3. Rollback mechanism

**Implementation:**
```swift
// SharedCore/Persistence/PersistenceMigrationManager.swift
extension PersistenceMigrationManager {
    func enableCoreDataSyncSafely() -> Bool {
        // 1. Backup all JSON stores
        let backupURL = createBackup()
        guard backupURL != nil else {
            LOG_DATA(.error, "Migration", "Backup failed - aborting CoreData sync")
            return false
        }
        
        // 2. Test write to CoreData
        let testContext = PersistenceController.shared.newBackgroundContext()
        do {
            // Try creating a test entity
            let testMO = SemesterMO(context: testContext)
            testMO.id = UUID()
            try testContext.save()
            testContext.delete(testMO)
            try testContext.save()
        } catch {
            LOG_DATA(.error, "Migration", "CoreData test write failed: \(error)")
            return false
        }
        
        // 3. Enable sync
        AppSettingsModel.shared.enableCoreDataSync = true
        
        // 4. Trigger initial sync
        Task {
            await syncAllStoresToCoreData()
        }
        
        return true
    }
    
    private func createBackup() -> URL? {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let backupDir = appSupport.appendingPathComponent("Backups/\(Date().timeIntervalSince1970)")
        try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        // Copy all store JSON files
        let storeFiles = [
            "RootsAssignments/tasks.json",
            "RootsGrades/grades.json",
            "RootsCourses/courses.json",
            // ... etc
        ]
        
        for file in storeFiles {
            let source = appSupport.appendingPathComponent(file)
            let dest = backupDir.appendingPathComponent(file)
            try? fm.copyItem(at: source, to: dest)
        }
        
        return backupDir
    }
}
```

---

## Acceptance Criteria Verification

### CRUD Operations Test Plan

**Test Each Entity:**
```swift
// Tests/Integration/PersistenceIntegrationTests.swift

func testSemesterCRUD() {
    let semester = Semester(...)
    
    // Create
    CoursesStore.shared.addSemester(semester)
    
    // Read
    let fetched = CoursesStore.shared.semesters.first { $0.id == semester.id }
    XCTAssertEqual(fetched, semester)
    
    // Update
    var updated = semester
    updated.isArchived = true
    CoursesStore.shared.updateSemester(updated)
    XCTAssertTrue(CoursesStore.shared.semesters.first { $0.id == semester.id }?.isArchived == true)
    
    // Delete
    CoursesStore.shared.deleteSemester(id: semester.id)
    XCTAssertNil(CoursesStore.shared.semesters.first { $0.id == semester.id })
}

func testCourseCRUD() { /* ... */ }
func testAssignmentCRUD() { /* ... */ }
func testEventCRUD() { /* ... */ }
func testGradeCRUD() { /* ... */ }
func testActivityCRUD() { /* ... */ }
```

### Data Persistence Test Plan

**Test App Relaunch:**
```swift
func testDataSurvivesRelaunch() {
    // 1. Create test data
    let semester = Semester(...)
    CoursesStore.shared.addSemester(semester)
    
    // 2. Force save
    CoursesStore.shared.saveCache()
    
    // 3. Clear in-memory state
    CoursesStore.shared.semesters.removeAll()
    
    // 4. Reload from disk
    CoursesStore.shared.loadCache()
    
    // 5. Verify data restored
    XCTAssertEqual(CoursesStore.shared.semesters.count, 1)
    XCTAssertEqual(CoursesStore.shared.semesters.first?.id, semester.id)
}
```

### Device/Simulator Test Plan

**Manual Testing:**
1. ✅ Create data on iOS simulator
2. ✅ Kill app (swipe up)
3. ✅ Relaunch app
4. ✅ Verify data still present
5. ✅ Deploy to physical device
6. ✅ Repeat steps 1-4
7. ✅ Test with iCloud sync enabled
8. ✅ Test with iCloud sync disabled
9. ✅ Test with CoreData sync enabled
10. ✅ Test with CoreData sync disabled

---

## Risk Assessment

### High Risk
- ❌ Data loss during migration
- ❌ CoreData/JSON sync conflicts

**Mitigation:**
- Always backup before enabling CoreData sync
- Make CoreData opt-in with feature flag
- Keep JSON as primary during transition period

### Medium Risk
- ⚠️ Performance impact (dual writes)
- ⚠️ Increased storage usage (duplicate data)

**Mitigation:**
- Use background contexts for CoreData writes
- Batch writes to reduce overhead
- Add metrics to monitor performance

### Low Risk
- ✅ Build errors from model changes
- ✅ Test failures

**Mitigation:**
- Thorough testing before merge
- CI/CD runs all tests

---

## Timeline Estimate

**Total Time:** 14-16 hours over 2-3 days

- Phase 1: CoreData Schema (2 hours)
- Phase 2: Repositories (4 hours)
- Phase 3: Store Integration (4 hours)
- Phase 4: iOS Optimizations (2 hours)
- Phase 5: Migration Safety (2 hours)
- Testing & Validation (2-4 hours)

---

## Success Metrics

### Functional
- ✅ All CRUD operations work on iOS
- ✅ Data persists across app relaunches
- ✅ No data loss in production
- ✅ iOS behavior matches macOS

### Performance
- ✅ App launch time increase < 100ms
- ✅ Save operation latency < 50ms (p95)
- ✅ Memory usage increase < 10MB

### Quality
- ✅ Test coverage > 80% for new code
- ✅ Zero crashes related to persistence
- ✅ Zero data corruption reports

---

## Rollout Plan

### Phase 1: Internal Testing (Week 1)
- Deploy to internal TestFlight
- Enable CoreData sync for testing
- Monitor crash logs and performance

### Phase 2: Beta Testing (Week 2)
- Deploy to external beta testers
- CoreData sync opt-in only
- Collect feedback and metrics

### Phase 3: Production (Week 3)
- Deploy to App Store
- CoreData sync remains opt-in
- Monitor adoption and issues

### Phase 4: Full Migration (Month 2)
- Enable CoreData by default
- Deprecate JSON-only mode
- Full CoreData transition complete

---

## Open Questions

1. **Do we want to migrate existing users to CoreData automatically?**
   - Recommendation: Make opt-in first, auto-migrate in v2.0

2. **Should we remove JSON stores eventually?**
   - Recommendation: Keep for 2-3 releases as safety net

3. **How to handle iCloud + CoreData conflicts?**
   - Recommendation: Disable iCloud JSON sync when CoreData enabled

4. **Should we add SwiftData instead of CoreData?**
   - Recommendation: No - SwiftData requires iOS 17+, CoreData works on iOS 15+

---

## Next Steps

1. ✅ Review this plan with team
2. ⬜ Get approval to proceed
3. ⬜ Create feature branch: `feature/ios-coredata-persistence`
4. ⬜ Implement Phase 1 (CoreData schema)
5. ⬜ Write tests for Phase 1
6. ⬜ Code review and merge Phase 1
7. ⬜ Repeat for Phases 2-5

---

## References

- [Apple CoreData Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [CoreData Lightweight Migrations](https://developer.apple.com/documentation/coredata/using_lightweight_migration)
- [Existing Implementation: PersistenceController.swift](./SharedCore/Persistence/PersistenceController.swift)
- [Existing Models: CourseModels.swift](./SharedCore/Models/CourseModels.swift)

---

**Document Version:** 1.0  
**Last Updated:** January 8, 2025  
**Status:** Ready for Review
