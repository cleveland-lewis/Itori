import Foundation
#if canImport(SwiftUI)
    import SwiftUI
#endif

// MARK: - Shared Planning Models

// These types are available on all platforms (macOS, iOS, watchOS)

public enum AssignmentCategory: String, CaseIterable, Codable, Identifiable {
    case reading, exam, homework, quiz, review, project, practiceTest

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .project: "Project"
        case .exam: "Exam"
        case .quiz: "Quiz"
        case .homework: "Homework"
        case .reading: "Reading"
        case .review: "Review"
        case .practiceTest: "Practice Test"
        }
    }
}

public enum AssignmentUrgency: String, Codable, CaseIterable, Hashable, Identifiable {
    case low, medium, high, critical

    public var id: String { rawValue }

    /// Limited selection for assignment creation UIs (no critical/urgent levels).
    public static var creationOptions: [AssignmentUrgency] {
        [.low, .medium, .high]
    }

    // Default implementation for non-macOS platforms
    // macOS uses localized versions from Platforms/macOS/Extensions/AssignmentExtensions.swift
    #if !os(macOS)
        public var color: Color {
            switch self {
            case .low: .green
            case .medium: .yellow
            case .high: .orange
            case .critical: .red
            }
        }

        public var systemIcon: String {
            switch self {
            case .low: "checkmark.circle.fill"
            case .medium: "exclamationmark.circle.fill"
            case .high: "exclamationmark.triangle.fill"
            case .critical: "exclamationmark.octagon.fill"
            }
        }

        public var label: String {
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            case .critical: "Critical"
            }
        }
    #endif
}

public enum AssignmentStatus: String, Codable, CaseIterable, Sendable, Identifiable {
    case notStarted
    case inProgress
    case completed
    case archived

    public var id: String { rawValue }

    // Default implementation for non-macOS platforms
    // macOS uses localized versions from Platforms/macOS/Extensions/AssignmentExtensions.swift
    #if !os(macOS)
        public var systemIcon: String {
            switch self {
            case .notStarted: "circle"
            case .inProgress: "circle.lefthalf.filled"
            case .completed: "checkmark.circle.fill"
            case .archived: "archivebox.fill"
            }
        }

        public var label: String {
            switch self {
            case .notStarted: "Not Started"
            case .inProgress: "In Progress"
            case .completed: "Completed"
            case .archived: "Archived"
            }
        }
    #endif
}

public struct PlanStepStub: Codable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var expectedMinutes: Int

    public init(id: UUID = UUID(), title: String = "", expectedMinutes: Int = 0) {
        self.id = id
        self.title = title
        self.expectedMinutes = expectedMinutes
    }
}

public struct Assignment: Identifiable, Codable, Hashable {
    public let id: UUID
    public var courseId: UUID?
    public var moduleIds: [UUID]
    public var title: String
    public var dueDate: Date
    public var dueTimeMinutes: Int?
    public var estimatedMinutes: Int
    public var weightPercent: Double?
    public var category: AssignmentCategory
    public var urgency: AssignmentUrgency
    public var isLockedToDueDate: Bool
    public var plan: [PlanStepStub]

