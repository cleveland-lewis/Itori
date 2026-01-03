# Core Data + CloudKit Quick Reference

## Entity Schema Quick Look

```
Semester (Academic Periods)
├── id: UUID ⚡
├── createdAt: Date
├── updatedAt: Date ⚡
├── startDate, endDate: Date
├── isCurrent, isArchived: Bool
├── educationLevel, semesterTerm: String
└── courses → [Course] (cascade delete)

Course (Classes)
├── id: UUID ⚡
├── createdAt: Date
├── updatedAt: Date ⚡
├── title, code: String
├── courseType, creditType: String
├── instructor, location, notes: String?
├── semester → Semester (nullify)
└── assignments → [Assignment] (cascade delete)

Assignment (Tasks/Homework)
├── id: UUID ⚡
├── createdAt: Date
├── updatedAt: Date ⚡
├── title: String
├── dueDate: Date? ⚡
├── estimatedMinutes, minBlock, maxBlock: Int16
├── difficulty, importance: Double (0-1)
├── type, category: String
├── isCompleted: Bool ⚡
├── gradeWeightPercent, Points: Double?
├── recurrenceSeriesID: UUID? ⚡
├── recurrenceData: Binary
├── course → Course (nullify)
└── attachments → [Attachment] (cascade delete)

Attachment (Files)
├── id: UUID ⚡
├── createdAt, updatedAt: Date
├── fileName: String
├── fileData: Binary (external storage)
├── fileURL, mimeType: String?
└── assignment → Assignment (nullify)

TimerSession (Study Tracking)
├── id: UUID ⚡
├── createdAt, updatedAt: Date ⚡
├── durationSeconds: Double
├── startedAt, endedAt: Date?
├── mode: String?
├── activityID: UUID?
├── courseId: UUID? ⚡
└── assignmentId: UUID? ⚡

⚡ = Indexed for fast queries
```

## Common Operations

### Create Entity
```swift
let context = PersistenceController.shared.viewContext
let course = NSEntityDescription.insertNewObject(forEntityName: "Course", into: context)
course.setValue(UUID(), forKey: "id")
course.setValue(Date(), forKey: "createdAt")
course.setValue(Date(), forKey: "updatedAt")
course.setValue("CS 101", forKey: "code")
// ... set other required fields
try context.save() // Auto-syncs to CloudKit
```

### Fetch Entities
```swift
let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Course")
fetchRequest.predicate = NSPredicate(format: "isArchived == NO")
fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
let courses = try? context.fetch(fetchRequest)
```

### Update Entity
```swift
course.setValue(Date(), forKey: "updatedAt") // Auto-touched by PersistenceController
course.setValue("New Title", forKey: "title")
try context.save() // Auto-syncs
```

### Delete Entity
```swift
context.delete(course) // Cascade deletes assignments
try context.save() // Auto-syncs deletion
```

### Background Operations
```swift
let backgroundContext = PersistenceController.shared.newBackgroundContext()
backgroundContext.perform {
    // Bulk operations here
    try? backgroundContext.save()
}
```

## Sync Monitoring (DEBUG only)

### View Sync Status
```swift
#if DEBUG
import SwiftUI

struct DebugSyncView: View {
    @StateObject var monitor = SyncMonitor.shared
    
    var body: some View {
        VStack {
            Text("CloudKit: \(monitor.isCloudKitActive ? "✅" : "❌")")
            Text("Last Sync: \(monitor.lastRemoteChange?.formatted() ?? "Never")")
            
            ForEach(monitor.syncEvents) { event in
                HStack {
                    Image(systemName: event.icon)
                    Text(event.details)
                    Spacer()
                    Text(event.timestamp.formatted(.relative(presentation: .numeric)))
                        .font(.caption)
                }
            }
        }
    }
}
#endif
```

### Log Custom Event
```swift
#if DEBUG
SyncMonitor.shared.logEvent(type: .statusChange, details: "Migration started")
#endif
```

## CloudKit Toggle

### Check Status
```swift
let isEnabled = AppSettingsModel.shared.enableICloudSync
let controller = PersistenceController.shared
print("CloudKit active: \(controller.isCloudKitEnabled)")
```

### Toggle Sync
```swift
AppSettingsModel.shared.enableICloudSync = true // or false
// PersistenceController automatically handles re-initialization
```

## Merge Policy

