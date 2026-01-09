#if canImport(WatchConnectivity) && os(iOS)
    import Foundation
    import WatchConnectivity

    final class PhoneWatchBridge: NSObject {
        static let shared = PhoneWatchBridge()

        private let session: WCSession?
        private let isoFormatter = ISO8601DateFormatter()
        private var tasks: [TaskSummary]
        private var energy: EnergyLevel = .medium
        private var activeTimer: ActiveTimerSummary?

        override private init() {
            self.session = WCSession.isSupported() ? WCSession.default : nil
            self.tasks = [
                TaskSummary(id: UUID(), title: "Weekly review notes", dueISO: nil, isComplete: false),
                TaskSummary(id: UUID(), title: "Prep slides for Tuesday sync", dueISO: nil, isComplete: false)
            ]
            super.init()
            session?.delegate = self
            session?.activate()
        }

        private func currentSnapshot() -> WatchSnapshot {
            WatchSnapshot(
                activeTimer: activeTimer,
                todaysTasks: tasks,
                energyToday: energy,
                lastSyncISO: isoFormatter.string(from: Date())
            )
        }

        private func handleCommand(_ command: WatchCommand) {
            switch command {
            case let .startTimer(mode, duration):
                let seconds = duration ?? (mode == .pomodoro ? 25 * 60 : nil)
                activeTimer = ActiveTimerSummary(
                    id: UUID(),
                    mode: mode,
                    durationSeconds: seconds,
                    startedAtISO: isoFormatter.string(from: Date())
                )
            case let .completeTask(id):
                tasks.removeAll { $0.id == id }
            case let .setEnergy(level, _):
                energy = level
            }
        }

        private func replyWithSnapshot(_ replyHandler: @escaping ([String: Any]) -> Void) {
            guard let data = try? JSONEncoder().encode(currentSnapshot()) else {
                replyHandler([:])
                return
            }
            replyHandler(["snapshot": data])
        }
    }

    // MARK: - WCSessionDelegate

    extension PhoneWatchBridge: WCSessionDelegate {
        func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

        func session(
            _: WCSession,
            didReceiveMessage message: [String: Any],
            replyHandler: @escaping ([String: Any]) -> Void
        ) {
            if let payload = message["command"] as? Data, let command = try? JSONDecoder().decode(
                WatchCommand.self,
                from: payload
            ) {
                handleCommand(command)
                replyWithSnapshot(replyHandler)
                return
            }
            if (message["requestSnapshot"] as? Bool) == true {
                replyWithSnapshot(replyHandler)
                return
            }
            replyHandler([:])
        }

        func sessionDidBecomeInactive(_: WCSession) {}
        func sessionDidDeactivate(_ session: WCSession) {
            session.activate()
        }
    }
#endif
