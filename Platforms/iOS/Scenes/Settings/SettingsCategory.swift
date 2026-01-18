#if os(iOS)
    import SwiftUI

    enum SettingsCategory: String, CaseIterable, Identifiable {
        case general
        case calendar
        case planner
        case courses
        case semesters
        case grades
        case interface
        case notifications
        case privacy
        case storage
        case developer

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general:
                NSLocalizedString("settings.category.general", comment: "General")
            case .calendar:
                NSLocalizedString("settings.category.calendar", comment: "Calendar")
            case .planner:
                NSLocalizedString("settings.category.planner", comment: "Planner")
            case .courses:
                NSLocalizedString("settings.category.courses", comment: "Courses")
            case .semesters:
                NSLocalizedString("settings.category.semesters", value: "Semesters", comment: "Semesters")
            case .grades:
                NSLocalizedString("settings.category.grades", value: "Grades", comment: "Grades")
            case .interface:
                NSLocalizedString("settings.category.interface", comment: "Interface")
            case .notifications:
                NSLocalizedString("settings.category.notifications", comment: "Notifications")
            case .privacy:
                NSLocalizedString("settings.category.privacy", comment: "Privacy")
            case .storage:
                NSLocalizedString("settings.category.storage", comment: "Storage")
            case .developer:
                NSLocalizedString("settings.category.developer", comment: "Developer")
            }
        }

        var systemImage: String {
            switch self {
            case .general: "gearshape"
            case .calendar: "calendar"
            case .planner: "pencil.and.list.clipboard"
            case .courses: "books.vertical"
            case .semesters: "graduationcap"
            case .grades: "chart.bar.doc.horizontal"
            case .interface: "sidebar.left"
            case .notifications: "bell.badge"
            case .privacy: "lock.shield"
            case .storage: "externaldrive"
            case .developer: "hammer.fill"
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
            case .grades:
                IOSGradesSettingsView()
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
