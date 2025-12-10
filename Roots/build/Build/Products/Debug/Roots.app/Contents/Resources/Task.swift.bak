import Foundation

enum TaskPriority: Int, Codable, Comparable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var color: String { // specific color names handled by View or DesignSystem
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "blue"
        }
    }
}

struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var dueDate: Date
    var priority: TaskPriority
    var isCompleted: Bool
    var completedDate: Date?

    // Add any other existing properties you have (e.g. courseID, notes)

    init(id: UUID = UUID(),
         title: String,
         dueDate: Date,
         priority: TaskPriority = .medium,
         isCompleted: Bool = false,
         completedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }

    // Helpers for Grouping
    var isOverdue: Bool {
        return !isCompleted && dueDate < Calendar.current.startOfDay(for: Date())
    }
    
    var isDueToday: Bool {
        return !isCompleted && Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueTomorrow: Bool {
        return !isCompleted && Calendar.current.isDateInTomorrow(dueDate)
    }
}
