#if os(macOS)
import SwiftUI
import AppKit
import Combine

// MARK: - System Settings Style View

struct SystemStyleSettingsView: View {
    @State private var selectedCategory: SettingsToolbarIdentifier = .general
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    
    var body: some View {
        NavigationSplitView(sidebar: {
            settingsSidebar
        }, detail: {
            settingsDetail
        })
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, idealWidth: 900, minHeight: 600, idealHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var settingsSidebar: some View {
        List(selection: $selectedCategory) {
            ForEach(SettingsToolbarIdentifier.allCases) { category in
                NavigationLink(value: category) {
                    Label {
                        Text(category.label)
                            .font(.body)
                    } icon: {
                        Image(systemName: category.systemImageName)
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 20)
                    }
                }
                .tag(category)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Settings")
        .frame(minWidth: 200, idealWidth: 220)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var settingsDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: selectedCategory.systemImageName)
                    .foregroundStyle(.secondary)
                Text(selectedCategory.label)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                contentForCategory(selectedCategory)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    @ViewBuilder
    private func contentForCategory(_ category: SettingsToolbarIdentifier) -> some View {
        switch category {
        case .general: GeneralSettingsView()
        case .calendar: CalendarSettingsView()
        case .reminders: RemindersSettingsView()
        case .planner: PlannerSettingsView()
        case .courses: CoursesSettingsView()
        case .semesters: SemestersSettingsView()
        case .interface: InterfaceSettingsView()
        case .profiles: ProfilesSettingsView()
        case .timer: TimerSettingsView()
        case .flashcards: FlashcardSettingsView()
        case .integrations: IntegrationsSettingsView()
        case .notifications: NotificationsSettingsView()
        case .privacy: PrivacySettingsView()
        case .storage: StorageSettingsView()
        case .developer: DeveloperSettingsView()
        }
    }
}

// MARK: - Settings Window Controller

final class SettingsWindowController: NSWindowController {
    static let lastPaneKey = "roots.settings.lastSelectedPane"
    private let appSettings: AppSettingsModel
    private let coursesStore: CoursesStore
    private let coordinator: SettingsCoordinator
    private var selectionCancellable: AnyCancellable?

    init(appSettings: AppSettingsModel, coursesStore: CoursesStore, coordinator: SettingsCoordinator) {
        // Assign stored properties first
        self.appSettings = appSettings
        self.coursesStore = coursesStore
        self.coordinator = coordinator

        // Capture initial values without touching self
        let initialPane = coordinator.selectedSection

        // Build binding and views without referencing self
        let selectionBinding = Binding<SettingsToolbarIdentifier>(
            get: { coordinator.selectedSection },
            set: { newValue in
                guard coordinator.selectedSection != newValue else { return }
                DispatchQueue.main.async {
                    coordinator.selectedSection = newValue
                }
            }
        )

        let hostingController = NSHostingController(rootView: SettingsWindowController.makeRootView(
            selection: selectionBinding,
            appSettings: appSettings,
            coursesStore: coursesStore,
            coordinator: coordinator
        ))
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 700))
        window.minSize = NSSize(width: 800, height: 600)
        window.title = "Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.transient]
        window.center()

        // Call super before any use of self
        super.init(window: window)

        // Set up selection sink observing coordinator
        selectionCancellable = coordinator.$selectedSection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pane in
                guard let self else { return }
                self.persistPane(pane)
            }
    }

    private static func makeRootView(
        selection: Binding<SettingsToolbarIdentifier>,
        appSettings: AppSettingsModel,
        coursesStore: CoursesStore,
        coordinator: SettingsCoordinator
    ) -> AnyView {
        AnyView(
            SystemStyleSettingsView()
                .environmentObject(AssignmentsStore.shared)
                .environmentObject(appSettings)
                .environmentObject(coursesStore)
                .environmentObject(GradesStore.shared)
                .environmentObject(PlannerStore.shared)
                .environmentObject(AppModel.shared)
                .environmentObject(coordinator)
                .environmentObject(EventsCountStore())
                .environmentObject(CalendarManager.shared)
                .environmentObject(TimerManager())
                .environmentObject(FlashcardManager.shared)
                .environmentObject(AppPreferences())
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSettings() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func persistPane(_ pane: SettingsToolbarIdentifier) {
        UserDefaults.standard.set(pane.rawValue, forKey: Self.lastPaneKey)
    }
}
#endif
