# iCloud File & Module Persistence Implementation

## Overview

This implementation provides comprehensive persistence and synchronization for:
- **Course Modules** (folders/organizational structure)
- **Course Files** (PDFs, documents, syllabi)
- **Planner Analyses** (AI-generated plans and insights)
- **File Parse Results** (extracted text and metadata)

All data syncs automatically across devices via CloudKit and remains available offline.

## Architecture

### Core Components

1. **Core Data Entities** (`Itori.xcdatamodeld`)
   - `CourseOutlineNodeMO` - Course modules/folders
   - `CourseFileMO` - File metadata and sync status
   - `FileParseResultMO` - Parse results and extracted content
   - `PlannerAnalysisMO` - Planner analyses and AI results

2. **Repositories** (`SharedCore/Persistence/Repositories/`)
   - `CourseModuleRepository` - CRUD for modules and files
   - `PlannerAnalysisRepository` - CRUD for analyses

3. **Sync Manager** (`CourseFileCloudSyncManager`)
   - Uploads files to iCloud Drive
   - Downloads files for offline access
   - Maintains local cache
   - Monitors sync status

4. **Migration Manager** (`PersistenceMigrationManager`)
   - Bridges JSON storage to Core Data
   - Handles batch migrations

## Usage

### Module Management

```swift
let repository = CourseModuleRepository()

// Create a module
let module = try await repository.createModule(
    courseId: courseId,
    parentId: nil, // root level
    type: .module,
    title: "Week 1",
    sortIndex: 0
)

// Fetch modules for a course
let modules = try await repository.fetchModules(for: courseId)

// Update module
try await repository.updateModule(
    id: module.id,
    title: "Week 1 - Introduction",
    sortIndex: 1
)

// Delete module
try await repository.deleteModule(id: module.id)
```

### File Management

```swift
// Add file to module
let file = try await repository.addFile(
    courseId: courseId,
    nodeId: moduleId, // or nil for course-level
    fileName: "lecture_notes.pdf",
    fileType: "pdf",
    localURL: fileURL.path,
    isSyllabus: false,
    isPracticeExam: false
)

// Upload to iCloud
let syncManager = CourseFileCloudSyncManager.shared
let cloudURL = try await syncManager.uploadFile(
    fileId: file.id,
    localURL: localFileURL,
    courseId: courseId,
    nodeId: moduleId
)

// Fetch files for a module
let files = try await repository.fetchFiles(
    courseId: courseId,
    nodeId: moduleId
)

// Download file from iCloud
let localURL = try await syncManager.downloadFile(
    fileId: file.id,
    iCloudPath: cloudPath
)

// Update parse status
try await repository.updateFileParse(
    id: file.id,
    parseStatus: .parsed,
    parseError: nil
)

// Delete file
try await syncManager.deleteFile(
    fileId: file.id,
    iCloudPath: cloudPath
)
```

### Planner Analysis Storage

```swift
let repository = PlannerAnalysisRepository()

// Save analysis
let analysisId = try await repository.saveAnalysis(
    type: "weekly_plan",
    startDate: weekStart,
    endDate: weekEnd,
    analysisData: [
        "assignments": assignmentsArray,
        "total_hours": 40,
        "difficulty_average": 0.7
    ],
    resultData: [
        "recommendations": [
            "Start early on difficult assignments",
            "Break work into smaller chunks"
        ],
        "workload_distribution": workloadDict
    ]
)

// Fetch analyses for date range
let analyses = try await repository.fetchAnalyses(
    startDate: monthStart,
    endDate: monthEnd,
    type: "weekly_plan"
)

// Get latest analysis
if let latest = try await repository.fetchLatestAnalysis(type: "weekly_plan") {
    print("Last analysis: \(latest.createdAt)")
}

// Update with new results
try await repository.updateAnalysis(
    id: analysisId,
    resultData: updatedResults
)

// Cleanup old data
let deleted = try await repository.deleteOldAnalyses(
    olderThan: threeMonthsAgo
)
```

### Migration from JSON Storage

