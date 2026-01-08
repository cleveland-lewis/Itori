#if os(iOS)
import SwiftUI

enum SettingsCategory: String, CaseIterable, Identifiable {
    case general
    case calendar
    case planner
    case courses
    case semesters
    case interface
    case notifications
    case privacy
    case storage
    case developer
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general:
            return NSLocalizedString("settings.category.general", comment: "General")
        case .calendar:
            return NSLocalizedString("settings.category.calendar", comment: "Calendar")
        case .planner:
            return NSLocalizedString("settings.category.planner", comment: "Planner")
        case .courses:
            return NSLocalizedString("settings.category.courses", comment: "Courses")
        case .semesters:
            return NSLocalizedString("settings.category.semesters", value: "Semesters", comment: "Semesters")
        case .interface:
            return NSLocalizedString("settings.category.interface", comment: "Interface")
        case .notifications:
            return NSLocalizedString("settings.category.notifications", comment: "Notifications")
        case .privacy:
            return NSLocalizedString("settings.category.privacy", comment: "Privacy")
        case .storage:
            return NSLocalizedString("settings.category.storage", comment: "Storage")
        case .developer:
            return NSLocalizedString("settings.category.developer", comment: "Developer")
        }
    }
    
    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .calendar: return "calendar"
        case .planner: return "pencil.and.list.clipboard"
        case .courses: return "books.vertical"
        case .semesters: return "graduationcap"
        case .interface: return "sidebar.left"
        case .notifications: return "bell.badge"
        case .privacy: return "lock.shield"
        case .storage: return "externaldrive"
        case .developer: return "hammer.fill"
        }
    }
    
    @ViewBuilder
    func destinationView() -> some View {
        switch self {
        case .general:
            IOSGeneralSettingsView()
        case .calendar:
            IOSCalendarSettingsView()
        case .planner:
            IOSPlannerSettingsView()
        case .courses:
            IOSCoursesSettingsView()
        case .semesters:
            IOSSemestersSettingsView()
        case .interface:
            IOSInterfaceSettingsView()
        case .notifications:
            IOSNotificationsSettingsView()
        case .privacy:
            IOSPrivacySettingsView()
        case .storage:
            IOSStorageSettingsView()
        case .developer:
            IOSDeveloperSettingsView()
        }
    }
}
#endif
