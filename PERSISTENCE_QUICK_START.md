# iOS Persistence Implementation - Quick Start Guide

## Overview

This guide provides step-by-step instructions to implement local persistence on iOS using the dual-write pattern.

---

## Prerequisites

- [ ] Xcode 15.0+
- [ ] Read [PERSISTENCE_SUMMARY.md](./PERSISTENCE_SUMMARY.md)
- [ ] Review [LOCAL_PERSISTENCE_IMPLEMENTATION_PLAN.md](./LOCAL_PERSISTENCE_IMPLEMENTATION_PLAN.md)

---

## Step 1: Extend CoreData Schema (30 minutes)

### Add Missing Entities

1. **Open Xcode**
   ```bash
   open ItoriApp.xcodeproj
   ```

2. **Navigate to CoreData Model**
   - Open `SharedCore/Persistence/Itori.xcdatamodeld`
   - Click `Itori.xcdatamodel`

3. **Add Event Entity**
   - Click "Add Entity" button
   - Name: `Event`
   - Class: `EventMO`
   - Add attributes:
     ```
     id: UUID
     title: String
     startDate: Date
     endDate: Date
     isAllDay: Boolean (default: NO)
     notes: String (optional)
     courseId: UUID (optional)
     recurrence: String (optional)
     createdAt: Date
     updatedAt: Date
     ```

4. **Add Grade Entity**
   - Click "Add Entity"
   - Name: `Grade`
   - Class: `GradeMO`
   - Add attributes:
     ```
     courseId: UUID (primary key)
     percent: Double (optional)
     letter: String (optional)
     updatedAt: Date
     ```

5. **Add Activity Entity**
   - Click "Add Entity"
   - Name: `Activity`
   - Class: `ActivityMO`
   - Add attributes:
     ```
     id: UUID
     name: String
     note: String (optional)
     courseId: UUID (optional)
     assignmentId: UUID (optional)
     studyCategory: String (optional)
     collectionId: UUID (optional)
     colorHex: String (optional)
     emoji: String (optional)
     isPinned: Boolean (default: NO)
     createdAt: Date
     updatedAt: Date
     ```

6. **Enhance Task Entity** (if not already complete)
   - Check if `Assignment` entity has all fields from `AppTask`
   - Add missing fields if needed:
     ```
     moduleIds: String (JSON array)
     minBlockMinutes: Integer 16
     maxBlockMinutes: Integer 16
     recurrence: String (optional, JSON)
     recurrenceSeriesID: UUID (optional)
     recurrenceIndex: Integer 32 (optional)
     alarmDate: Date (optional)
     alarmEnabled: Boolean (default: NO)
     alarmSound: String (optional)
     deletedAt: Date (optional)
     needsReview: Boolean (default: NO)
     ```

7. **Add Relationships**
   - Course → Events (one-to-many)
   - Course → Grade (one-to-one)
   - Course → Activities (one-to-many)

8. **Save and Build**
   ```bash
   # Clean build to verify
   xcodebuild clean build -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

---

## Step 2: Create Repository Pattern (1 hour)

### Create TaskRepository

**File:** `SharedCore/Persistence/Repositories/TaskRepository.swift`

```swift
import CoreData
import Foundation

final class TaskRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save(_ task: AppTask) throws {
        let mo = fetchOrCreate(id: task.id)
        mo.update(from: task)
        try context.save()
    }
    
    func fetch(id: UUID) -> AppTask? {
        let request: NSFetchRequest<AssignmentMO> = AssignmentMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first?.toModel()
    }
    
    func fetchAll() -> [AppTask] {
        let request: NSFetchRequest<AssignmentMO> = AssignmentMO.fetchRequest()
        return (try? context.fetch(request))?.map { $0.toModel() } ?? []
    }
    
    func delete(id: UUID) throws {
        guard let mo = fetchMO(id: id) else { return }
        context.delete(mo)
        try context.save()
    }
    
    private func fetchOrCreate(id: UUID) -> AssignmentMO {
        if let existing = fetchMO(id: id) {
            return existing
        }
        let mo = AssignmentMO(context: context)
        mo.id = id
        return mo
    }
    
    private func fetchMO(id: UUID) -> AssignmentMO? {
        let request: NSFetchRequest<AssignmentMO> = AssignmentMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
}

