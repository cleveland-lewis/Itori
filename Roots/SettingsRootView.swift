import SwiftUI
import Combine

// MARK: - Settings Category Enum

enum SettingsCategory: String, CaseIterable, Identifiable {
    case general = "General"
    case calendar = "Calendar"
    case reminders = "Reminders"
    case planner = "Planner"
    case courses = "Courses"
    case semesters = "Semesters"
    case interface = "Interface"
    case profiles = "Profiles"
    case account = "Account"
    case privacy = "Privacy & Security"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .calendar: return "calendar"
        case .reminders: return "list.bullet"
        case .planner: return "pencil.and.list.clipboard"
        case .courses: return "book.closed"
        case .semesters: return "calendar"
        case .interface: return "macwindow"
        case .profiles: return "person.crop.circle"
        case .account: return "person.text.rectangle"
        case .privacy: return "lock.shield"
        }
    }
}

// MARK: - Settings Root View

struct SettingsRootView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    @State private var selectedCategory: SettingsCategory = .general

    // Legacy initializer for compatibility with SettingsWindowController
    init(initialPane: SettingsToolbarIdentifier, paneChanged: @escaping (SettingsToolbarIdentifier) -> Void) {
        // We ignore these parameters since we're using a new NavigationSplitView-based approach
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsCategory.allCases, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            Group {
                switch selectedCategory {
                case .general:
                    GeneralSettingsView()
                case .calendar:
                    CalendarSettingsView()
                case .reminders:
                    RemindersSettingsView()
                case .planner:
                    PlannerSettingsView()
                case .courses:
                    CoursesSettingsView()
                case .semesters:
                    SemestersSettingsView()
                case .interface:
                    InterfaceSettingsView()
                case .profiles:
                    ProfilesSettingsView()
                case .account:
                    Text("Account settings are unavailable in this build.")
                case .privacy:
                    PrivacySettingsView()
                }
            }
            .frame(minWidth: 400, minHeight: 400)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(settings.objectWillChange) { _ in
            // Persist settings whenever they change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                settings.save()
            }
        }
    }
}
