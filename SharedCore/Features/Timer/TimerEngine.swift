import Foundation
import Combine

@MainActor
final class TimerEngine: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var mode: LocalTimerMode = .pomodoro
    @Published private(set) var isRunning = false
    @Published private(set) var remainingSeconds: TimeInterval = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var pomodoroSessions = 4
    @Published private(set) var completedPomodoroSessions = 0
    @Published private(set) var isPomodorBreak = false
    @Published private(set) var activeSession: LocalTimerSession?
    
    // MARK: - Private State
    
    private var tickCancellable: AnyCancellable?
    private let settings: AppSettingsModel
    private weak var notificationManager: NotificationManager?
    
    // MARK: - Callbacks
    
    var onSessionComplete: ((LocalTimerSession) -> Void)?
    var onTimerStateChange: (() -> Void)?
    
    // MARK: - Initialization
    
    init(settings: AppSettingsModel, notificationManager: NotificationManager? = nil) {
        self.settings = settings
        self.notificationManager = notificationManager
        self.pomodoroSessions = settings.pomodoroIterations
        self.remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
    }
    

    
    // MARK: - Public API
    
    func setMode(_ newMode: LocalTimerMode) {
        guard !isRunning else { return }
        mode = newMode
        reset()
    }
    
    func start(activityID: UUID) {
        guard !isRunning else { return }
        
        isRunning = true
        
        if activeSession == nil {
            activeSession = LocalTimerSession(
                id: UUID(),
                activityID: activityID,
                mode: mode,
                startDate: Date(),
                endDate: nil,
                duration: 0,
                workSeconds: 0,
                breakSeconds: 0,
                isBreakSession: isPomodorBreak
            )
        }
        
        startTicking()
        notifyStateChange()
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        stopTicking()
        notifyStateChange()
    }
    
    func resume() {
        guard !isRunning, activeSession != nil else { return }
        isRunning = true
        startTicking()
        notifyStateChange()
    }
    
    func end() {
        pause()
        
        guard var session = activeSession else { return }
        
        let elapsed = Date().timeIntervalSince(session.startDate)
        session.endDate = Date()
        session.duration = elapsed
        
        if mode == .pomodoro {
            if session.isBreakSession {
                session.breakSeconds = elapsed
                session.workSeconds = 0
            } else {
                session.workSeconds = elapsed
                session.breakSeconds = 0
            }
        } else {
            session.workSeconds = elapsed
            session.breakSeconds = 0
        }
        
        onSessionComplete?(session)
        activeSession = nil
        reset()
    }
    
    func stop() {
        pause()
        stopTicking()
    }
    
    func reset() {
        isRunning = false
        elapsedSeconds = 0
        
        switch mode {
        case .pomodoro:
            remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
            if !isPomodorBreak {
                completedPomodoroSessions = 0
            }
        case .countdown:
            remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
        case .stopwatch:
            remainingSeconds = 0
        }
        
        stopTicking()
        notifyStateChange()
    }
    
    func updateFromSettings() {
        pomodoroSessions = settings.pomodoroIterations
        
        if !isRunning && mode == .pomodoro {
            remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
        }
    }
    
    func syncDuration(from assignment: AppTask) {
        guard !isRunning, mode == .countdown else { return }
        remainingSeconds = TimeInterval(max(1, assignment.estimatedMinutes) * 60)
        notifyStateChange()
    }
    
    // MARK: - Private Timer Logic
    
    private func startTicking() {
        stopTicking()
        
        tickCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTicking() {
        tickCancellable?.cancel()
        tickCancellable = nil
    }
    
    private func tick() {
        guard isRunning else { return }
        
        switch mode {
        case .pomodoro, .countdown:
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                handleCompletion()
            }
        case .stopwatch:
            elapsedSeconds += 1
        }
        
        notifyStateChange()
    }
    
    private func handleCompletion() {
        isRunning = false
        
        let duration: TimeInterval
        
        switch mode {
        case .stopwatch:
            duration = elapsedSeconds
            elapsedSeconds = 0
            sendNotification(mode: "Stopwatch", duration: duration)
            
        case .pomodoro:
            let workDuration = TimeInterval(settings.pomodoroFocusMinutes * 60)
            duration = workDuration
            
            if isPomodorBreak {
                completedPomodoroSessions += 1
                isPomodorBreak = false
                remainingSeconds = workDuration
                
                let longBreakCadence = settings.longBreakCadence
                let wasLongBreak = completedPomodoroSessions % longBreakCadence == 0
                sendBreakCompleteNotification(isLongBreak: wasLongBreak)
            } else {
                isPomodorBreak = true
                sendWorkCompleteNotification()
                
                let longBreakCadence = settings.longBreakCadence
                let isLongBreak = (completedPomodoroSessions + 1) % longBreakCadence == 0
                
                if isLongBreak {
                    remainingSeconds = TimeInterval(settings.pomodoroLongBreakMinutes * 60)
                } else {
                    remainingSeconds = TimeInterval(settings.pomodoroShortBreakMinutes * 60)
                }
            }
            
        case .countdown:
            let countdownDuration = TimeInterval(settings.pomodoroFocusMinutes * 60)
            duration = countdownDuration
            remainingSeconds = countdownDuration
            sendNotification(mode: "Timer", duration: duration)
        }
        
        if var session = activeSession {
            session.endDate = Date()
            session.duration = duration
            
            if mode == .pomodoro {
                if session.isBreakSession {
                    session.breakSeconds = duration
                    session.workSeconds = 0
                } else {
                    session.workSeconds = duration
                    session.breakSeconds = 0
                }
            } else {
                session.workSeconds = duration
                session.breakSeconds = 0
            }
            
            onSessionComplete?(session)
        }
        
        activeSession = nil
        notifyStateChange()
    }
    
    // MARK: - Notifications
    
    private func sendNotification(mode: String, duration: TimeInterval) {
        notificationManager?.scheduleTimerCompleted(mode: mode, duration: duration)
    }
    
    private func sendWorkCompleteNotification() {
        notificationManager?.schedulePomodoroWorkComplete()
    }
    
    private func sendBreakCompleteNotification(isLongBreak: Bool) {
        notificationManager?.schedulePomodoroBreakComplete(isLongBreak: isLongBreak)
    }
    
    private func notifyStateChange() {
        onTimerStateChange?()
    }
}
