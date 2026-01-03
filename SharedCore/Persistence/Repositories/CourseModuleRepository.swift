import Foundation
import CoreData

/// Repository for managing course modules and files with iCloud sync
final class CourseModuleRepository {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    convenience init() {
        self.init(persistenceController: .shared)
    }
    
    // MARK: - Module Operations
    
    /// Create a new course module
    func createModule(
        courseId: UUID,
        parentId: UUID? = nil,
        type: CourseOutlineNodeType,
        title: String,
        sortIndex: Int = 0
    ) async throws -> CourseOutlineNode {
        let context = persistenceController.newBackgroundContext()
        
        return try await context.perform {
            let mo = CourseOutlineNodeMO(context: context)
            let id = UUID()
            let now = Date()
            
            mo.id = id
            mo.courseId = courseId
            mo.parentId = parentId
            mo.type = type.rawValue
            mo.title = title
            mo.sortIndex = Int32(sortIndex)
            mo.createdAt = now
            mo.updatedAt = now
            
            try context.save()
            
            return CourseOutlineNode(
                id: id,
                courseId: courseId,
                parentId: parentId,
                type: type,
                title: title,
                sortIndex: sortIndex,
                createdAt: now,
                updatedAt: now
            )
        }
    }
    
    /// Fetch all modules for a course
    func fetchModules(for courseId: UUID) async throws -> [CourseOutlineNode] {
        let context = persistenceController.newBackgroundContext()
        
        return try await context.perform {
            let request = CourseOutlineNodeMO.fetchRequest()
            request.predicate = NSPredicate(format: "courseId == %@", courseId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
            
            let results = try context.fetch(request)
            return results.map { self.toDomain($0) }
        }
    }
    
    /// Update module
    func updateModule(
        id: UUID,
        title: String? = nil,
        sortIndex: Int? = nil
    ) async throws {
        let context = persistenceController.newBackgroundContext()
        
        try await context.perform {
            let request = CourseOutlineNodeMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let mo = try context.fetch(request).first else {
                throw NSError(domain: "CourseModuleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Module not found"])
            }
            
            if let title = title {
                mo.title = title
            }
            if let sortIndex = sortIndex {
                mo.sortIndex = Int32(sortIndex)
            }
            mo.updatedAt = Date()
            
            try context.save()
        }
    }
    
