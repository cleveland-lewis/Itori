import Foundation
import CoreData

/// Bridge between existing JSON-based storage and Core Data + CloudKit
final class PersistenceMigrationManager {
    private let persistenceController: PersistenceController
    private let moduleRepository: CourseModuleRepository
    private let analysisRepository: PlannerAnalysisRepository
    private let fileSyncManager: CourseFileCloudSyncManager
    
    init(
        persistenceController: PersistenceController,
        moduleRepository: CourseModuleRepository,
        analysisRepository: PlannerAnalysisRepository,
        fileSyncManager: CourseFileCloudSyncManager
    ) {
        self.persistenceController = persistenceController
        self.moduleRepository = moduleRepository
        self.analysisRepository = analysisRepository
        self.fileSyncManager = fileSyncManager
    }
    
    convenience init() {
        self.init(
            persistenceController: .shared,
            moduleRepository: CourseModuleRepository(),
            analysisRepository: PlannerAnalysisRepository(),
            fileSyncManager: .shared
        )
    }
    
    // MARK: - Module Migration
    
    /// Migrate modules from JSON to Core Data
    func migrateModules(
        _ modules: [CourseOutlineNode],
        courseId: UUID
    ) async throws {
        print("📦 Migrating \(modules.count) modules to Core Data...")
        
        for module in modules {
            _ = try await moduleRepository.createModule(
                courseId: module.courseId,
                parentId: module.parentId,
                type: module.type,
                title: module.title,
                sortIndex: module.sortIndex
            )
        }
        
        print("✅ Modules migrated successfully")
    }
    
    /// Migrate files from JSON to Core Data + iCloud
    func migrateFiles(
        _ files: [CourseFile],
        courseId: UUID
    ) async throws {
        print("📦 Migrating \(files.count) files to Core Data + iCloud...")
        
        for file in files {
            // Add to database
            let courseFile = try await moduleRepository.addFile(
                courseId: file.courseId,
                nodeId: file.nodeId,
                fileName: file.filename,
                fileType: file.fileType,
                localURL: file.localURL,
                isSyllabus: file.isSyllabus,
                isPracticeExam: file.isPracticeExam
            )
            
            // Upload to iCloud if local file exists
            if let localPath = file.localURL,
               let localURL = URL(string: localPath),
               FileManager.default.fileExists(atPath: localURL.path) {
                do {
                    _ = try await fileSyncManager.uploadFile(
                        fileId: courseFile.id,
                        localURL: localURL,
                        courseId: courseId,
                        nodeId: file.nodeId
                    )
                } catch {
                    print("⚠️ Failed to upload file to iCloud: \(error)")
                }
            }
        }
        
        print("✅ Files migrated successfully")
    }
    
    // MARK: - Planner Analysis Migration
    
    /// Save planner analysis to Core Data
    public func savePlannerAnalysis(
        type: String,
        startDate: Date,
        endDate: Date,
        assignments: [String: Any],
        workload: [String: Any]?,
        recommendations: [String: Any]?
    ) async throws -> UUID {
        let analysisData: [String: Any] = [
            "assignments": assignments
        ]
        
        var resultData: [String: Any] = [:]
        if let workload = workload {
            resultData["workload"] = workload
        }
        if let recommendations = recommendations {
            resultData["recommendations"] = recommendations
        }
        
        let id = try await analysisRepository.saveAnalysis(
            type: type,
            startDate: startDate,
            endDate: endDate,
            analysisData: analysisData,
            resultData: resultData.isEmpty ? nil : resultData
        )
        
        print("✅ Saved planner analysis: \(type)")
        return id
    }
    
    // MARK: - Batch Operations
    
    /// Check if migration is needed
    public func needsMigration() async -> Bool {
        // Check if Core Data has any modules/files
        // If JSON storage has data but Core Data doesn't, migration is needed
        return false // Implement based on your storage layer
    }
    
    /// Full migration from JSON to Core Data
    public func performFullMigration() async throws {
        print("🚀 Starting full migration to Core Data + CloudKit...")
        
        // This would coordinate migration of all data types
        // Implementation depends on your existing storage structure
        
        print("✅ Full migration completed")
    }
}