```swift
let migrationManager = PersistenceMigrationManager()

// Migrate modules
try await migrationManager.migrateModules(
    existingModules,
    courseId: courseId
)

// Migrate files
try await migrationManager.migrateFiles(
    existingFiles,
    courseId: courseId
)

// Save analysis
let analysisId = try await migrationManager.savePlannerAnalysis(
    type: "auto_plan",
    startDate: Date(),
    endDate: Date().addingTimeInterval(7*24*60*60),
    assignments: assignmentsDict,
    workload: workloadDict,
    recommendations: recommendationsDict
)
```

## Sync Behavior

### Automatic Sync
- All Core Data changes sync automatically via CloudKit
- File uploads happen on-demand when you call `uploadFile()`
- Downloads happen automatically when files are accessed

### Offline Support
- All Core Data operations work offline
- Files are cached locally for offline access
- Changes sync when network is restored

### Conflict Resolution
- Core Data uses `NSMergeByPropertyObjectTrumpMergePolicy`
- Most recent change wins for each property
- CloudKit handles distributed conflicts automatically

## File Organization

### iCloud Directory Structure
```
iCloud/Documents/CourseFiles/
├── {courseId}/
│   ├── root/              # Course-level files
│   │   └── syllabus.pdf
│   └── {moduleId}/        # Module-specific files
│       └── lecture_notes.pdf
```

### Local Cache
```
~/Library/Caches/CourseFiles/
└── {filename}            # Downloaded for offline access
```

## Integration with Existing Code

### CoursesStore Integration

```swift
class CoursesStore: ObservableObject {
    private let moduleRepository = CourseModuleRepository()
    private let fileSyncManager = CourseFileCloudSyncManager.shared
    
    func createModule(for courseId: UUID, title: String) async throws {
        let module = try await moduleRepository.createModule(
            courseId: courseId,
            type: .module,
            title: title
        )
        
        // Update UI state
        await MainActor.run {
            // Refresh modules list
        }
    }
    
    func addFile(to courseId: UUID, moduleId: UUID?, url: URL) async throws {
        // Add to database
        let file = try await moduleRepository.addFile(
            courseId: courseId,
            nodeId: moduleId,
            fileName: url.lastPathComponent,
            fileType: url.pathExtension,
            localURL: url.path
        )
        
        // Upload to iCloud
        _ = try await fileSyncManager.uploadFile(
            fileId: file.id,
            localURL: url,
            courseId: courseId,
            nodeId: moduleId
        )
        
        // Update UI
        await MainActor.run {
            // Refresh files list
        }
    }
}
```

### File Parsing Integration

```swift
class FileParsingService {
    private let moduleRepository = CourseModuleRepository()
    
    func parseFile(_ file: CourseFile) async throws {
        // Update status to parsing
        try await moduleRepository.updateFileParse(
            id: file.id,
            parseStatus: .parsing
        )
        
        // Perform parsing
        do {
            let extractedText = try await extractText(from: file)
            
            // Save parse result
            try await moduleRepository.saveParseResult(
                fileId: file.id,
                parseType: "text_extraction",
                success: true,
                extractedText: extractedText,
                contentJSON: nil,
                errorMessage: nil
            )
            
            // Update status to parsed
            try await moduleRepository.updateFileParse(
                id: file.id,
                parseStatus: .parsed
            )
        } catch {
            // Update with error
            try await moduleRepository.updateFileParse(
                id: file.id,
                parseStatus: .failed,
                parseError: error.localizedDescription
            )
        }
    }
}
```

### Planner Integration

```swift
class PlannerService {
    private let analysisRepository = PlannerAnalysisRepository()
    
    func generateWeeklyPlan(for week: Date) async throws {
        let startDate = week.startOfWeek()
        let endDate = week.endOfWeek()
        
        // Generate plan (existing logic)
        let assignments = try await fetchAssignments(for: startDate, endDate: endDate)
        let analysis = try await analyzeWorkload(assignments)
        
        // Save to database
        _ = try await analysisRepository.saveAnalysis(
            type: "weekly_plan",
            startDate: startDate,
            endDate: endDate,
            analysisData: [
                "assignments": assignments.map { $0.id.uuidString },
                "total_estimated_hours": analysis.totalHours
            ],
            resultData: [
                "daily_distribution": analysis.dailyDistribution,
                "recommendations": analysis.recommendations
            ]
        )
    }
    
    func loadPreviousAnalysis(for week: Date) async throws -> PlannerAnalysisResult? {
        return try await analysisRepository.fetchLatestAnalysis(type: "weekly_plan")
    }
}
```

