#if os(iOS)
import SwiftUI

enum SettingsCategory: String, CaseIterable, Identifiable {
    case general
    case calendar
    case reminders
    case planner
    case courses
    case semesters
    case interface
    case profiles
    case timer
    case flashcards
    case practice
    case integrations
    case notifications
    case intelligentScheduling
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
        case .reminders:
            return NSLocalizedString("settings.category.reminders", comment: "Reminders")
        case .planner:
            return NSLocalizedString("settings.category.planner", comment: "Planner")
        case .courses:
            return NSLocalizedString("settings.category.courses", comment: "Courses")
        case .semesters:
            return NSLocalizedString("settings.category.active_semesters", value: "Active Semesters", comment: "Active Semesters")
        case .interface:
            return NSLocalizedString("settings.category.interface", comment: "Interface")
        case .profiles:
            return NSLocalizedString("settings.category.profiles", comment: "Profiles")
        case .timer:
            return NSLocalizedString("settings.category.timer", comment: "Timer")
        case .flashcards:
            return NSLocalizedString("settings.category.flashcards", comment: "Flashcards")
        case .practice:
            return NSLocalizedString("settings.category.practice", value: "Practice", comment: "Practice")
        case .integrations:
            return NSLocalizedString("settings.category.integrations", comment: "Integrations")
        case .notifications:
            return NSLocalizedString("settings.category.notifications", comment: "Notifications")
        case .intelligentScheduling:
            return NSLocalizedString("settings.category.intelligentScheduling", comment: "Intelligent Scheduling")
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
        case .reminders: return "list.bullet.rectangle"
        case .planner: return "pencil.and.list.clipboard"
        case .courses: return "books.vertical"
        case .semesters: return "graduationcap"
        case .interface: return "sidebar.left"
        case .profiles: return "person.crop.circle"
        case .timer: return "timer"
        case .flashcards: return "rectangle.stack.badge.person.crop"
        case .practice: return "pencil.and.list.clipboard"
        case .integrations: return "arrow.triangle.2.circlepath.circle"
        case .notifications: return "bell.badge"
        case .intelligentScheduling: return "brain"
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
        case .reminders:
            IOSRemindersSettingsView()
        case .planner:
            IOSPlannerSettingsView()
        case .courses:
            IOSCoursesSettingsView()
        case .semesters:
            IOSSemestersSettingsView()
        case .interface:
            IOSInterfaceSettingsView()
        case .profiles:
            IOSProfilesSettingsView()
        case .timer:
            IOSTimerSettingsView()
        case .flashcards:
            IOSFlashcardsSettingsView()
        case .practice:
            IOSPracticeSettingsView()
        case .integrations:
            IOSIntegrationsSettingsView()
        case .notifications:
            IOSNotificationsSettingsView()
        case .intelligentScheduling:
            IOSIntelligentSchedulingSettingsView()
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
