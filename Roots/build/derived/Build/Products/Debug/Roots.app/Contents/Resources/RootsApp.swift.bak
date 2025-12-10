//
//  RootsApp.swift
//  Roots
//
//  Created by Cleveland Lewis III on 11/30/25.
//

import SwiftUI
import _Concurrency
import SwiftData
import Combine

@main
struct RootsApp: App {

    @StateObject private var coursesStore: CoursesStore
    @StateObject private var appSettings = AppSettingsModel.shared
    @StateObject private var settingsCoordinator: SettingsCoordinator
    @StateObject private var appModel = AppModel()
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var timerManager = TimerManager()
    @StateObject private var preferences = AppPreferences()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = CoursesStore()
        _coursesStore = StateObject(wrappedValue: store)
        _settingsCoordinator = StateObject(wrappedValue: SettingsCoordinator(appSettings: AppSettingsModel.shared, coursesStore: store))
        _ = DeveloperSettingsSynchronizer.shared
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AssignmentsStore.shared)
                
                .environmentObject(coursesStore)
                .environmentObject(appSettings)
                .environmentObject(appModel)
                .environmentObject(settingsCoordinator)
                .environmentObject(EventsCountStore())
                .environmentObject(calendarManager)
                .environmentObject(timerManager)
                .environmentObject(FlashcardManager.shared)
                .environmentObject(preferences)
                .onAppear {
                    // Sync stored AppSettingsModel -> AppPreferences on launch
                    preferences.highContrast = appSettings.highContrastMode
                    preferences.reduceTransparency = appSettings.increaseTransparency
                    if let g = appSettings.glassIntensity { preferences.glassIntensity = g }
                }
                .onChange(of: preferences.highContrast) { _, newValue in
                    appSettings.highContrastMode = newValue
                    appSettings.save()
                }
                .onChange(of: preferences.reduceTransparency) { _, newValue in
                    appSettings.increaseTransparency = newValue
                    appSettings.save()
                }
                // Reverse sync: when saved AppSettingsModel values change (from other settings UI), update AppPreferences
                .onReceive(appSettings.objectWillChange) { _ in
                    preferences.highContrast = appSettings.highContrastMode
                    preferences.reduceTransparency = appSettings.increaseTransparency
                    if let g = appSettings.glassIntensity { preferences.glassIntensity = g }
                }
                .accentColor(preferences.currentAccentColor)
                .buttonStyle(.glassBlueProminent)
                .controlSize(.regular)
                .buttonBorderShape(.automatic)
                .tint(preferences.currentAccentColor)
                .frame(minWidth: RootsWindowSizing.minMainWidth, minHeight: RootsWindowSizing.minMainHeight)
                .task {
                    // Run adaptation on launch
                    SchedulerAdaptationManager.shared.runAdaptiveSchedulerUpdateIfNeeded()
                    // Refresh and request permissions on launch
                    await calendarManager.checkPermissionsOnStartup()
                    timerManager.checkNotificationPermissions()
                }
        }
        Settings {
            SettingsRootView(initialPane: settingsCoordinator.selectedSection, paneChanged: { _ in })
                .environmentObject(AssignmentsStore.shared)
                .environmentObject(coursesStore)
                .environmentObject(appSettings)
                .environmentObject(appModel)
                .environmentObject(settingsCoordinator)
                .environmentObject(EventsCountStore())
                .environmentObject(calendarManager)
                .environmentObject(timerManager)
                .environmentObject(FlashcardManager.shared)
                .environmentObject(preferences)
        }
        .onChange(of: scenePhase, perform: handleScenePhaseChange)
        .commands {
            AppCommands()
            SettingsCommands(showSettings: {
                settingsCoordinator.show()
            })
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase == .background || phase == .inactive {
            appSettings.save()
        } else if phase == .active {
            _Concurrency.Task {
                await calendarManager.checkPermissionsOnStartup()
            }
        }
    }
}
