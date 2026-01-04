//
//  IOSWatchSyncCoordinator.swift
//  Itori (iOS)
//
//  Handles watch connectivity on the iPhone side
//

#if os(iOS)
import Foundation
import Combine
import WatchConnectivity

@MainActor
final class IOSWatchSyncCoordinator: NSObject, ObservableObject {
    static let shared = IOSWatchSyncCoordinator()
    
    private var session: WCSession?
    private var timerManager: TimerManager?
    private var assignmentsStore: AssignmentsStore?
    private var cancellables = Set<AnyCancellable>()
    private var periodicSyncTimer: Timer?
    
    @Published var isWatchAppInstalled: Bool = false
    @Published var isWatchReachable: Bool = false
    
    // Sync frequency: every 15 seconds when watch is reachable
    private let syncInterval: TimeInterval = 15.0

    nonisolated static func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    deinit {
        periodicSyncTimer?.invalidate()
    }
    
    func configure(timerManager: TimerManager, assignmentsStore: AssignmentsStore) {
        self.timerManager = timerManager
        self.assignmentsStore = assignmentsStore
        
        // Observe timer changes and sync to watch immediately
        timerManager.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncToWatch()
            }
        }
        .store(in: &cancellables)
        
        // Observe task changes and sync to watch immediately
        assignmentsStore.$tasks.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncToWatch()
            }
        }
        .store(in: &cancellables)
        
        // Start periodic sync
        startPeriodicSync()
        
        IOSWatchSyncCoordinator.log("📱 IOSWatchSyncCoordinator: Configured with stores and periodic sync")
    }
    
    private func startPeriodicSync() {
        // Sync every 15 seconds to keep watch updated
        periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let session = self.session,
                      session.isReachable else { return }
                
                self.syncToWatch()
            }
        }
        
        // Keep timer alive in background
        if let timer = periodicSyncTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        IOSWatchSyncCoordinator.log("🔄 IOSWatchSyncCoordinator: Periodic sync enabled (every \(Int(syncInterval))s)")
    }
    
    // MARK: - Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            IOSWatchSyncCoordinator.log("⚠️  IOSWatchSyncCoordinator: WCSession not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        IOSWatchSyncCoordinator.log("🔗 IOSWatchSyncCoordinator: Session activated")
    }
    
    // MARK: - Sync to Watch
    
    func syncToWatch() {
        guard let session = session else {
            IOSWatchSyncCoordinator.log("⚠️  IOSWatchSyncCoordinator: Session not available")
            return
        }
        
        guard session.isPaired else {
            IOSWatchSyncCoordinator.log("⚠️  IOSWatchSyncCoordinator: Watch not paired")
            return
        }
        
        guard session.isWatchAppInstalled else {
            IOSWatchSyncCoordinator.log("⚠️  IOSWatchSyncCoordinator: Watch app not installed")
            return
        }
        
        let snapshot = createSnapshot()
        
        guard let snapshotData = try? JSONEncoder().encode(snapshot) else {
            IOSWatchSyncCoordinator.log("❌ IOSWatchSyncCoordinator: Failed to encode snapshot")
            return
        }
        
        // Verify data is not empty
        guard !snapshotData.isEmpty else {
            IOSWatchSyncCoordinator.log("❌ IOSWatchSyncCoordinator: Snapshot data is empty")
            return
        }
        
        // Use application context for background sync
        let context: [String: Any] = ["snapshot": snapshotData]
        
        do {
            try session.updateApplicationContext(context)
            IOSWatchSyncCoordinator.log("✅ IOSWatchSyncCoordinator: Synced to watch (\(snapshotData.count) bytes)")
        } catch {
            IOSWatchSyncCoordinator.log("❌ IOSWatchSyncCoordinator: Sync error: \(error.localizedDescription)")
            
            // If context update fails, try sending as message if watch is reachable
            if session.isReachable {
                session.sendMessage(["snapshot": snapshotData], replyHandler: { reply in
                    IOSWatchSyncCoordinator.log("✅ IOSWatchSyncCoordinator: Fallback message sent")
                }, errorHandler: { error in
                    IOSWatchSyncCoordinator.log("❌ IOSWatchSyncCoordinator: Fallback message failed: \(error.localizedDescription)")
                })
            }
        }
    }
    
    private func createSnapshot() -> WatchSnapshot {
        // Get active timer
        let activeTimer: ActiveTimerSummary?
        if let timerManager = timerManager, timerManager.isRunning {
            activeTimer = ActiveTimerSummary(
                id: UUID(),
                mode: .pomodoro, // Get from timer manager if available
                durationSeconds: timerManager.secondsRemaining,
                startedAtISO: ISO8601DateFormatter().string(from: Date())
            )
        } else {
            activeTimer = nil
        }
        
        // Get today's tasks
        let todaysTasks: [TaskSummary]
        if let store = assignmentsStore {
            // Filter for today's tasks and incomplete tasks
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            
            todaysTasks = store.tasks
                .filter { task in
                    // Include incomplete tasks
                    if !task.isCompleted { return true }
                    // Include tasks due today
                    if let due = task.due,
                       due >= today && due < tomorrow {
                        return true
                    }
                    return false
                }
                .prefix(20) // Limit to 20 tasks
                .map { task in
                    TaskSummary(
                        id: task.id,
                        title: task.title,
                        dueISO: task.due.map { ISO8601DateFormatter().string(from: $0) },
                        isComplete: task.isCompleted
                    )
                }
        } else {
            todaysTasks = []
        }
        
        return WatchSnapshot(
            activeTimer: activeTimer,
            todaysTasks: todaysTasks,
            energyToday: nil,
            lastSyncISO: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Handle Watch Commands
    
    private func handleWatchMessage(_ message: [String: Any]) -> [String: Any] {
        IOSWatchSyncCoordinator.log("📥 IOSWatchSyncCoordinator: Handling message: \(message.keys.joined(separator: ", "))")
        
        guard let action = message["action"] as? String else {
            return ["error": "No action specified"]
        }
        
        switch action {
        case "startTimer":
            handleStartTimer(message)
        case "stopTimer":
            handleStopTimer()
        case "toggleTask":
            handleToggleTask(message)
        case "addTask":
            handleAddTask(message)
        case "requestSync":
            // Sync will happen in reply
            break
        default:
            IOSWatchSyncCoordinator.log("⚠️  Unknown action: \(action)")
        }
        
        // Always return current snapshot
        let snapshot = createSnapshot()
        if let data = try? JSONEncoder().encode(snapshot) {
            return ["snapshot": data]
        }
        return [:]
    }
    
    private func handleStartTimer(_ message: [String: Any]) {
        guard let timerManager = timerManager else { return }
        
        if let durationSeconds = message["duration"] as? Int {
            timerManager.secondsRemaining = durationSeconds
        }
        timerManager.start()
        
        IOSWatchSyncCoordinator.log("▶️  Started timer from watch")
    }
    
    private func handleStopTimer() {
        timerManager?.stop()
        IOSWatchSyncCoordinator.log("⏹️  Stopped timer from watch")
    }
    
    private func handleToggleTask(_ message: [String: Any]) {
        guard let store = assignmentsStore,
              let taskIdString = message["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString),
              let taskIndex = store.tasks.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        
        var task = store.tasks[taskIndex]
        task.isCompleted.toggle()
        store.updateTask(task)
        
        IOSWatchSyncCoordinator.log("✓ Toggled task from watch: \(task.title)")
    }
    
    private func handleAddTask(_ message: [String: Any]) {
        guard let store = assignmentsStore,
              let title = message["title"] as? String else {
            return
        }
        
        let dueDate: Date?
        if let dueISO = message["dueISO"] as? String {
            dueDate = ISO8601DateFormatter().date(from: dueISO)
        } else {
            dueDate = nil
        }
        
        let newTask = AppTask(
            id: UUID(),
            title: title,
            courseId: nil,
            due: dueDate,
            estimatedMinutes: 60,
            minBlockMinutes: 20,
            maxBlockMinutes: 120,
            difficulty: 0.5,
            importance: 0.5,
            type: .homework,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .homework
        )
        
        store.addTask(newTask)
        
        IOSWatchSyncCoordinator.log("➕ Added task from watch: \(title)")
    }
}

// MARK: - WCSessionDelegate

extension IOSWatchSyncCoordinator: WCSessionDelegate {
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        IOSWatchSyncCoordinator.log("⚠️  IOSWatchSyncCoordinator: Session inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        IOSWatchSyncCoordinator.log("⚠️  IOSWatchSyncCoordinator: Session deactivated")
        Task { @MainActor in
            session.activate()
        }
    }
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isWatchAppInstalled = session.isWatchAppInstalled
            isWatchReachable = session.isReachable
            
            if let error = error {
                IOSWatchSyncCoordinator.log("❌ IOSWatchSyncCoordinator: Activation error: \(error.localizedDescription)")
            } else {
                IOSWatchSyncCoordinator.log("✅ IOSWatchSyncCoordinator: Activated")
                syncToWatch()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
            IOSWatchSyncCoordinator.log("🔗 IOSWatchSyncCoordinator: Reachability changed: \(session.isReachable)")
            
            if session.isReachable {
                syncToWatch()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            let reply = handleWatchMessage(message)
            replyHandler(reply)
        }
    }
}

#endif
