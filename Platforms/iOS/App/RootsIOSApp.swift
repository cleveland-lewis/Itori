//
//  RootsIOSApp.swift
//  Roots (iOS)
//

#if os(iOS)
import SwiftUI
import BackgroundTasks

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
        
        // Register background tasks
        RootsIOSApp.registerBackgroundTasks()
        
        // Initialize Intelligent Scheduling System (Always On)
        Task { @MainActor in
            IntelligentSchedulingCoordinator.shared.start()
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
                        
                        // Schedule background task for intelligent scheduling
                        Task {
                            await scheduleIntelligentSchedulingBackgroundTask()
                        }
                    } else if phase == .active {
                        // Check for overdue tasks when app becomes active
                        Task {
                            await IntelligentSchedulingCoordinator.shared.checkOverdueTasks()
                        }
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
    
    // MARK: - Background Task Scheduling
    
    private func scheduleIntelligentSchedulingBackgroundTask() async {
        let identifier = "com.clevelandlewis.Itori.intelligentScheduling"
        
        // Cancel any existing tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        
        // Schedule new background task
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            LOG_UI(.info, "Background", "Scheduled intelligent scheduling background task")
        } catch {
            LOG_UI(.error, "Background", "Failed to schedule background task: \(error)")
        }
    }
}

// MARK: - Background Task Registration

extension RootsIOSApp {
    static func registerBackgroundTasks() {
        let identifier = "com.clevelandlewis.Itori.intelligentScheduling"
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await handleIntelligentSchedulingBackgroundTask(task: task as! BGAppRefreshTask)
            }
        }
    }
    
    static func handleIntelligentSchedulingBackgroundTask(task: BGAppRefreshTask) async {
        LOG_UI(.info, "Background", "Running intelligent scheduling background task")
        
        // Schedule next background task
        await RootsIOSApp().scheduleIntelligentSchedulingBackgroundTask()
        
        // Perform intelligent scheduling work
        await IntelligentSchedulingCoordinator.shared.checkOverdueTasks()
        
        // Mark task as complete
        task.setTaskCompleted(success: true)
    }
}
#endif
