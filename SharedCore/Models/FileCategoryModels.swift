import Foundation

/// Category classification for course files
enum FileCategory: String, Codable, CaseIterable, Identifiable {
    case uncategorized
    case notes
    case test
    case syllabus
    case classNotes = "class"
    case rubric
    case practiceTest
    case assignmentList
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uncategorized: "Uncategorized"
        case .notes: "Notes"
        case .test: "Test"
        case .syllabus: "Syllabus"
        case .classNotes: "Class"
        case .rubric: "Rubric"
        case .practiceTest: "Practice Test"
        case .assignmentList: "Assignment List"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .uncategorized: "questionmark.square"
        case .notes: "note.text"
        case .test: "checkmark.seal"
        case .syllabus: "doc.text.below.ecg"
        case .classNotes: "book"
        case .rubric: "list.clipboard"
        case .practiceTest: "pencil.and.list.clipboard"
        case .assignmentList: "checklist"
        case .other: "doc"
        }
    }

    /// Whether this category triggers auto-parsing
    var triggersAutoParsing: Bool {
        switch self {
        case .syllabus, .classNotes, .rubric, .practiceTest, .test, .assignmentList:
            true
        case .uncategorized, .notes, .other:
            false
        }
    }

    /// Weight for practice test generation (0.0 - 1.0)
    var practiceTestWeight: Double {
        switch self {
        case .rubric: 1.00
        case .syllabus: 0.90
        case .classNotes: 0.80
        case .practiceTest: 0.75
        case .test: 0.70
        case .notes: 0.40
        case .other: 0.20
        case .uncategorized: 0.10
        case .assignmentList: 0.60
        }
    }
}

/// Parse status for course files
enum ParseStatus: String, Codable {
    case notParsed
    case queued
    case parsing
    case parsed
    case failed

    var displayName: String {
        switch self {
        case .notParsed: "Not Parsed"
        case .queued: "Parsing"
        case .parsing: "Parsing"
        case .parsed: "Parsed"
        case .failed: "Error parsing"
        }
    }

    var icon: String {
        switch self {
        case .notParsed: "circle"
        case .queued: "clock"
        case .parsing: "arrow.triangle.2.circlepath"
        case .parsed: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }

    var color: String {
        switch self {
        case .notParsed: "gray"
        case .queued: "orange"
        case .parsing: "blue"
        case .parsed: "green"
        case .failed: "red"
        }
    }
}