// MARK: - Model Conversion

extension AssignmentMO {
    func toModel() -> AppTask {
        AppTask(
            id: id ?? UUID(),
            title: title ?? "",
            courseId: courseId,
            moduleIds: decodeModuleIds(),
            due: dueDate,
            estimatedMinutes: Int(estimatedMinutes),
            minBlockMinutes: Int(minBlockMinutes),
            maxBlockMinutes: Int(maxBlockMinutes),
            difficulty: difficulty,
            importance: importance,
            type: TaskType(rawValue: type ?? "homework") ?? .homework,
            locked: false,
            attachments: [],
            isCompleted: isCompleted,
            gradeWeightPercent: gradeWeightPercent == 0 ? nil : gradeWeightPercent,
            gradePossiblePoints: gradePossiblePoints == 0 ? nil : gradePossiblePoints,
            gradeEarnedPoints: gradeEarnedPoints == 0 ? nil : gradeEarnedPoints,
            category: TaskType(rawValue: category ?? type ?? "homework") ?? .homework,
            dueTimeMinutes: dueTimeMinutes == 0 ? nil : Int(dueTimeMinutes),
            notes: notes
        )
    }
    
    func update(from task: AppTask) {
        self.id = task.id
        self.title = task.title
        self.courseId = task.courseId
        self.dueDate = task.due
        self.dueTimeMinutes = Int16(task.dueTimeMinutes ?? 0)
        self.estimatedMinutes = Int16(task.estimatedMinutes)
        self.minBlockMinutes = Int16(task.minBlockMinutes)
        self.maxBlockMinutes = Int16(task.maxBlockMinutes)
        self.difficulty = task.difficulty
        self.importance = task.importance
        self.type = task.type.rawValue
        self.category = task.category.rawValue
        self.isCompleted = task.isCompleted
        self.gradeWeightPercent = task.gradeWeightPercent ?? 0
        self.gradePossiblePoints = task.gradePossiblePoints ?? 0
        self.gradeEarnedPoints = task.gradeEarnedPoints ?? 0
        self.notes = task.notes
        self.updatedAt = Date()
        
        // Encode moduleIds as JSON
        if let data = try? JSONEncoder().encode(task.moduleIds) {
            self.moduleIds = String(data: data, encoding: .utf8)
        }
    }
    
    private func decodeModuleIds() -> [UUID] {
        guard let moduleIds = moduleIds,
              let data = moduleIds.data(using: .utf8) else {
            return []
        }
        return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
    }
}
```

### Create GradeRepository

**File:** `SharedCore/Persistence/Repositories/GradeRepository.swift`

```swift
import CoreData
import Foundation

final class GradeRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save(_ grade: GradeEntry) throws {
        let mo = fetchOrCreate(courseId: grade.courseId)
        mo.update(from: grade)
        try context.save()
    }
    
    func fetch(courseId: UUID) -> GradeEntry? {
        fetchMO(courseId: courseId)?.toModel()
    }
    
    func fetchAll() -> [GradeEntry] {
        let request: NSFetchRequest<GradeMO> = GradeMO.fetchRequest()
        return (try? context.fetch(request))?.map { $0.toModel() } ?? []
    }
    
    func delete(courseId: UUID) throws {
        guard let mo = fetchMO(courseId: courseId) else { return }
        context.delete(mo)
        try context.save()
    }
    
    private func fetchOrCreate(courseId: UUID) -> GradeMO {
        if let existing = fetchMO(courseId: courseId) {
            return existing
        }
        let mo = GradeMO(context: context)
        mo.courseId = courseId
        return mo
    }
    
    private func fetchMO(courseId: UUID) -> GradeMO? {
        let request: NSFetchRequest<GradeMO> = GradeMO.fetchRequest()
        request.predicate = NSPredicate(format: "courseId == %@", courseId as CVarArg)
        return try? context.fetch(request).first
    }
}

