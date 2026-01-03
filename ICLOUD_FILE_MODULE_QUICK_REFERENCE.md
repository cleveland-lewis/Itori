# iCloud File & Module Persistence - Quick Reference

## Quick Start

### Import
```swift
import SharedCore
```

### Create Module
```swift
let repository = CourseModuleRepository()
let module = try await repository.createModule(
    courseId: courseId,
    type: .module,
    title: "Week 1"
)
```

### Add File
```swift
// Add to database
let file = try await repository.addFile(
    courseId: courseId,
    nodeId: moduleId,
    fileName: "notes.pdf",
    fileType: "pdf",
    localURL: url.path
)

// Upload to iCloud
let syncManager = CourseFileCloudSyncManager.shared
let cloudURL = try await syncManager.uploadFile(
    fileId: file.id,
    localURL: url,
    courseId: courseId,
    nodeId: moduleId
)
```

### Save Planner Analysis
```swift
let analysisRepo = PlannerAnalysisRepository()
let id = try await analysisRepo.saveAnalysis(
    type: "weekly_plan",
    startDate: startDate,
    endDate: endDate,
    analysisData: ["assignments": [...], "hours": 40],
    resultData: ["recommendations": [...]]
)
```

### Fetch Data
```swift
// Modules
let modules = try await repository.fetchModules(for: courseId)

// Files
let files = try await repository.fetchFiles(courseId: courseId, nodeId: moduleId)

// Analyses
let analyses = try await analysisRepo.fetchAnalyses(
    startDate: startDate,
    endDate: endDate,
    type: "weekly_plan"
)
```

## Key Classes

| Class | Purpose |
|-------|---------|
| `CourseModuleRepository` | CRUD for modules and files |
| `PlannerAnalysisRepository` | CRUD for planner analyses |
| `CourseFileCloudSyncManager` | iCloud file upload/download |
| `PersistenceMigrationManager` | Migrate from JSON to Core Data |

## Entities

| Entity | Description |
|--------|-------------|
| `CourseOutlineNodeMO` | Course modules/folders |
| `CourseFileMO` | File metadata + sync status |
| `FileParseResultMO` | Parse results and extracted text |
| `PlannerAnalysisMO` | Planner analyses and AI results |

## Common Operations

### Update File Parse Status
```swift
try await repository.updateFileParse(
    id: file.id,
    parseStatus: .parsed,
    parseError: nil
)
```

### Download File from iCloud
```swift
let localURL = try await syncManager.downloadFile(
    fileId: file.id,
    iCloudPath: cloudPath
)
```

### Delete File
```swift
try await syncManager.deleteFile(
    fileId: file.id,
    iCloudPath: cloudPath
)
```

### Get Latest Analysis
```swift
let latest = try await analysisRepo.fetchLatestAnalysis(type: "weekly_plan")
```

### Clean Up Old Data
```swift
let deleted = try await analysisRepo.deleteOldAnalyses(
    olderThan: threeMonthsAgo
)
```

## Monitoring

### Sync Status
```swift
let syncMonitor = SyncMonitor.shared
print("Last sync: \(syncMonitor.lastSyncDate ?? Date())")
print("Is syncing: \(syncMonitor.isSyncing)")
```

### File Sync Status
```swift
let syncManager = CourseFileCloudSyncManager.shared
syncManager.$syncStatus.sink { status in
    switch status {
    case .idle: print("Idle")
    case .syncing(let progress): print("\(Int(progress * 100))%")
    case .error(let msg): print("Error: \(msg)")
    }
}
```

### Check iCloud Availability
```swift
if !syncManager.isCloudAvailable {
    // Show alert
}
```

## Error Handling

```swift
do {
    try await repository.createModule(...)
} catch {
    if error.localizedDescription.contains("not found") {
        // Handle not found
    } else {
        // Handle other errors
    }
}
```

## File Sync Errors

```swift
enum SyncError: LocalizedError {
    case cloudNotAvailable
    case fileNotFound
    case uploadFailed(String)
    case downloadFailed(String)
}
```

## Migration

```swift
let migrationManager = PersistenceMigrationManager()

// Migrate modules
try await migrationManager.migrateModules(modules, courseId: courseId)

// Migrate files
try await migrationManager.migrateFiles(files, courseId: courseId)
```

## Testing

```swift
class MyTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: CourseModuleRepository!
    
    override func setUp() {
        persistenceController = PersistenceController(inMemory: true)
        repository = CourseModuleRepository(persistenceController: persistenceController)
    }
    
    func testCreateModule() async throws {
        let module = try await repository.createModule(
            courseId: UUID(),
            type: .module,
            title: "Test"
        )
        XCTAssertEqual(module.title, "Test")
    }
}
```

## Best Practices

1. ✅ Always use repositories (not Core Data directly)
2. ✅ Upload files after database entry
3. ✅ Handle offline scenarios gracefully
4. ✅ Clean up old analyses periodically
5. ✅ Monitor sync status and show to users
6. ✅ Test with in-memory store

## Common Pitfalls

1. ❌ Don't access Core Data on main thread
2. ❌ Don't upload files before database entry
3. ❌ Don't assume iCloud is always available
4. ❌ Don't ignore sync errors
5. ❌ Don't forget to clean up old data

## Performance Tips

- Use background contexts for bulk operations
- Batch file uploads
- Cache file URLs locally
- Use `@FetchRequest` for SwiftUI views
- Implement pagination for large datasets

## Directory Structure

```
iCloud/Documents/CourseFiles/
└── {courseId}/
    ├── root/              # Course-level files
    └── {moduleId}/        # Module-specific files

~/Library/Caches/CourseFiles/
└── {filename}            # Local cache
```

## Related Files

- `SharedCore/Persistence/Repositories/CourseModuleRepository.swift`
- `SharedCore/Persistence/Repositories/PlannerAnalysisRepository.swift`
- `SharedCore/Services/CourseFileCloudSyncManager.swift`
- `SharedCore/Persistence/PersistenceMigrationManager.swift`
- `ICLOUD_FILE_MODULE_PERSISTENCE.md` (Full guide)
