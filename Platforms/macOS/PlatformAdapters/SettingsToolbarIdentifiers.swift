#if os(macOS)
    import AppKit

    enum SettingsToolbarIdentifier: String, CaseIterable, Identifiable {
        case general
        case calendar
        case planner
        case timer
        case courses
        case semesters
        case grades
        case interface
        case ai
        case notifications
        case privacy
        case storage
        case developer
        case license // Changed from subscription
        // case subscription // Commented out for future AI subscription
        case about

        var id: String { rawValue }

        var label: String {
            switch self {
            case .license: "License" // Changed from Subscription
            // case .subscription: "Subscription" // Commented out
            case .general: "General"
            case .calendar: "Calendar"
            case .planner: "Planner"
            case .timer: "Timer"
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
            case .license: "checkmark.seal.fill" // Changed from seal
            // case .subscription: "seal" // Commented out
            case .general: "gearshape"
            case .calendar: "calendar"
            case .planner: "pencil.and.list.clipboard"
            case .timer: "timer"
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