extension GradeMO {
    func toModel() -> GradeEntry {
        GradeEntry(
            courseId: courseId ?? UUID(),
            percent: percent == 0 ? nil : percent,
            letter: letter,
            updatedAt: updatedAt ?? Date()
        )
    }
    
    func update(from grade: GradeEntry) {
        self.courseId = grade.courseId
        self.percent = grade.percent ?? 0
        self.letter = grade.letter
        self.updatedAt = grade.updatedAt
    }
}
```

---

## Step 3: Add Setting Toggle (15 minutes)

**File:** `SharedCore/Models/AppSettingsModel.swift`

Add property:
```swift
@Published var enableCoreDataSync: Bool = false {
    didSet {
        save()
        NotificationCenter.default.post(
            name: .coreDataSyncSettingChanged,
            object: enableCoreDataSync
        )
    }
}
```

**File:** `Notification+Names.swift`

Add notification:
```swift
extension Notification.Name {
    static let coreDataSyncSettingChanged = Notification.Name("coreDataSyncSettingChanged")
}
```

---

## Step 4: Integrate with Stores (2 hours)

**File:** `SharedCore/State/AssignmentsStore.swift`

Add repository and sync method:

```swift
private var taskRepository: TaskRepository {
    TaskRepository(context: PersistenceController.shared.viewContext)
}

@Published var tasks: [AppTask] = [] {
    didSet {
        guard !isLoadingFromDisk else { return }
        
        // Primary: JSON
        saveCache()
        
        // Secondary: CoreData (async)
        if AppSettingsModel.shared.enableCoreDataSync {
            Task.detached(priority: .utility) {
                await self.syncToCoreData()
            }
        }
        
        // Optional: iCloud
        if isOnline && isSyncEnabled {
            saveToiCloud()
        }
    }
}

private func syncToCoreData() async {
    let context = PersistenceController.shared.newBackgroundContext()
    let repo = TaskRepository(context: context)
    
    await context.perform {
        do {
            // Delete removed tasks
            let existingIDs = Set(repo.fetchAll().map { $0.id })
            let currentIDs = Set(await MainActor.run { self.tasks.map { $0.id } })
            
            for deletedID in existingIDs.subtracting(currentIDs) {
                try repo.delete(id: deletedID)
            }
            
            // Save/update all current tasks
            let tasksToSync = await MainActor.run { self.tasks }
            for task in tasksToSync {
                try repo.save(task)
            }
            
            LOG_DATA(.debug, "Persistence", "CoreData sync: \(tasksToSync.count) tasks")
        } catch {
            LOG_DATA(.error, "Persistence", "CoreData sync failed: \(error)")
        }
    }
}
```

**Repeat for:**
- `GradesStore.swift`
- `CoursesStore.swift` (already uses CoreData partially)
- `PlannerStore.swift`

---

## Step 5: Add Tests (1 hour)

**File:** `Tests/Integration/PersistenceIntegrationTests.swift`

```swift
import XCTest
@testable import Itori

