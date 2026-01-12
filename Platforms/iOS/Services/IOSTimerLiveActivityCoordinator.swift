import Foundation

#if os(iOS)
    @MainActor
    final class IOSTimerLiveActivityCoordinator {
        static let shared = IOSTimerLiveActivityCoordinator()

        private let viewModel: TimerPageViewModel
        private let liveActivityManager = IOSTimerLiveActivityManager()
        private var observer: NSObjectProtocol?

        private init() {
            self.viewModel = TimerPageViewModel.shared
            observer = NotificationCenter.default.addObserver(
                forName: .timerSessionDidUpdate,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.syncLiveActivity()
                }
            }
            syncLiveActivity()
        }

        private func syncLiveActivity() {
            liveActivityManager.sync(
                currentMode: viewModel.currentMode,
                session: viewModel.currentSession,
                elapsed: viewModel.sessionElapsed,
                remaining: viewModel.sessionRemaining,
                isOnBreak: viewModel.isOnBreak,
                activities: viewModel.activities,
                pomodoroCompletedCycles: viewModel.pomodoroCompletedCycles,
                pomodoroMaxCycles: viewModel.pomodoroMaxCycles
            )
        }
    }
#endif
