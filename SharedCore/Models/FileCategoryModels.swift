import Foundation

/// Category classification for course files
enum FileCategory: String, Codable, CaseIterable, Identifiable {
    case uncategorized = "uncategorized"
    case notes = "notes"
    case test = "test"
    case syllabus = "syllabus"
    case classNotes = "class"
    case rubric = "rubric"
    case practiceTest = "practiceTest"
    case assignmentList = "assignmentList"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .uncategorized: return "Uncategorized"
        case .notes: return "Notes"
        case .test: return "Test"
        case .syllabus: return "Syllabus"
        case .classNotes: return "Class"
        case .rubric: return "Rubric"
        case .practiceTest: return "Practice Test"
        case .assignmentList: return "Assignment List"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .uncategorized: return "questionmark.square"
        case .notes: return "note.text"
        case .test: return "checkmark.seal"
        case .syllabus: return "doc.text.below.ecg"
        case .classNotes: return "book"
        case .rubric: return "list.clipboard"
        case .practiceTest: return "pencil.and.list.clipboard"
        case .assignmentList: return "checklist"
        case .other: return "doc"
        }
    }
    
    /// Whether this category triggers auto-parsing
    var triggersAutoParsing: Bool {
        switch self {
        case .syllabus, .classNotes, .rubric, .practiceTest, .test, .assignmentList:
            return true
        case .uncategorized, .notes, .other:
            return false
        }
    }
    
    /// Weight for practice test generation (0.0 - 1.0)
    var practiceTestWeight: Double {
        switch self {
        case .rubric: return 1.00
        case .syllabus: return 0.90
        case .classNotes: return 0.80
        case .practiceTest: return 0.75
        case .test: return 0.70
        case .notes: return 0.40
        case .other: return 0.20
        case .uncategorized: return 0.10
        case .assignmentList: return 0.60
        }
    }
}

/// Parse status for course files
enum ParseStatus: String, Codable {
    case notParsed = "notParsed"
    case queued = "queued"
    case parsing = "parsing"
    case parsed = "parsed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .notParsed: return "Not Parsed"
        case .queued: return "Queued"
        case .parsing: return "Parsing..."
        case .parsed: return "Parsed"
        case .failed: return "Failed"
        }
    }
    
    var icon: String {
        switch self {
        case .notParsed: return "circle"
        case .queued: return "clock"
        case .parsing: return "arrow.triangle.2.circlepath"
        case .parsed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
    
    var color: String {
        switch self {
        case .notParsed: return "gray"
        case .queued: return "orange"
        case .parsing: return "blue"
        case .parsed: return "green"
        case .failed: return "red"
        }
    }
}
