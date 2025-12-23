import SwiftUI

enum SettingsCategory: String, CaseIterable, Identifiable {
    case general
    case accessibility
    case interface
    case appearance
    case timer
    case calendar
    case privacy
    case storage
    case coursesPlanner
    case notifications
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general:
            return NSLocalizedString("settings.category.general", comment: "General")
        case .accessibility:
            return NSLocalizedString("settings.category.accessibility", comment: "Accessibility")
        case .interface:
            return NSLocalizedString("settings.category.interface", comment: "Interface")
        case .appearance:
            return NSLocalizedString("settings.category.appearance", comment: "Appearance")
        case .timer:
            return NSLocalizedString("settings.category.timer", comment: "Timer")
        case .calendar:
            return NSLocalizedString("settings.category.calendar", comment: "Calendar")
        case .privacy:
            return NSLocalizedString("settings.category.privacy", comment: "Privacy")
        case .storage:
            return NSLocalizedString("settings.category.storage", comment: "Storage")
        case .coursesPlanner:
            return NSLocalizedString("settings.category.courses_planner", comment: "Courses & Planner")
        case .notifications:
            return NSLocalizedString("settings.category.notifications", comment: "Notifications")
        }
    }
    
    var systemImage: String {
        switch self {
        case .general:
            return "gearshape"
        case .accessibility:
            return "accessibility"
        case .interface:
            return "sidebar.left"
        case .appearance:
            return "paintbrush"
        case .timer:
            return "timer"
        case .calendar:
            return "calendar"
        case .privacy:
            return "hand.raised"
        case .storage:
            return "internaldrive"
        case .coursesPlanner:
            return "book.and.wrench"
        case .notifications:
            return "bell.badge"
        }
    }
    
    @ViewBuilder
    func destinationView() -> some View {
        switch self {
        case .general:
            GeneralSettingsView()
        case .accessibility:
            AccessibilitySettingsView()
        case .interface:
            InterfaceSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .timer:
            TimerSettingsView()
        case .calendar:
            CalendarSettingsView()
        case .privacy:
            PrivacySettingsView()
        case .storage:
            StorageSettingsView()
        case .coursesPlanner:
            CoursesPlannerSettingsView()
        case .notifications:
            NotificationsSettingsView()
        }
    }
}