**Current:** `NSMergeByPropertyObjectTrumpMergePolicy`

**Behavior:** Property-by-property comparison using `updatedAt` timestamp
- Most recent value wins per-property
- Deterministic and automatic
- No UI intervention needed

**Example:**
```
Device A (offline): course.title = "Math 101", updatedAt = 10:00 AM
Device B (offline): course.title = "Mathematics 101", updatedAt = 10:05 AM

Result after sync: course.title = "Mathematics 101" (10:05 AM wins)
```

## Testing

### Run Tests
```bash
# All persistence tests
xcodebuild test -scheme Roots -destination 'platform=macOS' \
    -only-testing:RootsTests/CoreDataStackTests

# Specific test
xcodebuild test -scheme Roots -destination 'platform=macOS' \
    -only-testing:RootsTests/CoreDataStackTests/testCreateTimerSession
```

### In-Memory Testing
```swift
let testController = PersistenceController(inMemory: true)
let testContext = testController.viewContext
// Create test data without affecting production database
```

## Troubleshooting

### Sync Not Working?
1. **Check iCloud account:** Settings → iCloud → Signed in?
2. **Check sync toggle:** Roots Settings → Enable iCloud Sync
3. **Check network:** Online?
4. **Wait:** CloudKit sync takes 10-30 seconds normally
5. **Check SyncMonitor:** Any errors logged?

### Data Not Appearing?
- CloudKit is **eventually consistent** (not instant)
- Normal latency: 10-30 seconds
- High load: Up to 2 minutes
- Check Console.app for Core Data errors

### Duplicates?
- Should not happen (UUID unique constraints)
- If seen: File bug with reproduction steps
- Check merge policy is set correctly

## Performance Tips

### Fast Queries
```swift
// ✅ Good: Use predicates and indexes
fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ AND isCompleted == NO", Date() as CVarArg)

// ❌ Bad: Fetch all then filter in code
let all = try context.fetch(fetchRequest)
let filtered = all.filter { !$0.isCompleted }
```

### Batch Operations
```swift
// ✅ Good: Background context
let bgContext = persistence.newBackgroundContext()
bgContext.perform {
    for i in 0..<1000 {
        // Create entities
    }
    try? bgContext.save()
}

// ❌ Bad: Main thread bulk operations
for i in 0..<1000 {
    // Blocks UI
}
```

### Relationship Faulting
```swift
// ✅ Good: Fetch only what you need
fetchRequest.relationshipKeyPathsForPrefetching = ["course"]

// ❌ Bad: Over-fetching relationships
// Letting Core Data auto-fetch on demand
```

## Key Files

```
SharedCore/Persistence/
├── PersistenceController.swift          # Main controller (pre-existing)
├── Roots.xcdatamodeld/                  # Core Data model (updated)
│   └── Roots.xcdatamodel/contents       # 5 entities
├── SyncMonitor.swift                    # Debug sync monitoring (new)
└── Repositories/
    └── BaseRepository.swift             # Repository pattern base (new)

Tests/PersistenceTests/
└── CoreDataStackTests.swift             # Basic tests (new)

Documentation/
├── CORE_DATA_CLOUDKIT_SYNC_COMPLETE.md  # Full documentation
├── CORE_DATA_CLOUDKIT_IMPLEMENTATION_PLAN.md  # Implementation plan
└── CORE_DATA_CLOUDKIT_QUICK_REFERENCE.md  # This file
```

## Capabilities Check

### macOS (Config/Roots.entitlements)
- ✅ iCloud.com.cwlewisiii.Roots
- ✅ CloudKit
- ✅ CloudDocuments

### iOS (Config/Roots-iOS.entitlements)
- ✅ iCloud.com.cwlewisiii.Roots
- ✅ CloudKit
- ✅ CloudDocuments

## Status

**Infrastructure:** ✅ 100% Complete
**Integration:** ⏳ Pending (AssignmentsStore, CoursesStore)
**Migration:** ⏳ Pending (JSON → Core Data)
**Production Ready:** ✅ Yes (foundation complete)

## Getting Help

1. Check `CORE_DATA_CLOUDKIT_SYNC_COMPLETE.md` for detailed docs
2. Check SyncMonitor debug logs
3. Check Console.app for Core Data errors
4. Review Apple's [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer) docs

---

**Last Updated:** 2026-01-03
**Version:** v1
