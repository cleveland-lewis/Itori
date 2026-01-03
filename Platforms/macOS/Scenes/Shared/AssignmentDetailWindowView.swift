import SwiftUI

struct AssignmentDetailWindowView: View {
    let task: AppTask
    let courses: [Course]
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void

    var body: some View {
        List {
            Section {
                Button(action: onToggleCompletion) {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
                        Text(task.isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                            .font(.body.weight(.medium))
                    }
                }
            }

            Section(header: Text("Details")) {
                DetailRow(label: "Title", value: task.title)
                if let courseLabel = courseLabel {
                    DetailRow(label: "Course", value: courseLabel)
                }
                DetailRow(label: "Type", value: typeLabel(task.type))
                if task.due != nil {
                    DetailRow(label: "Due Date", value: formatDueDisplay(for: task))
                } else {
                    DetailRow(label: "Due Date", value: "Not Set", isSecondary: true)
                }
            }

            Section(header: Text("Time & Effort")) {
                DetailRow(label: timeEstimateLabel(task.type), value: "\(task.estimatedMinutes) min")
                DetailRow(label: "Priority", value: priorityLabel(task.importance))
            }

            if let earned = task.gradeEarnedPoints,
               let possible = task.gradePossiblePoints,
               possible > 0 {
                Section(header: Text("Grade")) {
                    let gradePercent = (earned / possible) * 100
                    DetailRow(label: "Score", value: String(format: "%.1f%% (%.1f/%.1f)", gradePercent, earned, possible))
                    if let weight = task.gradeWeightPercent {
                        DetailRow(label: "Weight", value: String(format: "%.1f%% of course", weight))
                    }
                }
            }

            Section {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Assignment", systemImage: "trash")
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.automatic)
        #endif
    }

    private var courseLabel: String? {
        guard let courseId = task.courseId else { return nil }
        guard let course = courses.first(where: { $0.id == courseId }) else { return nil }
        if course.code.isEmpty {
            return course.title
        } else {
            return "\(course.code) · \(course.title)"
        }
    }

    private func formatDueDisplay(for task: AppTask) -> String {
        guard let due = task.due else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = task.hasExplicitDueTime ? .short : .none
        let date = task.hasExplicitDueTime ? (task.effectiveDueDateTime ?? due) : due
        return formatter.string(from: date)
    }

    private func typeLabel(_ type: TaskType) -> String {
        switch type {
        case .homework: return "Homework"
        case .quiz: return "Quiz"
        case .exam: return "Exam"
        case .reading: return "Reading"
        case .review: return "Review"
        case .study: return "Study"
        case .project: return "Project"
        }
    }

    private func timeEstimateLabel(_ type: TaskType) -> String {
        switch type {
        case .exam, .quiz:
            return "Estimated Study Time"
        case .homework, .reading, .project, .review, .study:
            return "Estimated Work Time"
        }
    }

    private func priorityLabel(_ value: Double) -> String {
        switch value {
        case ..<0.3: return "Lowest"
        case ..<0.5: return "Low"
        case ..<0.7: return "Medium"
        case ..<0.9: return "High"
        default: return "Urgent"
        }
    }

    private struct DetailRow: View {
        let label: String
        let value: String
        var isSecondary: Bool = false

        var body: some View {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.body)
                    .foregroundStyle(isSecondary ? .secondary : .primary)
            }
            .padding(.vertical, 4)
        }
    }
}
