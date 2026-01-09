#if os(macOS)
    import SwiftUI

    // MARK: - macOS-specific UI Extensions for Shared Assignment Types

    extension AssignmentUrgency {
        var label: String {
            switch self {
            case .low: "assignments.urgency.low".localized
            case .medium: "assignments.urgency.medium".localized
            case .high: "assignments.urgency.high".localized
            case .critical: "assignments.urgency.critical".localized
            }
        }

        var color: Color {
            switch self {
            case .low: .green
            case .medium: .yellow
            case .high: .orange
            case .critical: .red
            }
        }
    }

    extension AssignmentCategory {
        var localizedName: String {
            switch self {
            case .project: "assignments.category.project".localized
            case .exam: "assignments.category.exam".localized
            case .quiz: "assignments.category.quiz".localized
            case .homework, .homework: "assignments.category.homework".localized
            case .reading: "assignments.category.reading".localized
            case .review: "assignments.category.review".localized
            case .practiceTest: "assignments.category.practice_test".localized
            }
        }
    }

    extension AssignmentStatus {
        var label: String {
            switch self {
            case .notStarted: "assignments.status.not_started".localized
            case .inProgress: "assignments.status.in_progress".localized
            case .completed: "assignments.status.completed".localized
            case .archived: "assignments.status.archived".localized
            }
        }
    }

#endif
