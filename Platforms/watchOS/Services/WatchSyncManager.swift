//
//  WatchSyncManager.swift
//  Itori (watchOS)
//
//  Manages data synchronization between iPhone and Apple Watch
//

#if os(watchOS)
    import Combine
    import Foundation
    import SwiftUI
    import WatchConnectivity

    @MainActor
    final class WatchSyncManager: NSObject, ObservableObject {
        static let shared = WatchSyncManager()

        // Published State
        @Published var activeTimer: ActiveTimerSummary?
        @Published var timerSecondsRemaining: Int = 0
        @Published var isTimerPaused: Bool = false
        @Published var tasks: [TaskSummary] = []
        @Published var isConnected: Bool = false
        @Published var lastSyncDate: Date?

        private var session: WCSession?
        private var timerUpdateTimer: Timer?
        private var periodicSyncTimer: Timer?
        private var cancellables = Set<AnyCancellable>()

        // Sync frequency: every 30 seconds when active
        private let syncInterval: TimeInterval = 30.0

        private func log(_ message: String) {
            #if DEBUG
                print(message)
            #endif
        }

        override private init() {
            super.init()
            setupWatchConnectivity()
            setupPeriodicSync()
        }

        deinit {
            periodicSyncTimer?.invalidate()
            timerUpdateTimer?.invalidate()
        }

        // MARK: - Setup

        private func setupWatchConnectivity() {
            guard WCSession.isSupported() else {
                log("⚠️  WatchSyncManager: WCSession not supported")
                return
            }

            session = WCSession.default
            session?.delegate = self
            session?.activate()

            log("🔗 WatchSyncManager: Session activated")
        }

        private func setupPeriodicSync() {
            // Request sync every 30 seconds to keep data fresh
            periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.requestFullSync()
                }
            }

            // Keep timer alive in background
            if let timer = periodicSyncTimer {
                RunLoop.current.add(timer, forMode: .common)
            }

            log("🔄 WatchSyncManager: Periodic sync enabled (every \(Int(syncInterval))s)")
        }

        // MARK: - Timer Actions

        func startTimer(mode: TimerMode, durationSeconds: Int?) {
            log("▶️  Starting timer: \(mode.displayName), duration: \(durationSeconds ?? 0)s")

            let message: [String: Any] = [
                "action": "startTimer",
                "mode": mode.rawValue,
                "duration": durationSeconds as Any
            ]

            sendMessage(message)

            // Optimistically update local state
            activeTimer = ActiveTimerSummary(
                id: UUID(),
                mode: mode,
                durationSeconds: durationSeconds,
                startedAtISO: ISO8601DateFormatter().string(from: Date())
            )
            timerSecondsRemaining = durationSeconds ?? 0
            startLocalTimerTracking()
            saveSharedTimerState()
        }

        func stopTimer() {
            log("⏹️  Stopping timer")

            let message: [String: Any] = ["action": "stopTimer"]
            sendMessage(message)

            // Update local state
            activeTimer = nil
            timerSecondsRemaining = 0
            isTimerPaused = false
            stopLocalTimerTracking()
            saveSharedTimerState()
        }

        func togglePause() {
            if isTimerPaused {
                resumeTimer()
            } else {
                pauseTimer()
            }
        }

        func pauseTimer() {
            log("⏸️  Pausing timer")
            let message: [String: Any] = ["action": "pauseTimer"]
            sendMessage(message)
            isTimerPaused = true
            stopLocalTimerTracking()
            saveSharedTimerState()
        }

        func resumeTimer() {
            log("▶️  Resuming timer")
            let message: [String: Any] = ["action": "resumeTimer"]
            sendMessage(message)
            isTimerPaused = false
            startLocalTimerTracking()
            saveSharedTimerState()
        }

        private func startLocalTimerTracking() {
            stopLocalTimerTracking()

            timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.timerSecondsRemaining > 0 else {
                        self?.stopLocalTimerTracking()
                        self?.activeTimer = nil
                        self?.saveSharedTimerState()
                        return
                    }
                    self.timerSecondsRemaining -= 1
                    self.saveSharedTimerState()
                }
            }
        }

        private func stopLocalTimerTracking() {
            timerUpdateTimer?.invalidate()
            timerUpdateTimer = nil
        }

        private func saveSharedTimerState() {
            guard let defaults = UserDefaults(suiteName: AppGroupConstants.identifier) else { return }
            let payload = WatchTimerStateSnapshot(
                isRunning: activeTimer != nil,
                isPaused: isTimerPaused,
                modeRaw: activeTimer?.mode.rawValue ?? "",
                remainingSeconds: timerSecondsRemaining,
                startedAtISO: activeTimer?.startedAtISO
            )
            if let data = try? JSONEncoder().encode(payload) {
                defaults.set(data, forKey: AppGroupConstants.watchTimerStateKey)
            }
        }

        // MARK: - Task Actions

        func toggleTaskCompletion(taskId: UUID) {
            log("✓ Toggling task: \(taskId)")

            let message: [String: Any] = [
                "action": "toggleTask",
                "taskId": taskId.uuidString
            ]

            sendMessage(message)

            // Optimistically update local state
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                var updatedTask = tasks[index]
                updatedTask = TaskSummary(
                    id: updatedTask.id,
                    title: updatedTask.title,
                    dueISO: updatedTask.dueISO,
                    isComplete: !updatedTask.isComplete
                )
                tasks[index] = updatedTask
            }
        }

        func addTask(title: String, dueISO: String?) {
            log("➕ Adding task: \(title)")

            var message: [String: Any] = [
                "action": "addTask",
                "title": title
            ]
            if let due = dueISO {
                message["dueISO"] = due
            }

            sendMessage(message)

            // Optimistically add to local state
            let newTask = TaskSummary(
                id: UUID(),
                title: title,
                dueISO: dueISO,
                isComplete: false
            )
            tasks.insert(newTask, at: 0)
        }

        // MARK: - Communication

        private func sendMessage(_ message: [String: Any]) {
            guard let session, session.isReachable else {
                log("❌ WatchSyncManager: iPhone not reachable")
                return
            }

            session.sendMessage(message, replyHandler: { [weak self] reply in
                Task { @MainActor [weak self] in
                    self?.handleReply(reply)
                }
            }, errorHandler: { error in
                log("❌ WatchSyncManager: Send error: \(error.localizedDescription)")
            })
        }

        func requestFullSync() {
            let message: [String: Any] = ["action": "requestSync"]
            sendMessage(message)
        }

        private func handleReply(_ reply: [String: Any]) {
            log("📥 WatchSyncManager: Received reply with keys: \(reply.keys.joined(separator: ", "))")

            // Update sync status
            lastSyncDate = Date()

            // Parse and update state from reply
            if let snapshotData = reply["snapshot"] as? Data {
                decodeSnapshot(snapshotData)
            }
        }

        private func decodeSnapshot(_ data: Data) {
            do {
                let snapshot = try JSONDecoder().decode(WatchSnapshot.self, from: data)

                // Update timer state
                activeTimer = snapshot.activeTimer
                if let timer = snapshot.activeTimer {
                    // Calculate remaining time
                    let formatter = ISO8601DateFormatter()
                    if let startDate = formatter.date(from: timer.startedAtISO),
                       let duration = timer.durationSeconds
                    {
                        let elapsed = Int(Date().timeIntervalSince(startDate))
                        timerSecondsRemaining = max(0, duration - elapsed)

                        if timerSecondsRemaining > 0 {
                            startLocalTimerTracking()
                        }
                    } else {
                        timerSecondsRemaining = 0
                    }
                } else {
                    timerSecondsRemaining = 0
                    stopLocalTimerTracking()
                }

                // Update tasks
                tasks = snapshot.todaysTasks

                log("✅ WatchSyncManager: Synced \(tasks.count) tasks, timer: \(activeTimer != nil)")

            } catch {
                log("❌ WatchSyncManager: Failed to decode snapshot: \(error)")
            }
        }
    }

    // MARK: - WCSessionDelegate

    extension WatchSyncManager: WCSessionDelegate {
        nonisolated func session(
            _: WCSession,
            activationDidCompleteWith activationState: WCSessionActivationState,
            error: Error?
        ) {
            Task { @MainActor in
                isConnected = (activationState == .activated)

                if let error {
                    log("❌ WatchSyncManager: Activation error: \(error.localizedDescription)")
                } else {
                    log("✅ WatchSyncManager: Activated with state: \(activationState.rawValue)")
                    // Request initial sync
                    requestFullSync()
                }
            }
        }

        nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any]) {
            Task { @MainActor in
                log("📥 WatchSyncManager: Received message: \(message.keys.joined(separator: ", "))")

                // Handle updates from iPhone
                if let snapshotData = message["snapshot"] as? Data {
                    decodeSnapshot(snapshotData)
                }
            }
        }

        nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
            Task { @MainActor in
                log(
                    "📥 WatchSyncManager: Received context with keys: \(applicationContext.keys.joined(separator: ", "))"
                )

                guard !applicationContext.isEmpty else {
                    log("⚠️  WatchSyncManager: Application context is empty")
                    return
                }

                if let snapshotData = applicationContext["snapshot"] as? Data {
                    guard !snapshotData.isEmpty else {
                        log("⚠️  WatchSyncManager: Snapshot data is empty")
                        return
                    }
                    decodeSnapshot(snapshotData)
                } else {
                    log("⚠️  WatchSyncManager: No snapshot data in context")
                }
            }
        }
    }

    struct WatchTimerStateSnapshot: Codable {
        let isRunning: Bool
        let isPaused: Bool
        let modeRaw: String
        let remainingSeconds: Int
        let startedAtISO: String?
    }

#endif
