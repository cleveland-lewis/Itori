import Foundation
import Combine

@MainActor
final class TimerCoordinator: ObservableObject {
    // MARK: - Managers
    
    let engine: TimerEngine
    let sessionManager: SessionManager
    let activityManager: ActivityManager
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    private var notificationObservers: [NSObjectProtocol] = []
    
    // MARK: - Initialization
    
    init(settings: AppSettingsModel, notificationManager: NotificationManager? = nil) {
        self.engine = TimerEngine(settings: settings, notificationManager: notificationManager)
        self.sessionManager = SessionManager()
        self.activityManager = ActivityManager()
        
        setupBindings()
    }
    

    
    // MARK: - Lifecycle
    
    func initialize() async {
        await sessionManager.load()
        await activityManager.load()
        
        setupNotificationObservers()
    }
    
    func cleanup() {
        engine.stop()
        cancellables.removeAll()
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
    }
    
    // MARK: - Timer Actions
    
    func startTimer() {
        guard let activity = activityManager.currentActivity() else { return }
        engine.start(activityID: activity.id)
    }
    
    func pauseTimer() {
        engine.pause()
    }
    
    func resumeTimer() {
        engine.resume()
    }
    
    func endTimer() {
        engine.end()
    }
    
    func resetTimer() {
        engine.reset()
    }
    
    func setMode(_ mode: LocalTimerMode) {
        engine.setMode(mode)
    }
    
    func syncWithAssignment(_ assignment: AppTask) {
        engine.syncDuration(from: assignment)
    }
    
    // MARK: - Private Setup
    
    private func setupBindings() {
        engine.onSessionComplete = { [weak self] session in
            guard let self else { return }
            
            self.sessionManager.add(session)
            self.activityManager.updateTrackedTime(for: session.activityID, workSeconds: session.workSeconds)
        }
        
        engine.onTimerStateChange = { [weak self] in
            self?.postTimerStateChangeNotification()
        }
    }
    
    private func setupNotificationObservers() {
        let startObserver = NotificationCenter.default.addObserver(
            forName: .timerStartRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startTimer()
            }
        }
        notificationObservers.append(startObserver)
        
        let stopObserver = NotificationCenter.default.addObserver(
            forName: .timerStopRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pauseTimer()
            }
        }
        notificationObservers.append(stopObserver)
        
        let endObserver = NotificationCenter.default.addObserver(
            forName: .timerEndRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.endTimer()
            }
        }
        notificationObservers.append(endObserver)
    }
    
    private func postTimerStateChangeNotification() {
        var userInfo: [String: Any] = [
            "mode": engine.mode,
            "isRunning": engine.isRunning,
            "remainingSeconds": engine.remainingSeconds,
            "elapsedSeconds": engine.elapsedSeconds,
            "pomodoroSessions": engine.pomodoroSessions,
            "completedPomodoroSessions": engine.completedPomodoroSessions,
            "isPomodorBreak": engine.isPomodorBreak,
            "activities": activityManager.activities,
            "sessions": sessionManager.sessions
        ]
        
        if let activityID = activityManager.selectedActivityID {
            userInfo["selectedActivityID"] = activityID
        }
        
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil, userInfo: userInfo)
    }
}
