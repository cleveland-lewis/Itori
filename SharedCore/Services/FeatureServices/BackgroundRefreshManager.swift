import Foundation
#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    private let refreshIdentifier = "com.itori.background.refresh"
    private var didRegister = false

    private init() {}

    func register() {
        #if canImport(BackgroundTasks) && os(iOS)
            guard !TestMode.isRunningTests else { return }
            guard !didRegister else { return }
            didRegister = true
            BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshIdentifier, using: nil) { task in
                self.scheduleNext()
                self.handleRefresh(task: task)
            }
        #endif
    }

    func scheduleNext() {
        #if canImport(BackgroundTasks) && os(iOS)
            if !didRegister {
                register()
            }
            guard didRegister else {
                return
            }
            let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                DebugLogger.log("⚠️ Background refresh schedule failed: \(error.localizedDescription)")
            }
        #endif
    }

    private func handleRefresh(task: Any) {
        #if canImport(BackgroundTasks) && os(iOS)
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            refreshTask.expirationHandler = {
                NotificationManager.shared.scheduleBackgroundRefreshNotification(
                    status: .failed(reason: "Refresh timed out.")
                )
            }

            Task {
                NotificationManager.shared.scheduleBackgroundRefreshNotification(status: .started)
                let error = await CalendarRefreshCoordinator.shared.runRefresh()
                PlannerSyncCoordinator.shared.requestRecompute(
                    assignmentsStore: .shared,
                    plannerStore: .shared,
                    settings: .shared
                )
                if let error {
                    NotificationManager.shared.scheduleBackgroundRefreshNotification(
                        status: .failed(reason: error.errorDescription ?? "Refresh failed.")
                    )
                    refreshTask.setTaskCompleted(success: false)
                } else {
                    NotificationManager.shared.scheduleBackgroundRefreshNotification(status: .completed)
                    refreshTask.setTaskCompleted(success: true)
                }
            }
        #endif
    }
}
