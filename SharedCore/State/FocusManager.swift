import Combine
import Foundation

@MainActor
final class FocusManager: ObservableObject {
    @Published var mode: LocalTimerMode = .pomodoro
    @Published var activities: [LocalTimerActivity] = []
    @Published var selectedActivityID: UUID? = nil

    @Published var isRunning: Bool = false
    @Published var remainingSeconds: TimeInterval = 25 * 60
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var pomodoroSessions: Int = 4
    @Published var completedPomodoroSessions: Int = 0
    @Published var isPomodorBreak: Bool = false
    @Published var activeSession: LocalTimerSession? = nil
    @Published var sessions: [LocalTimerSession] = []

    private var timerCancellable: AnyCancellable?
    @Published var settings: AppSettingsModel
    private let audioService = AudioFeedbackService.shared

    init() {
        self.settings = AppSettingsModel.shared
        pomodoroSessions = settings.pomodoroIterations
    }

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        // Session tracking disabled pending migration to new FocusSession API

        // Play haptic feedback only
        Feedback.shared.timerStart()
    }

    func pauseTimer() {
        isRunning = false

        // Play haptic feedback only
        Feedback.shared.timerStop()
    }

    func resetTimer() {
        isRunning = false
        elapsedSeconds = 0
        remainingSeconds = 25 * 60
        completedPomodoroSessions = 0
        isPomodorBreak = false
    }

    func endTimerSession() {
        isRunning = false

        // Play haptic feedback only
        Feedback.shared.timerStop()

        // Session tracking disabled pending migration to new FocusSession API
        activeSession = nil
        resetTimer()
    }

    func tick() {
        guard isRunning else { return }

        switch mode {
        case .pomodoro, .timer, .focus:
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                completeCurrentBlock()
            }
        case .stopwatch:
            elapsedSeconds += 1
        }
    }

    func completeCurrentBlock() {
        isRunning = false
        let duration: TimeInterval
        switch mode {
        case .stopwatch:
            duration = elapsedSeconds
            elapsedSeconds = 0
        case .pomodoro:
            duration = 25 * 60 - remainingSeconds

            if isPomodorBreak {
                completedPomodoroSessions += 1
                isPomodorBreak = false
                remainingSeconds = 25 * 60
            } else {
                isPomodorBreak = true

                let longBreakCadence = settings.longBreakCadence
                let isLongBreak = (completedPomodoroSessions + 1) % longBreakCadence == 0

                if isLongBreak {
                    remainingSeconds = TimeInterval(settings.pomodoroLongBreakMinutes * 60)
                } else {
                    remainingSeconds = TimeInterval(settings.pomodoroShortBreakMinutes * 60)
                }
            }
        case .timer, .focus:
            duration = 25 * 60 - remainingSeconds
            remainingSeconds = 25 * 60
        }

        // Session tracking disabled pending migration to new FocusSession API
        activeSession = nil
    }

    private func logSession(_: LocalTimerSession) {
        // Track session completion
        // Note: Session tracking is handled by FocusSession state
    }
}
