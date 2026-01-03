//
//  RootsIOSApp.swift
//  Roots (iOS)
//

#if os(iOS)
import SwiftUI

@main
struct RootsIOSApp: App {
    @StateObject private var coursesStore: CoursesStore
    @StateObject private var appSettings = AppSettingsModel.shared
    @StateObject private var settingsCoordinator: SettingsCoordinator
    @StateObject private var gradesStore = GradesStore.shared
    @StateObject private var plannerStore = PlannerStore.shared
    @StateObject private var plannerCoordinator = PlannerCoordinator.shared
    @StateObject private var assignmentPlansStore = AssignmentPlansStore.shared
    @StateObject private var sheetRouter = IOSSheetRouter()
    @StateObject private var toastRouter = IOSToastRouter()
    @StateObject private var filterState = IOSFilterState()
    @StateObject private var appModel = AppModel.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var deviceCalendar = DeviceCalendarManager.shared
    @StateObject private var calendarRefresh = CalendarRefreshCoordinator.shared
    @StateObject private var timerManager = TimerManager()
    @StateObject private var focusManager = FocusManager()
    @StateObject private var preferences = AppPreferences()
    @StateObject private var parsingStore = SyllabusParsingStore.shared
    @StateObject private var eventsCountStore = EventsCountStore()
    @StateObject private var schedulingCoordinator = IntelligentSchedulingCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = PhoneWatchBridge.shared
        ResetCoordinator.shared.start(appModel: AppModel.shared)
        let store = CoursesStore()
        _coursesStore = StateObject(wrappedValue: store)
        let settings = AppSettingsModel.shared
        _settingsCoordinator = StateObject(wrappedValue: SettingsCoordinator(appSettings: settings, coursesStore: store))
        if UserDefaults.standard.data(forKey: "roots.settings.appsettings") == nil {
            settings.visibleTabs = TabRegistry.defaultEnabledTabs
            settings.tabOrder = TabRegistry.allTabs.map { $0.id }
            settings.save()
        }
        
        // Initialize Intelligent Scheduling System
        Task { @MainActor in
            if settings.enableIntelligentScheduling {
                IntelligentSchedulingCoordinator.shared.start()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environmentObject(AssignmentsStore.shared)
                .environmentObject(coursesStore)
                .environmentObject(appSettings)
                .environmentObject(appModel)
                .environmentObject(settingsCoordinator)
                .environmentObject(eventsCountStore)
                .environmentObject(calendarManager)
                .environmentObject(DeviceCalendarManager.shared)
                .environmentObject(timerManager)
                .environmentObject(focusManager)
                .environmentObject(FlashcardManager.shared)
                .environmentObject(preferences)
                .environmentObject(gradesStore)
                .environmentObject(plannerStore)
                .environmentObject(plannerCoordinator)
                .environmentObject(assignmentPlansStore)
                .environmentObject(parsingStore)
                .environmentObject(calendarRefresh)
                .environmentObject(sheetRouter)
                .environmentObject(toastRouter)
                .environmentObject(filterState)
                .environmentObject(schedulingCoordinator)
                .onAppear {
                    preferences.highContrast = appSettings.highContrastMode
                    preferences.reduceTransparency = appSettings.increaseTransparency || !appSettings.enableGlassEffects
                    preferences.glassIntensity = appSettings.glassIntensity
                    preferences.reduceMotion = appSettings.reduceMotion
                    PlannerSyncCoordinator.shared.start(
                        assignmentsStore: .shared,
                        plannerStore: .shared,
                        settings: .shared
                    )
                    
                    // Start auto-reschedule monitoring
                    MissedEventDetectionService.shared.startMonitoring()

                    BackgroundRefreshManager.shared.register()
                    BackgroundRefreshManager.shared.scheduleNext()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        BackgroundRefreshManager.shared.scheduleNext()
                    }
                }
                .onChange(of: appSettings.highContrastMode) { _, newValue in
                    preferences.highContrast = newValue
                }
                .onChange(of: appSettings.increaseTransparency) { _, newValue in
                    preferences.reduceTransparency = newValue || !appSettings.enableGlassEffects
                }
                .onChange(of: appSettings.enableGlassEffects) { _, newValue in
                    preferences.reduceTransparency = appSettings.increaseTransparency || !newValue
                }
                .onChange(of: appSettings.glassIntensity) { _, newValue in
                    preferences.glassIntensity = newValue
                }
                .onChange(of: appSettings.reduceMotion) { _, newValue in
                    preferences.reduceMotion = newValue
                    AnimationPolicy.shared.updateFromAppSettings()
                }
        }
        WindowGroup(id: WindowIdentifier.assignmentDetail.rawValue) {
            AssignmentSceneContent()
                .environmentObject(AssignmentsStore.shared)
                .environmentObject(coursesStore)
        }
        WindowGroup(id: WindowIdentifier.courseDetail.rawValue) {
            CourseSceneContent()
                .environmentObject(AssignmentsStore.shared)
                .environmentObject(coursesStore)
        }
        WindowGroup(id: WindowIdentifier.plannerDay.rawValue) {
            PlannerSceneContent()
                .environmentObject(plannerStore)
        }
        WindowGroup(id: WindowIdentifier.timerSession.rawValue) {
            IOSTimerPageView()
                .environmentObject(appSettings)
        }
    }
}
#endif