## Monitoring & Debugging

### Sync Status

```swift
let syncMonitor = SyncMonitor.shared

// Observe sync state
syncMonitor.$lastSyncDate
    .sink { date in
        print("Last sync: \(date)")
    }
    .store(in: &cancellables)

// Check for errors
if let error = syncMonitor.lastError {
    print("Sync error: \(error)")
}

// Check CloudKit availability
let fileSyncManager = CourseFileCloudSyncManager.shared
if !fileSyncManager.isCloudAvailable {
    print("⚠️ iCloud is not available")
}
```

### File Sync Status

```swift
let syncManager = CourseFileCloudSyncManager.shared

// Monitor sync progress
syncManager.$syncStatus
    .sink { status in
        switch status {
        case .idle:
            print("Sync idle")
        case .syncing(let progress):
            print("Syncing: \(Int(progress * 100))%")
        case .error(let message):
            print("Sync error: \(message)")
        }
    }
    .store(in: &cancellables)

// Check pending uploads
print("Pending uploads: \(syncManager.pendingSyncCount)")
```

## Testing

### Unit Tests

```swift
class ModulePersistenceTests: XCTestCase {
    var repository: CourseModuleRepository!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        repository = CourseModuleRepository(persistenceController: persistenceController)
    }
    
    func testCreateModule() async throws {
        let courseId = UUID()
        
        let module = try await repository.createModule(
            courseId: courseId,
            type: .module,
            title: "Test Module"
        )
        
        XCTAssertEqual(module.title, "Test Module")
        XCTAssertEqual(module.courseId, courseId)
    }
    
    func testFetchModules() async throws {
        let courseId = UUID()
        
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Module 1")
        _ = try await repository.createModule(courseId: courseId, type: .module, title: "Module 2")
        
        let modules = try await repository.fetchModules(for: courseId)
        XCTAssertEqual(modules.count, 2)
    }
}
```

## Performance Considerations

### Batching
- Use background contexts for bulk operations
- Batch file uploads during off-peak times
- Clean up old analyses periodically

### Caching
- Files are cached locally after first download
- Core Data provides automatic memory management
- Use `@FetchRequest` or manual fetches based on needs

### Storage Limits
- Monitor iCloud storage usage
- Implement file size limits (e.g., 50MB per file)
- Compress large files before upload

## Best Practices

1. **Always use repositories** - Don't access Core Data directly
2. **Upload files after database entry** - Ensures metadata exists first
3. **Handle offline gracefully** - Show cached data, queue uploads
4. **Clean up old data** - Delete analyses older than 6 months
5. **Monitor sync status** - Alert users to sync issues
6. **Test migration thoroughly** - Use in-memory store for tests

## Troubleshooting

### Files not syncing
- Check iCloud account is signed in
- Verify entitlements are configured
- Check network connectivity
- Review sync status in SyncMonitor

### Large files failing
- Check file size limits
- Implement chunked uploads for large files
- Consider external storage for very large files

### Merge conflicts
- Check merge policy configuration
- Review conflicting changes in CloudKit dashboard
- Consider using custom conflict resolution

## Migration Checklist

- [ ] Add Core Data entities to model
- [ ] Configure CloudKit capabilities
- [ ] Test sync between devices
- [ ] Migrate existing JSON data
- [ ] Update UI to use new repositories
- [ ] Add sync status indicators
- [ ] Implement error handling
- [ ] Add unit tests
- [ ] Test offline behavior
- [ ] Monitor sync performance

## Next Steps

1. **Phase 1**: Implement repositories and test locally
2. **Phase 2**: Enable CloudKit and test sync
3. **Phase 3**: Migrate existing data
4. **Phase 4**: Update UI to use new persistence
5. **Phase 5**: Add sync monitoring and error handling
6. **Phase 6**: Optimize and polish

## Related Documentation

- [CORE_DATA_CLOUDKIT_INDEX.md](CORE_DATA_CLOUDKIT_INDEX.md)
- [ICLOUD_SYNC_PRODUCTION_READY.md](ICLOUD_SYNC_PRODUCTION_READY.md)
- [FILE_CLASSIFICATION_IMPLEMENTATION.md](FILE_CLASSIFICATION_IMPLEMENTATION.md)
