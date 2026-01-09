import Foundation

// MARK: - Parsing Job Status

enum ParsingJobStatus: String, Codable {
    case queued = "Queued"
    case running = "Running"
    case succeeded = "Succeeded"
    case failed = "Failed"
}

// MARK: - Parsing Job

struct SyllabusParsingJob: Identifiable, Codable {
    var id: UUID
    var courseId: UUID
    var fileId: UUID
    var status: ParsingJobStatus
    var startedAt: Date?
    var completedAt: Date?
    var errorMessage: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        courseId: UUID,
        fileId: UUID,
        status: ParsingJobStatus = .queued,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.courseId = courseId
        self.fileId = fileId
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.errorMessage = errorMessage
        self.createdAt = createdAt
    }
}

// MARK: - Parsed Assignment

struct ParsedAssignment: Identifiable, Codable {
    var id: UUID
    var jobId: UUID // Link back to parsing job
    var courseId: UUID
    var title: String
    var dueDate: Date?
    var dueTime: String? // Optional time string if parsed
    var inferredType: String? // e.g., "Homework", "Exam", "Project"
    var inferredCategory: String?
    var provenanceAnchor: String? // Text snippet from syllabus for traceability
    var rawText: String? // Full parsed text
    var createdAt: Date

    // Not imported to canonical assignments yet
    var isImported: Bool
    var importedTaskId: UUID?

    init(
        id: UUID = UUID(),
        jobId: UUID,
        courseId: UUID,
        title: String,
        dueDate: Date? = nil,
        dueTime: String? = nil,
        inferredType: String? = nil,
        inferredCategory: String? = nil,
        provenanceAnchor: String? = nil,
        rawText: String? = nil,
        createdAt: Date = Date(),
        isImported: Bool = false,
        importedTaskId: UUID? = nil
    ) {
        self.id = id
        self.jobId = jobId
        self.courseId = courseId
        self.title = title
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.inferredType = inferredType
        self.inferredCategory = inferredCategory
        self.provenanceAnchor = provenanceAnchor
        self.rawText = rawText
        self.createdAt = createdAt
        self.isImported = isImported
        self.importedTaskId = importedTaskId
    }
}
