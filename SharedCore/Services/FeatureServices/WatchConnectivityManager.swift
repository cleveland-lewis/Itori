import Combine
import Foundation

struct TimerState: Codable {
    let isRunning: Bool
    let isPaused: Bool
    let remainingSeconds: TimeInterval
    let totalSeconds: TimeInterval
    let activityName: String?
}

#if !os(watchOS) && canImport(WatchConnectivity)
    import WatchConnectivity

    /// Manages synchronization with Apple Watch
    @MainActor
    final class WatchConnectivityManager: NSObject, ObservableObject {
        static let shared = WatchConnectivityManager()

        @Published var isWatchAppInstalled: Bool = false
        @Published var isWatchReachable: Bool = false

        private var session: WCSession?
        private var timerManager: TimerManager?
        private var cancellables = Set<AnyCancellable>()

        override private init() {
            super.init()
            setupWatchConnectivity()
        }

        // MARK: - Setup

        private func setupWatchConnectivity() {
            guard WCSession.isSupported() else {
                LOG_TIMER(.debug, "WatchSync", "WCSession not supported on this device")
                return
            }

            session = WCSession.default
            session?.delegate = self
            session?.activate()

            LOG_TIMER(.info, "WatchSync", "WatchConnectivity session activated")
        }

        func setTimerManager(_ manager: TimerManager) {
            self.timerManager = manager

            // Subscribe to timer changes
            manager.$isRunning
                .sink { [weak self] _ in
                    self?.sendTimerUpdate()
                }
                .store(in: &cancellables)

            manager.$isPaused
                .sink { [weak self] _ in
                    self?.sendTimerUpdate()
                }
                .store(in: &cancellables)

            manager.$secondsRemaining
                .sink { [weak self] _ in
                    self?.sendTimerUpdate()
                }
                .store(in: &cancellables)
        }

        // MARK: - Timer Sync

        private func sendTimerUpdate() {
            guard let timer = timerManager else { return }

            let snapshot = createSnapshot()

            // Send as application context (background delivery)
            do {
                let data = try JSONEncoder().encode(snapshot)
                try session?.updateApplicationContext(["snapshot": data])
                LOG_TIMER(.debug, "WatchSync", "Sent timer update to watch")
            } catch {
                LOG_TIMER(.error, "WatchSync", "Failed to send timer update: \(error)")
            }
        }

        private func createSnapshot() -> WatchSnapshot {
            guard let timer = timerManager else {
                return WatchSnapshot(activeTimer: nil, todaysTasks: [])
            }

            let activeTimer: ActiveTimerSummary? = timer.isRunning ? ActiveTimerSummary(
                id: UUID(),
                mode: .pomodoro, // Default for now
                durationSeconds: timer.secondsRemaining,
                startedAtISO: ISO8601DateFormatter().string(from: Date())
            ) : nil

            // TODO: Add today's tasks from CoreData
            let tasks: [TaskSummary] = []

            return WatchSnapshot(activeTimer: activeTimer, todaysTasks: tasks)
        }

        // MARK: - Handle Watch Messages

        private func handleMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
            LOG_TIMER(.debug, "WatchSync", "Received message from watch: \(message.keys.joined(separator: ", "))")

            guard let action = message["action"] as? String else {
                replyHandler([:])
                return
            }

            switch action {
            case "startTimer":
                let durationSeconds = message["duration"] as? Int
                let modeRaw = message["mode"] as? String
                let mode = modeRaw.flatMap { TimerMode(rawValue: $0) } ?? .timer
                TimerPageViewModel.shared.startExternalSession(mode: mode, durationSeconds: durationSeconds)
                if mode == .timer, let timer = timerManager {
                    if let durationSeconds {
                        timer.secondsRemaining = durationSeconds
                    }
                    timer.start()
                }

            case "stopTimer":
                TimerPageViewModel.shared.endSession(completed: false)
                timerManager?.stop()

            case "pauseTimer":
                TimerPageViewModel.shared.pauseSession()
                if let timer = timerManager, timer.isRunning, !timer.isPaused {
                    timer.togglePause()
                }

            case "resumeTimer":
                TimerPageViewModel.shared.resumeSession()
                if let timer = timerManager, timer.isRunning, timer.isPaused {
                    timer.togglePause()
                }

            case "requestSync":
                // Send full snapshot
                break

            default:
                LOG_TIMER(.info, "WatchSync", "Unknown action: \(action)")
            }

            // Send snapshot as reply
            do {
                let snapshot = createSnapshot()
                let data = try JSONEncoder().encode(snapshot)
                replyHandler(["snapshot": data])
            } catch {
                LOG_TIMER(.error, "WatchSync", "Failed to encode snapshot: \(error)")
                replyHandler([:])
            }
        }
    }

    // MARK: - WCSessionDelegate

    extension WatchConnectivityManager: WCSessionDelegate {
        nonisolated func sessionDidBecomeInactive(_: WCSession) {
            LOG_TIMER(.debug, "WatchSync", "Session became inactive")
        }

        nonisolated func sessionDidDeactivate(_ session: WCSession) {
            LOG_TIMER(.debug, "WatchSync", "Session deactivated")
            Task { @MainActor in
                session.activate()
            }
        }

        nonisolated func session(
            _ session: WCSession,
            activationDidCompleteWith _: WCSessionActivationState,
            error: Error?
        ) {
            Task { @MainActor in
                if let error {
                    LOG_TIMER(.error, "WatchSync", "Activation failed: \(error.localizedDescription)")
                } else {
                    isWatchAppInstalled = session.isWatchAppInstalled
                    isWatchReachable = session.isReachable
                    LOG_TIMER(
                        .info,
                        "WatchSync",
                        "Activated. Watch installed: \(session.isWatchAppInstalled), reachable: \(session.isReachable)"
                    )
                }
            }
        }

        nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
            Task { @MainActor in
                isWatchReachable = session.isReachable
                LOG_TIMER(.debug, "WatchSync", "Reachability changed: \(session.isReachable)")
            }
        }

        nonisolated func session(
            _: WCSession,
            didReceiveMessage message: [String: Any],
            replyHandler: @escaping ([String: Any]) -> Void
        ) {
            Task { @MainActor in
                handleMessage(message, replyHandler: replyHandler)
            }
        }
    }
#else
    // Stub for watchOS or platforms without WatchConnectivity
    @MainActor
    final class WatchConnectivityManager: ObservableObject {
        static let shared = WatchConnectivityManager()
        @Published var isWatchAppInstalled: Bool = false
        @Published var isWatchReachable: Bool = false
        private init() {}
        func setup(timerManager _: TimerManager) {}
        func sendTimerState(_: TimerState) {}
    }
#endif
