#if os(macOS)
import SwiftUI

// MARK: - macOS-specific UI Extensions for Shared Assignment Types

extension AssignmentUrgency {
    var label: String {
        switch self {
        case .low: return "assignments.urgency.low".localized
        case .medium: return "assignments.urgency.medium".localized
        case .high: return "assignments.urgency.high".localized
        case .critical: return "assignments.urgency.critical".localized
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension AssignmentCategory {
    var localizedName: String {
        switch self {
        case .project: return "assignments.category.project".localized
        case .exam: return "assignments.category.exam".localized
        case .quiz: return "assignments.category.quiz".localized
        case .homework, .practiceHomework: return "assignments.category.homework".localized
        case .reading: return "assignments.category.reading".localized
        case .review: return "assignments.category.review".localized
        }
    }
}

extension AssignmentStatus {
    var label: String {
        switch self {
        case .notStarted: return "assignments.status.not_started".localized
        case .inProgress: return "assignments.status.in_progress".localized
        case .completed: return "assignments.status.completed".localized
        case .archived: return "assignments.status.archived".localized
        }
    }
}

#endif
