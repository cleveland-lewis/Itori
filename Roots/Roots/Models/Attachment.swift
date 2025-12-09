import Foundation

/// Tag for categorizing attachments
enum AttachmentTag: String, Codable, CaseIterable, Identifiable {
    case syllabus = "Syllabus"
    case learningOutcome = "Learning Outcome"
    case practiceExam = "Practice Exam"
    case practiceProblem = "Practice Problem"
    case rubric = "Rubric"
    case guidelines = "Guidelines"
    case notes = "Notes"
    case lectureSlides = "Lecture Slides"
    case other = "Other"

    var id: String { rawValue }

    /// Returns the appropriate SF Symbol icon for each tag
    var icon: String {
        switch self {
        case .syllabus:
            return "doc.text"
        case .learningOutcome:
            return "list.bullet.clipboard"
        case .practiceExam:
            return "checkmark.seal"
        case .practiceProblem:
            return "puzzlepiece"
        case .rubric:
            return "checklist"
        case .guidelines:
            return "list.clipboard"
        case .notes:
            return "note.text"
        case .lectureSlides:
            return "play.rectangle"
        case .other:
            return "paperclip"
        }
    }
}

/// Represents a file attachment for courses or tasks
struct Attachment: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var localURL: URL
    var tag: AttachmentTag
    var moduleNumber: Int?
    var dateAdded: Date

    init(id: UUID = UUID(),
         name: String,
         localURL: URL,
         tag: AttachmentTag,
         moduleNumber: Int? = nil,
         dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.localURL = localURL
        self.tag = tag
        self.moduleNumber = moduleNumber
        self.dateAdded = dateAdded
    }

    /// Determines if the file is parsable (PDF or text-based)
    var isParsable: Bool {
        let fileExtension = localURL.pathExtension.lowercased()
        return ["pdf", "txt", "md", "rtf", "doc", "docx"].contains(fileExtension)
    }

    /// Returns the file extension in uppercase
    var fileExtension: String {
        localURL.pathExtension.uppercased()
    }

    /// Returns the file size if available
    var fileSize: Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }

    /// Returns formatted file size (e.g., "1.5 MB")
    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
