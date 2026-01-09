import Foundation

enum QuickAction: String, CaseIterable, Identifiable, Codable {
    case add_assignment
    case add_course
    case add_task
    case add_grade
    case auto_schedule
    case quick_note
    case open_new_note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .add_assignment: "Add Assignment"
        case .add_course: "Add Course"
        case .add_task: "Add Task"
        case .add_grade: "Add Grade"
        case .auto_schedule: "Auto Schedule"
        case .quick_note: "Quick Note"
        case .open_new_note: "New Note"
        }
    }

    var systemImage: String {
        switch self {
        case .add_assignment: "plus.square.on.square"
        case .add_course: "book.badge.plus"
        case .add_task: "checkmark.circle.badge.plus"
        case .add_grade: "chart.bar.doc.horizontal"
        case .auto_schedule: "wand.and.stars"
        case .quick_note: "pencil"
        case .open_new_note: "square.and.pencil"
        }
    }

    static let defaultSelection: [QuickAction] = [
        .add_assignment,
        .add_course,
        .quick_note,
        .add_grade
    ]
}
