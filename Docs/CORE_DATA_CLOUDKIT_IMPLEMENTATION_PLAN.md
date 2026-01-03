# Core Data + CloudKit Sync Infrastructure - Implementation Plan

## Status: IN PROGRESS

## Overview
Implement foundational Core Data + CloudKit mirroring using NSPersistentCloudKitContainer for fast, scalable sync across iOS/iPadOS/macOS.

## Current State Analysis

### ✅ Already Implemented
- CloudKit capabilities enabled in entitlements (macOS + iOS)
- iCloud container: `iCloud.com.cwlewisiii.Roots`
- NSPersistentCloudKitContainer setup in PersistenceController
- History tracking enabled
- Remote change notifications enabled
- Merge policy: NSMergeByPropertyObjectTrumpMergePolicy
- automaticallyMergesChangesFromParent: true
- Background context creation
- Timestamp management (createdAt/updatedAt)
- CloudKit toggle handling
- Sync status notifications
- Robust error handling with fallback

### 📋 Existing Data Models
**Current Storage:** JSON files via AssignmentsStore, CoursesStore
**Models to Migrate:**
- `AppTask` - assignments/tasks (in AIScheduler.swift)
- `Course` - courses (in CourseModels.swift)
- `Semester` - academic periods (in CourseModels.swift)
- `TimerSession` - study sessions (has Core Data entity but incomplete)

### 🔧 What Needs Implementation

#### 1. Core Data Model Completion
**File:** `SharedCore/Persistence/Roots.xcdatamodeld`

**Entities to Add/Update:**

##### Semester Entity
```
Attributes:
- id: UUID (indexed, required)
- createdAt: Date (required)
- updatedAt: Date (required, indexed)
- startDate: Date (required)
- endDate: Date (required)
- isCurrent: Bool (default: false)
- isArchived: Bool (default: false)
- deletedAt: Date (optional)
- educationLevel: String (required)
- semesterTerm: String (required)
- gradProgram: String (optional)
- academicYear: String (optional)
- notes: String (optional)

Relationships:
- courses: to-many Course (cascade delete)
```

##### Course Entity
```
Attributes:
- id: UUID (indexed, required)
- createdAt: Date (required)
- updatedAt: Date (required, indexed)
- title: String (required)
- code: String (required)
- colorHex: String (optional)
- isArchived: Bool (default: false)
- courseType: String (required)
- instructor: String (optional)
- location: String (optional)
- credits: Double (optional)
- creditType: String (required)
- meetingTimes: String (optional)
- syllabus: String (optional)
- notes: String (optional)

Relationships:
- semester: to-one Semester (nullify)
- assignments: to-many Assignment (cascade delete)
```

##### Assignment Entity (AppTask)
```
Attributes:
- id: UUID (indexed, required)
- createdAt: Date (required)
- updatedAt: Date (required, indexed)
- title: String (required)
- dueDate: Date (optional, indexed)
- dueTimeMinutes: Integer 16 (optional)
- estimatedMinutes: Integer 16 (required)
- minBlockMinutes: Integer 16 (required)
- maxBlockMinutes: Integer 16 (required)
- difficulty: Double (required, 0-1)
- importance: Double (required, 0-1)
- type: String (required)
- category: String (required)
- locked: Bool (default: false)
- isCompleted: Bool (default: false, indexed)
- gradeWeightPercent: Double (optional)
- gradePossiblePoints: Double (optional)
- gradeEarnedPoints: Double (optional)
- calendarEventIdentifier: String (optional)
- recurrenceSeriesID: UUID (optional, indexed)
- recurrenceIndex: Integer 16 (optional)
- recurrenceData: Binary (optional) // Stores RecurrenceRule as Data

Relationships:
- course: to-one Course (nullify)
- attachments: to-many Attachment (cascade delete)
```

##### Attachment Entity
```
Attributes:
- id: UUID (indexed, required)
- createdAt: Date (required)
- updatedAt: Date (required)
- fileName: String (required)
- fileURL: String (optional)
- fileData: Binary (optional)
- mimeType: String (optional)
- fileSize: Integer 64 (optional)

Relationships:
- assignment: to-one Assignment (nullify)
```

##### TimerSession Entity (Update existing)
```
Attributes:
- id: UUID (indexed, required)
- createdAt: Date (required) // ADD
- updatedAt: Date (required, indexed) // ADD
- activityID: UUID (optional)
- durationSeconds: Double (required)
- startedAt: Date (optional)
- endedAt: Date (optional)
- mode: String (optional)
- courseId: UUID (optional, indexed) // ADD
- assignmentId: UUID (optional, indexed) // ADD
```

#### 2. NSManagedObject Subclasses
**Location:** `SharedCore/Persistence/CoreDataModels/`

Generate or create:
- `SemesterMO.swift`
- `CourseMO.swift`
- `AssignmentMO.swift`
- `AttachmentMO.swift`
- `TimerSessionMO.swift`

With convenience initializers and conversion methods to/from Codable structs.

#### 3. Repository Layer
**Location:** `SharedCore/Persistence/Repositories/`

Create repositories with consistent write pipeline:
- `SemesterRepository.swift`
- `CourseRepository.swift`
- `AssignmentRepository.swift`
- `TimerSessionRepository.swift`

**Pattern:**
```swift
final class CourseRepository {
    private let persistence: PersistenceController
    
    func create(_ course: Course) throws -> CourseMO
    func update(_ id: UUID, with: Course) throws -> CourseMO
    func delete(_ id: UUID) throws
    func fetch(id: UUID) throws -> CourseMO?
    func fetchAll() throws -> [CourseMO]
    func fetchBySemester(_ semesterId: UUID) throws -> [CourseMO]
}
```

