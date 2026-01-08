#if os(macOS)
import Foundation

// Import shared RootTab enum - platform extensions only
public extension RootTab {
    var title: String {
        switch self {
        case .dashboard:    return NSLocalizedString("tab.dashboard", value: "Dashboard", comment: "Sidebar tab")
        case .calendar:     return NSLocalizedString("tab.calendar", value: "Calendar", comment: "Sidebar tab")
        case .planner:      return NSLocalizedString("tab.planner", value: "Planner", comment: "Sidebar tab")
        case .assignments:  return NSLocalizedString("tab.assignments", value: "Assignments", comment: "Sidebar tab")
        case .courses:      return NSLocalizedString("tab.courses", value: "Courses", comment: "Sidebar tab")
        case .grades:       return NSLocalizedString("tab.grades", value: "Grades", comment: "Sidebar tab")
        case .timer:        return NSLocalizedString("tab.timer", value: "Timer", comment: "Sidebar tab")
        case .flashcards:   return NSLocalizedString("tab.flashcards", value: "Flashcards", comment: "Sidebar tab")
        case .practice:     return NSLocalizedString("tab.practice", value: "Practice", comment: "Sidebar tab")
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:    return "square.grid.2x2"
        case .calendar:     return "calendar"
        case .planner:      return "pencil.and.list.clipboard"
        case .assignments:  return "slider.horizontal.3"
        case .courses:      return "book.closed"
        case .grades:       return "number.circle"
        case .timer:        return "timer"
        case .flashcards:   return "rectangle.stack"
        case .practice:     return "list.clipboard"
        }
    }

    var logKey: String { title.lowercased().replacingOccurrences(of: " ", with: "") }
}
#endif
