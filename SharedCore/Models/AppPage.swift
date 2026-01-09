import Foundation

enum AppPage: String, CaseIterable, Identifiable {
    case dashboard
    case calendar
    case planner
    case assignments
    case courses
    case grades
    case timer
    case flashcards
    case practice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: NSLocalizedString("tab.dashboard", value: "Dashboard", comment: "Page title")
        case .calendar: NSLocalizedString("tab.calendar", value: "Calendar", comment: "Page title")
        case .planner: NSLocalizedString("tab.planner", value: "Planner", comment: "Page title")
        case .assignments: NSLocalizedString("tab.assignments", value: "Assignments", comment: "Page title")
        case .courses: NSLocalizedString("tab.courses", value: "Courses", comment: "Page title")
        case .grades: NSLocalizedString("tab.grades", value: "Grades", comment: "Page title")
        case .timer: NSLocalizedString("tab.timer", value: "Timer", comment: "Page title")
        case .flashcards: NSLocalizedString("tab.flashcards", value: "Flashcards", comment: "Page title")
        case .practice: NSLocalizedString("tab.practice", value: "Practice", comment: "Page title")
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "rectangle.grid.2x2"
        case .calendar: "calendar"
        case .planner: "square.and.pencil"
        case .assignments: "checklist"
        case .courses: "book.closed"
        case .grades: "chart.bar.doc.horizontal"
        case .timer: "timer"
        case .flashcards: "rectangle.stack"
        case .practice: "list.clipboard"
        }
    }

    static func from(_ rootTab: RootTab) -> AppPage {
        AppPage(rawValue: rootTab.rawValue) ?? .dashboard
    }
}