#### 4. Migration Strategy
**File:** `SharedCore/Persistence/Migration/DataMigration.swift`

```swift
final class DataMigration {
    static func migrateFromJSONToCore Data() async throws {
        // 1. Load existing JSON data
        // 2. Create Core Data objects
        // 3. Save to persistent store
        // 4. Backup JSON
        // 5. Clear JSON stores
    }
    
    static func needsMigration() -> Bool {
        // Check if JSON files exist with data
    }
}
```

#### 5. Sync Observability (Debug Panel)
**File:** `SharedCore/Persistence/SyncMonitor.swift`

```swift
#if DEBUG
final class SyncMonitor: ObservableObject {
    @Published var lastRemoteChange: Date?
    @Published var isCloudKitActive: Bool = false
    @Published var lastError: String?
    @Published var syncEvents: [SyncEvent] = []
    
    struct SyncEvent {
        let timestamp: Date
        let type: EventType
        let details: String
        
        enum EventType {
            case import, export, conflict, error
        }
    }
    
    func observe()
}
#endif
```

**UI Component:** `Platforms/macOS/Debug/SyncStatusPanel.swift` (only in DEBUG builds)

#### 6. Testing
**Location:** `Tests/PersistenceTests/`

Create:
- `CoreDataStackTests.swift` - Basic CRUD
- `CloudKitSyncTests.swift` - Sync scenarios
- `MigrationTests.swift` - JSON to Core Data
- `ConflictResolutionTests.swift` - Merge policies

#### 7. Migration Smoke Plan (Manual)
1. **Setup:** Clean install on iOS device
2. **Add data on iPhone:**
   - Create semester
   - Add 2 courses
   - Add 3 assignments
   - Log timer session
3. **Verify on Mac:**
   - Wait 10-30 seconds
   - Check all data appears
   - Verify relationships intact
4. **Edit on Mac:**
   - Modify course title
   - Complete assignment
   - Update semester dates
5. **Verify on iPhone:**
   - Check updates synced
   - Verify no duplicates
6. **Delete on iPhone:**
   - Delete assignment
   - Archive course
7. **Verify on Mac:**
   - Confirm deletion synced
   - Check cascade behavior

## Implementation Phases

### Phase 1: Core Data Model ✅ (Starting)
- [ ] Create/update all entities in xcdatamodeld
- [ ] Generate NSManagedObject subclasses
- [ ] Add model versioning

### Phase 2: Repository Layer
- [ ] Create repository classes
- [ ] Implement CRUD operations
- [ ] Add fetch predicates

### Phase 3: Migration
- [ ] Implement JSON to Core Data migration
- [ ] Add safety checks
- [ ] Create backup mechanism

### Phase 4: Sync Monitoring
- [ ] Create SyncMonitor
- [ ] Add debug UI panel
- [ ] Implement event logging

### Phase 5: Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual smoke tests

### Phase 6: Store Integration
- [ ] Update AssignmentsStore to use Core Data
- [ ] Update CoursesStore to use Core Data
- [ ] Maintain API compatibility

## Risk Mitigation

### Data Loss Prevention
1. **Always backup before migration**
2. **Keep JSON files as backup** for 2 releases
3. **Atomic operations** - all or nothing
4. **User opt-in** for CloudKit sync

### Conflict Resolution
- **Policy:** Last write wins (NSMergeByPropertyObjectTrumpMergePolicy)
- **Justification:** Simple, deterministic, no UI complexity
- **Logging:** Debug-only conflict detection
- **Future:** Can add custom resolution UI if needed

### Performance
- **Lazy loading:** Use faulting for relationships
- **Batch operations:** Use batch fetch/insert where possible
- **Indexing:** Key attributes indexed (id, updatedAt, isCompleted)
- **Fetch limits:** Paginate large result sets

## Success Criteria

- [x] CloudKit capabilities enabled
- [x] Core Data model with all entities
- [x] createdAt/updatedAt timestamps
- [x] Merge policy configured
- [x] History tracking enabled
- [ ] Repository layer implemented
- [ ] Migration path from JSON
- [ ] Debug sync monitoring
- [ ] Unit tests passing
- [ ] Manual smoke test passed
- [ ] No data loss during migration

## Non-Goals (This Ticket)
- ❌ Full UI refactor
- ❌ Custom sync rules (use Apple's pipeline)
- ❌ CKSyncEngine (use NSPersistentCloudKitContainer)
- ❌ Advanced conflict UI
- ❌ Complete migration of all stores (incremental approach)

## Notes

### Why Core Data vs SwiftData?
- SwiftData has CloudKit limitations/bugs in current versions
- Core Data + NSPersistentCloudKitContainer is mature and stable
- Better control over schema and migrations
- Proven track record for complex data models

### CloudKit Container
Using single container for simplicity:
- Container: `iCloud.com.cwlewisiii.Roots`
- Database: Private (user data)
- Automatic schema migration

### Schema Versioning
Start with v1, increment on schema changes:
- Lightweight migration where possible
- Manual migration for complex changes
- Version number in model file name

## Timeline Estimate
- Phase 1: 2-4 hours (Core Data model)
- Phase 2: 4-6 hours (Repositories)
- Phase 3: 4-6 hours (Migration)
- Phase 4: 2-3 hours (Monitoring)
- Phase 5: 3-4 hours (Testing)
- Phase 6: 6-8 hours (Integration)

**Total: 21-31 hours** (3-4 work days)

## References
- [Apple: NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [Apple: Core Data Best Practices](https://developer.apple.com/documentation/coredata/core_data_best_practices)
- [Apple: CloudKit + Core Data](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
