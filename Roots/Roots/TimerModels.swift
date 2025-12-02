import Foundation

// MARK: - Models

/// Represents an activity the user can time (e.g., study task, assignment, course work)
struct TimerActivity: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var courseID: UUID?
    var assignmentID: UUID?
    var studyCategory: StudyCategory?
    var collectionID: UUID?
    var colorHex: String?
    var emoji: String?

    init(id: UUID = UUID(), name: String, courseID: UUID? = nil, assignmentID: UUID? = nil, studyCategory: StudyCategory? = nil, collectionID: UUID? = nil, colorHex: String? = nil, emoji: String? = nil) {
        self.id = id
        self.name = name
        self.courseID = courseID
        self.assignmentID = assignmentID
        self.studyCategory = studyCategory
        self.collectionID = collectionID
        self.colorHex = colorHex
        self.emoji = emoji
    }
}

enum StudyCategory: String, CaseIterable, Codable {
    case reading
    case problemSolving
    case reviewing
    case writing
    case other
}

/// Collection of activities
struct ActivityCollection: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var description: String?

    init(id: UUID = UUID(), name: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}

/// Timer modes
enum TimerMode: String, CaseIterable, Codable {
    case omodoro
    case timer
    case stopwatch
}

/// Represents a run/session
struct FocusSession: Identifiable, Hashable, Codable {
    enum State: String, Codable {
        case idle
        case running
        case paused
        case completed
        case cancelled
    }

    let id: UUID
    let activityID: UUID?
    let mode: TimerMode
    let plannedDuration: TimeInterval?
    var startedAt: Date?
    var endedAt: Date?
    var state: State

    init(id: UUID = UUID(), activityID: UUID? = nil, mode: TimerMode = .omodoro, plannedDuration: TimeInterval? = nil, startedAt: Date? = nil, endedAt: Date? = nil, state: State = .idle) {
        self.id = id
        self.activityID = activityID
        self.mode = mode
        self.plannedDuration = plannedDuration
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.state = state
    }
}
