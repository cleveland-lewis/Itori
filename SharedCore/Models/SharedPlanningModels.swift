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
        case .project: return "Project"
        case .exam: return "Exam"
        case .quiz: return "Quiz"
        case .homework: return "Homework"
        case .reading: return "Reading"
        case .review: return "Review"
        case .practiceTest: return "Practice Test"
        }
    }
}

public enum AssignmentUrgency: String, Codable, CaseIterable, Hashable, Identifiable {
    case low, medium, high, critical
    
    public var id: String { rawValue }
    
    // Default implementation for non-macOS platforms
    // macOS uses localized versions from Platforms/macOS/Extensions/AssignmentExtensions.swift
    #if !os(macOS)
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    public var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
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
    public var label: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .archived: return "Archived"
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

extension Assignment {
    /// Planner-specific computed properties for scheduling algorithm
    public var plannerPriorityWeight: Double {
        // Convert urgency to priority weight (0...1 scale)
        switch urgency {
        case .low: return 0.2
        case .medium: return 0.6
        case .high: return 0.8
        case .critical: return 1.0
        }
    }
    
    public var plannerEstimatedMinutes: Int {
        estimatedMinutes
    }
    
    public var plannerDueDate: Date? {
        effectiveDueDateTime
    }
    
    public var plannerCourseId: UUID? {
        courseId
    }
    
    public var plannerCategory: AssignmentCategory {
        category
    }
    
    /// Difficulty estimation for planner (0...1 scale)
    /// Based on category and estimated time
    public var plannerDifficulty: Double {
        let baseForCategory: Double = {
            switch category {
            case .exam: return 0.9
            case .project: return 0.8
            case .quiz: return 0.7
            case .homework: return 0.6
            case .reading: return 0.5
            case .review: return 0.4
            case .practiceTest: return 0.7
            }
        }()
        
        // Adjust by time estimate
        let timeAdjustment: Double = {
            if estimatedMinutes < 30 { return -0.1 }
            if estimatedMinutes > 120 { return 0.1 }
            return 0.0
        }()
        
        return min(1.0, max(0.0, baseForCategory + timeAdjustment))
    }
}

extension Assignment {
    public var effectiveDueDateTime: Date {
        if let dueTimeMinutes {
            return Calendar.current.date(byAdding: .minute, value: dueTimeMinutes, to: dueDate) ?? dueDate
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 23
        components.minute = 59
        return Calendar.current.date(from: components) ?? dueDate
    }
    
    public var hasExplicitDueTime: Bool {
        dueTimeMinutes != nil
    }
}
