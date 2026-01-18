#if os(macOS)
    import AppKit

    enum SettingsToolbarIdentifier: String, CaseIterable, Identifiable {
        case general
        case calendar
        case planner
        case courses
        case semesters
        case grades
        case interface
        case ai
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
            case .grades: "Grades"
            case .interface: "Interface"
            case .ai: "LLM"
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
            case .grades: "chart.bar.doc.horizontal"
            case .interface: "macwindow"
            case .ai: "cpu.fill"
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