    /// Delete module
    func deleteModule(id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()
        
        try await context.perform {
            let request = CourseOutlineNodeMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let mo = try context.fetch(request).first else {
                throw NSError(domain: "CourseModuleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Module not found"])
            }
            
            context.delete(mo)
            try context.save()
        }
    }
    
    // MARK: - File Operations
    
    /// Add file to module or course
    func addFile(
        courseId: UUID,
        nodeId: UUID? = nil,
        fileName: String,
        fileType: String,
        localURL: String?,
        isSyllabus: Bool = false,
        isPracticeExam: Bool = false
    ) async throws -> CourseFile {
        let context = persistenceController.newBackgroundContext()
        
        return try await context.perform {
            let mo = CourseFileMO(context: context)
            let id = UUID()
            let now = Date()
            
            mo.id = id
            mo.courseId = courseId
            mo.nodeId = nodeId
            mo.fileName = fileName
            mo.fileType = fileType
            mo.localURL = localURL
            mo.isSyllabus = isSyllabus
            mo.isPracticeExam = isPracticeExam
            mo.category = FileCategory.uncategorized.rawValue
            mo.parseStatus = ParseStatus.notParsed.rawValue
            mo.syncStatus = "pending"
            mo.contentFingerprint = self.generateFingerprint(fileName: fileName)
            mo.createdAt = now
            mo.updatedAt = now
            
            try context.save()
            
            return CourseFile(
                id: id,
                courseId: courseId,
                nodeId: nodeId,
                filename: fileName,
                fileType: fileType,
                localURL: localURL,
                isSyllabus: isSyllabus,
                isPracticeExam: isPracticeExam,
                category: .uncategorized,
                parseStatus: .notParsed,
                parsedAt: nil,
                parseError: nil,
                contentFingerprint: self.generateFingerprint(fileName: fileName),
                createdAt: now,
                updatedAt: now
            )
        }
    }
    
    /// Fetch files for a module or course
    func fetchFiles(courseId: UUID, nodeId: UUID? = nil) async throws -> [CourseFile] {
        let context = persistenceController.newBackgroundContext()
        
        return try await context.perform {
            let request = CourseFileMO.fetchRequest()
            
            if let nodeId = nodeId {
                request.predicate = NSPredicate(format: "courseId == %@ AND nodeId == %@", courseId as CVarArg, nodeId as CVarArg)
            } else {
                request.predicate = NSPredicate(format: "courseId == %@ AND nodeId == nil", courseId as CVarArg)
            }
            
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            let results = try context.fetch(request)
            return results.map { self.toCourseDomain($0) }
        }
    }
    
    /// Update file sync status and iCloud URL
    func updateFileSync(
        id: UUID,
        iCloudURL: String?,
        syncStatus: String
    ) async throws {
        let context = persistenceController.newBackgroundContext()
        
        try await context.perform {
            let request = CourseFileMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let mo = try context.fetch(request).first else {
                throw NSError(domain: "CourseModuleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
            }
            
            mo.iCloudURL = iCloudURL
            mo.syncStatus = syncStatus
            mo.updatedAt = Date()
            
            try context.save()
        }
    }
    
    /// Update file parse status
    func updateFileParse(
        id: UUID,
        parseStatus: ParseStatus,
        parseError: String? = nil
    ) async throws {
        let context = persistenceController.newBackgroundContext()
        
        try await context.perform {
            let request = CourseFileMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let mo = try context.fetch(request).first else {
                throw NSError(domain: "CourseModuleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
            }
            
            mo.parseStatus = parseStatus.rawValue
            mo.parseError = parseError
            mo.parsedAt = parseStatus == .parsed ? Date() : nil
            mo.updatedAt = Date()
            
            try context.save()
        }
    }
    
    /// Delete file
    func deleteFile(id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()
        
        try await context.perform {
            let request = CourseFileMO.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let mo = try context.fetch(request).first else {
                throw NSError(domain: "CourseModuleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
            }
            
            context.delete(mo)
            try context.save()
        }
    }
    
    // MARK: - File Parse Results
    
    /// Save parse result
    func saveParseResult(
        fileId: UUID,
        parseType: String,
        success: Bool,
        extractedText: String?,
        contentJSON: String?,
        errorMessage: String?
    ) async throws {
        let context = persistenceController.newBackgroundContext()
        
        try await context.perform {
            let mo = FileParseResultMO(context: context)
            let now = Date()
            
            mo.id = UUID()
            mo.fileId = fileId
            mo.parseType = parseType
            mo.success = success
            mo.extractedText = extractedText
            mo.contentJSON = contentJSON
            mo.errorMessage = errorMessage
            mo.createdAt = now
            mo.updatedAt = now
            
            try context.save()
        }
    }
    
    // MARK: - Private Helpers
    
    private func toDomain(_ mo: CourseOutlineNodeMO) -> CourseOutlineNode {
        CourseOutlineNode(
            id: mo.id!,
            courseId: mo.courseId!,
            parentId: mo.parentId,
            type: CourseOutlineNodeType(rawValue: mo.type!) ?? .module,
            title: mo.title ?? "",
            sortIndex: Int(mo.sortIndex),
            createdAt: mo.createdAt ?? Date(),
            updatedAt: mo.updatedAt ?? Date()
        )
    }
    
    private func toCourseDomain(_ mo: CourseFileMO) -> CourseFile {
        CourseFile(
            id: mo.id!,
            courseId: mo.courseId!,
            nodeId: mo.nodeId,
            filename: mo.fileName ?? "",
            fileType: mo.fileType ?? "",
            localURL: mo.localURL,
            isSyllabus: mo.isSyllabus,
            isPracticeExam: mo.isPracticeExam,
            category: FileCategory(rawValue: mo.category ?? "") ?? .uncategorized,
            parseStatus: ParseStatus(rawValue: mo.parseStatus ?? "") ?? .notParsed,
            parsedAt: mo.parsedAt,
            parseError: mo.parseError,
            contentFingerprint: mo.contentFingerprint ?? "",
            createdAt: mo.createdAt ?? Date(),
            updatedAt: mo.updatedAt ?? Date()
        )
    }
    
    private func generateFingerprint(fileName: String) -> String {
        "\(fileName)-\(UUID().uuidString.prefix(8))"
    }
}
