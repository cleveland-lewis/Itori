#if os(macOS)
import AppKit

enum SettingsToolbarIdentifier: String, CaseIterable, Identifiable {
    case general
    case calendar
    case planner
    case courses
    case semesters
    case interface
    case profiles
    case ai
    case integrations
    case notifications
    case privacy
    case storage
    case developer
    case subscription
    case about

    var id: String { rawValue }

    var label: String {
        switch self {
        case .subscription: return "Subscription"
        case .general: return "General"
        case .calendar: return "Calendar"
        case .planner: return "Planner"
        case .courses: return "Courses"
        case .semesters: return "Semesters"
        case .interface: return "Interface"
        case .profiles: return "Profile"
        case .ai: return "LLM"
        case .integrations: return "Integrations"
        case .notifications: return "Notifications"
        case .privacy: return "Privacy"
        case .storage: return "Storage"
        case .developer: return "Developer"
        case .about: return "About"
        }
    }

    var systemImageName: String {
        switch self {
        case .subscription: return "seal"
        case .general: return "gearshape"
        case .calendar: return "calendar"
        case .planner: return "pencil.and.list.clipboard"
        case .courses: return "books.vertical"
        case .semesters: return "graduationcap"
        case .interface: return "macwindow"
        case .profiles: return "person.crop.circle"
        case .ai: return "cpu.fill"
        case .integrations: return "arrow.triangle.2.circlepath.circle"
        case .notifications: return "bell.badge"
        case .privacy: return "lock.shield"
        case .storage: return "externaldrive"
        case .developer: return "hammer.fill"
        case .about: return "info.circle"
        }
    }

    var toolbarItemIdentifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("roots.settings.\(rawValue)")
    }

    var windowTitle: String {
        "Settings"
    }
}
#endif
