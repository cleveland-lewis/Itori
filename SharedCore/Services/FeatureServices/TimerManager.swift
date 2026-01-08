import Foundation
import Combine
import UserNotifications

final class TimerManager: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()

    // Timer state
    private var timer: Timer?
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var secondsRemaining: Int = 25 * 60

    func start() {
        guard !isRunning else { return }
        LOG_TIMER(.info, "TimerStart", "Timer starting with \(secondsRemaining)s")
        isRunning = true
        isPaused = false
        
        // Play timer start feedback
        Task { @MainActor in
            Feedback.shared.timerStart()
        }
        
        // Throttled to 1s
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let strongSelf = self else { return }
            _Concurrency.Task { @MainActor in
                strongSelf.tick()
            }
        }
        if let t = timer {
            RunLoop.current.add(t, forMode: .common)
        }
    }

    func stop() {
        LOG_TIMER(.info, "TimerStop", "Timer stopped with \(secondsRemaining)s remaining")
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        // Play timer stop feedback
        Task { @MainActor in
            Feedback.shared.timerStop()
        }
    }
    
    func togglePause() {
        guard isRunning else { return }
        
        isPaused.toggle()
        
        if isPaused {
            LOG_TIMER(.info, "TimerPause", "Timer paused")
            timer?.invalidate()
            timer = nil
            
            Task { @MainActor in
                Feedback.shared.timerStop() // Use stop feedback for pause
            }
        } else {
            LOG_TIMER(.info, "TimerResume", "Timer resumed")
            
            // Restart the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let strongSelf = self else { return }
                _Concurrency.Task { @MainActor in
                    strongSelf.tick()
                }
            }
            if let t = timer {
                RunLoop.current.add(t, forMode: .common)
            }
            
            Task { @MainActor in
                Feedback.shared.timerStart()
            }
        }
    }

    private func tick() {
        guard secondsRemaining > 0 else {
            LOG_TIMER(.info, "TimerComplete", "Timer completed")
            stop()
            // Notify finished
            return
        }
        secondsRemaining -= 1
    }

    /// Check notification permissions status (does not request)
    /// Call this on launch to populate permission state
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            LOG_NOTIFICATIONS(.debug, "Permissions", "Notification auth status: \(settings.authorizationStatus.rawValue)")
            if settings.authorizationStatus == .denied {
                LOG_NOTIFICATIONS(.debug, "Permissions", "Notification permissions denied by user")
            } else if settings.authorizationStatus == .notDetermined {
                LOG_NOTIFICATIONS(.debug, "Permissions", "Notification permissions not yet requested")
            }
            // Don't auto-request - let user trigger from Settings or timer start
        }
    }
    
    /// Request notification permission (called explicitly by user action)
    func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization()
    }
}
