import SwiftUI
import AppKit

final class SettingsWindowController: NSWindowController {
    private static let lastPaneKey = "roots.settings.lastSelectedPane"
    private let appSettings: AppSettingsModel
    private let coursesStore: CoursesStore
    private let coordinator: SettingsCoordinator

    init(appSettings: AppSettingsModel, coursesStore: CoursesStore, coordinator: SettingsCoordinator) {
        self.appSettings = appSettings
        self.coursesStore = coursesStore
        self.coordinator = coordinator
        let rootView = SettingsRootView(
            initialPane: coordinator.selectedSection,
            paneChanged: { _ in }
        )
        .environmentObject(AssignmentsStore.shared)
        .environmentObject(appSettings)
        .environmentObject(coursesStore)
        .environmentObject(AppModel())
        .environmentObject(coordinator)
        .environmentObject(EventsCountStore())
        .environmentObject(CalendarManager.shared)
        .environmentObject(TimerManager())
        .environmentObject(FlashcardManager.shared)
        .environmentObject(AppPreferences())
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: RootsWindowSizing.minSettingsWidth, height: RootsWindowSizing.minSettingsHeight))
        window.minSize = NSSize(width: RootsWindowSizing.minSettingsWidth, height: RootsWindowSizing.minSettingsHeight)
        RootsWindowSizing.applyMinimumSize(to: window, role: .settings)
        window.title = "Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.collectionBehavior = [.transient]
        window.center()

        super.init(window: window)
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

    private func updateTitle(for pane: SettingsToolbarIdentifier) {
        window?.title = pane.windowTitle
    }

    private func persistPane(_ pane: SettingsToolbarIdentifier) {
        UserDefaults.standard.set(pane.rawValue, forKey: Self.lastPaneKey)
    }
}