final class PersistenceIntegrationTests: XCTestCase {
    var controller: PersistenceController!
    
    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
    }
    
    func testTaskCRUD() async throws {
        let repo = TaskRepository(context: controller.viewContext)
        
        // Create
        let task = AppTask(
            id: UUID(),
            title: "Test Task",
            courseId: nil,
            due: Date(),
            estimatedMinutes: 60,
            minBlockMinutes: 30,
            maxBlockMinutes: 120,
            difficulty: 0.5,
            importance: 0.7,
            type: .homework,
            locked: false
        )
        
        try repo.save(task)
        
        // Read
        let fetched = repo.fetch(id: task.id)
        XCTAssertEqual(fetched?.id, task.id)
        XCTAssertEqual(fetched?.title, task.title)
        
        // Update
        var updated = task
        updated.isCompleted = true
        try repo.save(updated)
        
        let refetched = repo.fetch(id: task.id)
        XCTAssertEqual(refetched?.isCompleted, true)
        
        // Delete
        try repo.delete(id: task.id)
        XCTAssertNil(repo.fetch(id: task.id))
    }
    
    func testDataPersistence() async throws {
        // Create data
        let task = AppTask(/* ... */)
        AssignmentsStore.shared.tasks = [task]
        
        // Force save
        AssignmentsStore.shared.saveCache()
        
        // Clear memory
        AssignmentsStore.shared.tasks = []
        
        // Reload
        AssignmentsStore.shared.loadCache()
        
        // Verify
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 1)
        XCTAssertEqual(AssignmentsStore.shared.tasks.first?.id, task.id)
    }
}
```

---

## Step 6: Build and Test (30 minutes)

### Build

```bash
# Clean
xcodebuild clean -scheme Itori

# Build iOS
xcodebuild build -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15'

# Build macOS
xcodebuild build -scheme Itori -destination 'platform=macOS'
```

### Run Tests

```bash
# Unit tests
xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ItoriTests

# Integration tests
xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PersistenceIntegrationTests
```

### Manual Testing

1. Launch app in simulator
2. Create test data (semester, course, assignment)
3. Force quit app (Cmd+Shift+H twice, swipe up)
4. Relaunch app
5. Verify data persists

---

## Step 7: Enable in Settings (10 minutes)

**Add to Settings UI:**

iOS: `Platforms/iOS/Scenes/Settings/IOSStorageSettingsView.swift`  
macOS: `Platforms/macOS/Views/StorageSettingsView.swift`

```swift
Toggle("Enable CoreData Sync (Beta)", isOn: $settings.enableCoreDataSync)
    .accessibilityLabel("Enable CoreData Sync")
    .accessibilityHint("Experimental feature for improved data persistence")
```

---

## Troubleshooting

### Build Errors

**Problem:** "Cannot find AssignmentMO in scope"
**Solution:** Clean build folder (Cmd+Shift+K), rebuild

**Problem:** "Multiple commands produce Info.plist"
**Solution:** Check watch app settings (see WATCH_APP_BUILD_ISSUE.md)

### Runtime Errors

**Problem:** "CoreData: error: Failed to call designated initializer"
**Solution:** Ensure all CoreData entities have `codeGenerationType="class"` in model

**Problem:** "The model used to open the store is incompatible"
**Solution:** Delete app from simulator, reinstall

### Test Failures

**Problem:** Tests hang on CoreData operations
**Solution:** Use `inMemory: true` for test persistence controller

---

## Rollback Plan

If issues occur:

1. **Disable CoreData Sync**
   ```swift
   AppSettingsModel.shared.enableCoreDataSync = false
   ```

2. **Restore from Backup**
   - Backups created automatically in `~/Library/Application Support/Itori/Backups/`
   - Copy backup JSON files to active location

3. **Revert Code Changes**
   ```bash
   git checkout main
   ```

---

## Success Checklist

- [ ] All CoreData entities added
- [ ] All repositories created
- [ ] Stores integrated with dual-write
- [ ] Tests passing
- [ ] Manual testing on simulator works
- [ ] Manual testing on device works
- [ ] Performance impact < 100ms
- [ ] No crashes in logs
- [ ] Code reviewed
- [ ] Documentation updated

---

## Next Steps

After successful implementation:

1. Deploy to internal TestFlight
2. Monitor crash logs and performance
3. Collect feedback from team
4. Expand to external beta
5. Deploy to production (opt-in)
6. Enable by default after validation period

---

**Estimated Time:** 4-6 hours for core implementation  
**Full Completion:** 8-10 hours including tests and polish