    // Optional UI/tracking fields
    public var status: AssignmentStatus?
    public var courseCode: String?
    public var courseName: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        courseId: UUID? = nil,
        moduleIds: [UUID] = [],
        title: String = "",
        dueDate: Date = Date(),
        dueTimeMinutes: Int? = nil,
        estimatedMinutes: Int = 60,
        weightPercent: Double? = nil,
        category: AssignmentCategory = .homework,
        urgency: AssignmentUrgency = .medium,
        isLockedToDueDate: Bool = false,
        plan: [PlanStepStub] = [],
        status: AssignmentStatus? = nil,
        courseCode: String? = nil,
        courseName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.courseId = courseId
        self.moduleIds = moduleIds
        self.title = title
        self.dueDate = Calendar.current.startOfDay(for: dueDate)
        self.dueTimeMinutes = dueTimeMinutes
        self.estimatedMinutes = estimatedMinutes
        self.weightPercent = weightPercent
        self.category = category
        self.urgency = urgency
        self.isLockedToDueDate = isLockedToDueDate
        self.plan = plan
        self.status = status
        self.courseCode = courseCode
        self.courseName = courseName
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case courseId
        case moduleIds
        case title
        case dueDate
        case dueTimeMinutes
        case estimatedMinutes
        case weightPercent
        case category
        case urgency
        case isLockedToDueDate
        case plan
        case status
        case courseCode
        case courseName
        case notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        courseId = try container.decodeIfPresent(UUID.self, forKey: .courseId)
        moduleIds = try container.decodeIfPresent([UUID].self, forKey: .moduleIds) ?? []
        title = try container.decode(String.self, forKey: .title)
        let decodedDue = try container.decode(Date.self, forKey: .dueDate)
        let decodedDueTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .dueTimeMinutes)
        dueDate = Calendar.current.startOfDay(for: decodedDue)
        if let decodedDueTimeMinutes {
            dueTimeMinutes = decodedDueTimeMinutes
        } else {
            let components = Calendar.current.dateComponents([.hour, .minute], from: decodedDue)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            dueTimeMinutes = minutes == 0 ? nil : minutes
        }
        estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        weightPercent = try container.decodeIfPresent(Double.self, forKey: .weightPercent)
        category = try container.decode(AssignmentCategory.self, forKey: .category)
        urgency = try container.decode(AssignmentUrgency.self, forKey: .urgency)
        isLockedToDueDate = try container.decode(Bool.self, forKey: .isLockedToDueDate)
        plan = try container.decodeIfPresent([PlanStepStub].self, forKey: .plan) ?? []
        status = try container.decodeIfPresent(AssignmentStatus.self, forKey: .status)
        courseCode = try container.decodeIfPresent(String.self, forKey: .courseCode)
        courseName = try container.decodeIfPresent(String.self, forKey: .courseName)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(courseId, forKey: .courseId)
        try container.encode(moduleIds, forKey: .moduleIds)
        try container.encode(title, forKey: .title)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(dueTimeMinutes, forKey: .dueTimeMinutes)
        try container.encode(estimatedMinutes, forKey: .estimatedMinutes)
        try container.encodeIfPresent(weightPercent, forKey: .weightPercent)
        try container.encode(category, forKey: .category)
        try container.encode(urgency, forKey: .urgency)
        try container.encode(isLockedToDueDate, forKey: .isLockedToDueDate)
        try container.encode(plan, forKey: .plan)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(courseCode, forKey: .courseCode)
        try container.encodeIfPresent(courseName, forKey: .courseName)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// Event categorization used across platforms
public enum EventCategoryStub: String, Codable, CaseIterable {
    case homework, classSession, study, exam, meeting, other
}

// MARK: - Planner Integration

public extension Assignment {
    /// Planner-specific computed properties for scheduling algorithm
    var plannerPriorityWeight: Double {
        // Convert urgency to priority weight (0...1 scale)
        switch urgency {
        case .low: 0.2
        case .medium: 0.6
        case .high: 0.8
        case .critical: 1.0
        }
    }

    var plannerEstimatedMinutes: Int {
        estimatedMinutes
    }

    var plannerDueDate: Date? {
        effectiveDueDateTime
    }

    var plannerCourseId: UUID? {
        courseId
    }

    var plannerCategory: AssignmentCategory {
        category
    }

    /// Difficulty estimation for planner (0...1 scale)
    /// Based on category and estimated time
    var plannerDifficulty: Double {
        let baseForCategory = switch category {
        case .exam: 0.9
        case .project: 0.8
        case .quiz: 0.7
        case .homework: 0.6
        case .reading: 0.5
        case .review: 0.4
        case .practiceTest: 0.7
        }

        // Adjust by time estimate
        let timeAdjustment: Double = {
            if estimatedMinutes < 30 { return -0.1 }
            if estimatedMinutes > 120 { return 0.1 }
            return 0.0
        }()

        return min(1.0, max(0.0, baseForCategory + timeAdjustment))
    }
}

public extension Assignment {
    var effectiveDueDateTime: Date {
        if let dueTimeMinutes {
            return Calendar.current.date(byAdding: .minute, value: dueTimeMinutes, to: dueDate) ?? dueDate
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 23
        components.minute = 59
        return Calendar.current.date(from: components) ?? dueDate
    }

    var hasExplicitDueTime: Bool {
        dueTimeMinutes != nil
    }
}
