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
            case .subscription: "Subscription"
            case .general: "General"
            case .calendar: "Calendar"
            case .planner: "Planner"
            case .courses: "Courses"
            case .semesters: "Semesters"
            case .interface: "Interface"
            case .profiles: "Profile"
            case .ai: "LLM"
            case .integrations: "Integrations"
            case .notifications: "Notifications"
            case .privacy: "Privacy"
            case .storage: "Storage"
            case .developer: "Developer"
            case .about: "About"
            }
        }

        var systemImageName: String {
            switch self {
            case .subscription: "seal"
            case .general: "gearshape"
            case .calendar: "calendar"
            case .planner: "pencil.and.list.clipboard"
            case .courses: "books.vertical"
            case .semesters: "graduationcap"
            case .interface: "macwindow"
            case .profiles: "person.crop.circle"
            case .ai: "cpu.fill"
            case .integrations: "arrow.triangle.2.circlepath.circle"
            case .notifications: "bell.badge"
            case .privacy: "lock.shield"
            case .storage: "externaldrive"
            case .developer: "hammer.fill"
            case .about: "info.circle"
            }
        }

        var toolbarItemIdentifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier("itori.settings.\(rawValue)")
        }

        var windowTitle: String {
            "Settings"
        }
    }
#endif
