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
        case .dashboard:  return NSLocalizedString("tab.dashboard", value: "Dashboard", comment: "Page title")
        case .calendar:   return NSLocalizedString("tab.calendar", value: "Calendar", comment: "Page title")
        case .planner:    return NSLocalizedString("tab.planner", value: "Planner", comment: "Page title")
        case .assignments:return NSLocalizedString("tab.assignments", value: "Assignments", comment: "Page title")
        case .courses:    return NSLocalizedString("tab.courses", value: "Courses", comment: "Page title")
        case .grades:     return NSLocalizedString("tab.grades", value: "Grades", comment: "Page title")
        case .timer:      return NSLocalizedString("tab.timer", value: "Timer", comment: "Page title")
        case .flashcards: return NSLocalizedString("tab.flashcards", value: "Flashcards", comment: "Page title")
        case .practice:   return NSLocalizedString("tab.practice", value: "Practice", comment: "Page title")
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:   return "rectangle.grid.2x2"
        case .calendar:    return "calendar"
        case .planner:     return "square.and.pencil"
        case .assignments: return "checklist"
        case .courses:     return "book.closed"
        case .grades:      return "chart.bar.doc.horizontal"
        case .timer:       return "timer"
        case .flashcards:  return "rectangle.stack"
        case .practice:    return "list.clipboard"
        }
    }
    
    static func from(_ rootTab: RootTab) -> AppPage {
        AppPage(rawValue: rootTab.rawValue) ?? .dashboard
    }
}
