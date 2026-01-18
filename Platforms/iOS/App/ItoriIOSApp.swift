//
//  ItoriIOSApp.swift
//  Itori (iOS)
//

#if os(iOS)
    import BackgroundTasks
    import SwiftUI

    @main
    struct ItoriIOSApp: App {
        @StateObject private var coursesStore: CoursesStore
        @StateObject private var settingsCoordinator: SettingsCoordinator
        @StateObject private var sheetRouter = IOSSheetRouter()
        @StateObject private var toastRouter = IOSToastRouter()
        @StateObject private var filterState = IOSFilterState()
        @StateObject private var timerManager = TimerManager()
        @StateObject private var focusManager = FocusManager()
        @StateObject private var preferences = AppPreferences()
        @StateObject private var eventsCountStore = EventsCountStore()
        @StateObject private var watchConnectivity = WatchConnectivityManager.shared
        @Environment(\.scenePhase) private var scenePhase

        init() {
            // OPTIMIZATION: Only essential initialization - defer everything else
            let store = CoursesStore()
            _coursesStore = StateObject(wrappedValue: store)
            let settings = AppSettingsModel.shared
            _settingsCoordinator = StateObject(wrappedValue: SettingsCoordinator(
                appSettings: settings,
                coursesStore: store
            ))
            if UserDefaults.standard.data(forKey: "itori.settings.appsettings") == nil {
                settings.visibleTabs = TabRegistry.defaultEnabledTabs
                settings.tabOrder = TabRegistry.allTabs.map(\.id)
                settings.save()
            }
        }

        var body: some Scene {
            WindowGroup {
                IOSRootView()
                    .environmentObject(AssignmentsStore.shared)
                    .environmentObject(coursesStore)
                    .environmentObject(AppSettingsModel.shared)
                    .environmentObject(AppModel.shared)
                    .environmentObject(settingsCoordinator)
                    .environmentObject(eventsCountStore)
                    .environmentObject(CalendarManager.shared)
                    .environmentObject(DeviceCalendarManager.shared)
                    .environmentObject(timerManager)
                    .environmentObject(focusManager)
                    .environmentObject(FlashcardManager.shared)
                    .environmentObject(preferences)
                    .environmentObject(GradesStore.shared)
                    .environmentObject(PlannerStore.shared)
                    .environmentObject(PlannerCoordinator.shared)
                    .environmentObject(AssignmentPlansStore.shared)
                    .environmentObject(SyllabusParsingStore.shared)
                    .environmentObject(CalendarRefreshCoordinator.shared)
                    .environmentObject(sheetRouter)
                    .environmentObject(toastRouter)
                    .environmentObject(filterState)
                    .environmentObject(IntelligentSchedulingCoordinator.shared)
                    .tint(AppSettingsModel.shared.activeAccentColor)
                    .task {
                        // OPTIMIZATION: Defer non-essential initialization until after first frame
                        await initializeBackgroundServices()
                    }
                    .onAppear {
                        let appSettings = AppSettingsModel.shared
                        preferences.highContrast = appSettings.highContrastMode
                        preferences.reduceTransparency = appSettings.increaseTransparency || !appSettings
                            .enableGlassEffects
                        preferences.glassIntensity = appSettings.glassIntensity
                        preferences.reduceMotion = appSettings.reduceMotion

                        // Initialize watch connectivity with timer manager
                        watchConnectivity.setTimerManager(timerManager)
                        _ = IOSTimerLiveActivityCoordinator.shared

                        // PHASE 3: Start prewarming hot views after idle
                        Task {
                            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
                            PrewarmCoordinator.shared.startPrewarming(
                                coursesStore: coursesStore,
                                assignmentsStore: .shared
                            )
                        }
                    }
                    .onChange(of: scenePhase) { _, phase in
                        if phase == .background {
                            BackgroundRefreshManager.shared.scheduleNext()

                            // PHASE 3: Cancel prewarming when app goes to background
                            PrewarmCoordinator.shared.cancelPrewarming()

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
                    .onChange(of: AppSettingsModel.shared.highContrastMode) { _, newValue in
                        preferences.highContrast = newValue
                    }
                    .onChange(of: AppSettingsModel.shared.increaseTransparency) { _, newValue in
                        preferences.reduceTransparency = newValue || !AppSettingsModel.shared.enableGlassEffects
                    }
                    .onChange(of: AppSettingsModel.shared.enableGlassEffects) { _, newValue in
                        preferences.reduceTransparency = AppSettingsModel.shared.increaseTransparency || !newValue
                    }
                    .onChange(of: AppSettingsModel.shared.glassIntensity) { _, newValue in
                        preferences.glassIntensity = newValue
                    }
                    .onChange(of: AppSettingsModel.shared.reduceMotion) { _, newValue in
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
                    .environmentObject(PlannerStore.shared)
            }
            WindowGroup(id: WindowIdentifier.timerSession.rawValue) {
                IOSTimerPageView()
                    .environmentObject(AppSettingsModel.shared)
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

        // OPTIMIZATION: Initialize background services after first frame renders
        // PHASE 2: Tiered initialization - core services first, then delayed services
        @MainActor
        private func initializeBackgroundServices() async {
            LOG_LIFECYCLE(.info, "BackgroundInit", "Starting tiered background service initialization")

            // TIER 1: Core services needed for basic interaction (start immediately)
            await withTaskGroup(of: Void.self) { group in
                // Reset coordinator (affects app state)
                group.addTask {
                    await ResetCoordinator.shared.start(appModel: AppModel.shared)
                    LOG_LIFECYCLE(.debug, "Tier1", "ResetCoordinator initialized")
                }

                // Background tasks registration
                group.addTask {
                    ItoriIOSApp.registerBackgroundTasks()
                    LOG_LIFECYCLE(.debug, "Tier1", "BackgroundTasks registered")
                }
            }

            LOG_LIFECYCLE(.info, "BackgroundInit", "Tier 1 services initialized")

            // PHASE 2: Wait for initial data load OR 1 second delay
            let dataLoadWaitTask = Task {
                for _ in 0 ..< 20 { // Check up to 2 seconds
                    if CoursesStore.shared?.isInitialLoadComplete == true {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                }
            }
            await dataLoadWaitTask.value

            // Additional small delay to ensure UI is stable
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

            LOG_LIFECYCLE(.info, "BackgroundInit", "Starting Tier 2 services")

            // TIER 2: All other services (defer to avoid blocking interaction)
            await withTaskGroup(of: Void.self) { group in
                // PhoneWatch communication
                group.addTask {
                    _ = PhoneWatchBridge.shared
                    LOG_LIFECYCLE(.debug, "Tier2", "PhoneWatchBridge initialized")
                }

                // Planner sync
                group.addTask {
                    await PlannerSyncCoordinator.shared.start(
                        assignmentsStore: .shared,
                        plannerStore: .shared,
                        settings: .shared
                    )
                    LOG_LIFECYCLE(.debug, "Tier2", "PlannerSync initialized")
                }

                // Missed event detection
                group.addTask {
                    await MissedEventDetectionService.shared.startMonitoring()
                    LOG_LIFECYCLE(.debug, "Tier2", "MissedEventDetection initialized")
                }

                // Background refresh
                group.addTask {
                    BackgroundRefreshManager.shared.register()
                    BackgroundRefreshManager.shared.scheduleNext()
                    LOG_LIFECYCLE(.debug, "Tier2", "BackgroundRefresh initialized")
                }

                // Intelligent scheduling
                group.addTask {
                    await IntelligentSchedulingCoordinator.shared.start()
                    LOG_LIFECYCLE(.debug, "Tier2", "IntelligentScheduling initialized")
                }
            }

            LOG_LIFECYCLE(.info, "BackgroundInit", "All background services initialized (tiered)")
        }
    }

    // MARK: - Background Task Registration

    extension ItoriIOSApp {
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
            await ItoriIOSApp().scheduleIntelligentSchedulingBackgroundTask()

            // Perform intelligent scheduling work
            await IntelligentSchedulingCoordinator.shared.checkOverdueTasks()

            // Mark task as complete
            task.setTaskCompleted(success: true)
        }
    }
#endif
