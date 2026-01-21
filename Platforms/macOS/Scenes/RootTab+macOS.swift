#if os(macOS)
    import Foundation

    // Import shared RootTab enum - platform extensions only
    public extension RootTab {
        var title: String {
            switch self {
            case .dashboard: NSLocalizedString("tab.dashboard", value: "Dashboard", comment: "Sidebar tab")
            case .calendar: NSLocalizedString("tab.calendar", value: "Calendar", comment: "Sidebar tab")
            case .planner: NSLocalizedString("tab.planner", value: "Planner", comment: "Sidebar tab")
            case .assignments: NSLocalizedString("tab.assignments", value: "Assignments", comment: "Sidebar tab")
            case .courses: NSLocalizedString("tab.courses", value: "Courses", comment: "Sidebar tab")
            case .grades: NSLocalizedString("tab.grades", value: "Grades", comment: "Sidebar tab")
            case .timer: NSLocalizedString("tab.timer", value: "Timer", comment: "Sidebar tab")
            case .flashcards: NSLocalizedString("tab.flashcards", value: "Flashcards", comment: "Sidebar tab")
                // v1.1: Practice tests disabled
                // case .practice: NSLocalizedString("tab.practice", value: "Practice", comment: "Sidebar tab")
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: "square.grid.2x2"
            case .calendar: "calendar"
            case .planner: "pencil.and.list.clipboard"
            case .assignments: "slider.horizontal.3"
            case .courses: "book.closed"
            case .grades: "number.circle"
            case .timer: "timer"
            case .flashcards: "rectangle.stack"
                // v1.1: Practice tests disabled
                // case .practice: "list.clipboard"
            }
        }

        var logKey: String { title.lowercased().replacingOccurrences(of: " ", with: "") }
    }
#endif
