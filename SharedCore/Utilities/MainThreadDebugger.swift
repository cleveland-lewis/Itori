import Foundation
import Combine
import os.log

@MainActor
final class MainThreadDebugger: ObservableObject {
    static let shared = MainThreadDebugger()
    
    @Published private(set) var isEnabled = false
    @Published private(set) var events: [DebugEvent] = []
    @Published private(set) var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    private var timer: Timer?
    private let maxEvents = 500
    private let logger = Logger(subsystem: "com.itori.app", category: "MainThreadDebugger")
    
    struct DebugEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: EventType
        let message: String
        let threadInfo: String
        let stackTrace: [String]
        
        enum EventType: String {
            case mainThreadBlock = "⚠️ MAIN THREAD BLOCKED"
            case longOperation = "🐌 LONG OPERATION"
            case memoryWarning = "💾 MEMORY WARNING"
            case uiFreeze = "❄️ UI FREEZE"
            case taskCreated = "📦 TASK CREATED"
            case taskCompleted = "✅ TASK COMPLETED"
            case warning = "⚠️ WARNING"
            case info = "ℹ️ INFO"
        }
    }
    
    struct PerformanceMetrics {
        var totalMainThreadBlocks: Int = 0
        var longestBlockDuration: TimeInterval = 0
        var averageBlockDuration: TimeInterval = 0
        var memoryUsageMB: Double = 0
        var activeTasks: Int = 0
    }
    
    private init() {}
    
    func enable() {
        guard !isEnabled else { 
            DebugLogger.log("🐜 [MainThreadDebugger] Already enabled - ignoring duplicate enable call")
            return 
        }
        
        DebugLogger.log("🐜 [MainThreadDebugger] enable() called - activating debugger...")
        
        isEnabled = true
        events.removeAll()
        startMonitoring()
        log(.info, "Main Thread Debugger enabled")
        
        let timestamp = formatTimestamp(Date())
        DebugLogger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        DebugLogger.log("🐜 [MainThreadDebugger] ENABLED at \(timestamp)")
        DebugLogger.log("🐜 All events will be logged to console with full details")
        DebugLogger.log("🐜 Monitoring started: checking main thread every 100ms")
        DebugLogger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    func disable() {
        guard isEnabled else { return }
        
        let timestamp = formatTimestamp(Date())
        let totalBlocks = performanceMetrics.totalMainThreadBlocks
        let totalEvents = events.count
        
        isEnabled = false
        stopMonitoring()
        log(.info, "Main Thread Debugger disabled")
        
        DebugLogger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        DebugLogger.log("🐜 [MainThreadDebugger] DISABLED at \(timestamp)")
        DebugLogger.log("🐜 Session Summary:")
        DebugLogger.log("🐜   - Total Events: \(totalEvents)")
        DebugLogger.log("🐜   - Main Thread Blocks: \(totalBlocks)")
        DebugLogger.log("🐜   - Memory Peak: \(String(format: "%.1f", performanceMetrics.memoryUsageMB))MB")
        DebugLogger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    func toggle() {
        DebugLogger.log("🐜 [MainThreadDebugger] toggle() called - current state: \(isEnabled ? "ON" : "OFF")")
        if isEnabled {
            DebugLogger.log("🐜 [MainThreadDebugger] Disabling...")
            disable()
        } else {
            DebugLogger.log("🐜 [MainThreadDebugger] Enabling...")
            enable()
        }
    }
    
    func clearEvents() {
        events.removeAll()
        performanceMetrics = PerformanceMetrics()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        // Monitor main thread every 100ms
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMainThread()
            }
        }
        
        // Monitor memory
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            while self.isEnabled {
                self.updateMemoryUsage()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkMainThread() {
        guard isEnabled else { return }
        
        // Check if main thread is blocked
        let start = CFAbsoluteTimeGetCurrent()
        
        // Perform a dummy operation
        _ = (0...100).reduce(0, +)
        
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        // If this simple operation took too long, main thread is blocked
        if elapsed > 0.016 { // 16ms = 60fps threshold
            recordMainThreadBlock(duration: elapsed)
        }
        
        // Log periodic status even when not blocked (every 5 seconds)
        let now = Date()
        if let last = lastStatusLog, now.timeIntervalSince(last) < 5.0 {
            return
        }
        lastStatusLog = now
        
        let timeStr = formatTimestamp(now)
        let memStr = String(format: "%.1f", performanceMetrics.memoryUsageMB)
        let blocksStr = performanceMetrics.totalMainThreadBlocks
        DebugLogger.log("🟢 [\(timeStr)] [MainThreadDebugger] STATUS: Memory: \(memStr)MB | Blocks: \(blocksStr) | Active Tasks: \(performanceMetrics.activeTasks)")
    }
    
    private var lastStatusLog: Date?
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            Task { @MainActor [weak self] in
                self?.performanceMetrics.memoryUsageMB = memoryMB
            }
        }
    }
    
    // MARK: - Event Recording
    
    private func recordMainThreadBlock(duration: TimeInterval) {
        let stackTrace = Thread.callStackSymbols.prefix(10).map { $0 }
        let timestamp = Date()
        
        let event = DebugEvent(
            timestamp: timestamp,
            type: duration > 0.1 ? .uiFreeze : .mainThreadBlock,
            message: "Main thread blocked for \(String(format: "%.2f", duration * 1000))ms",
            threadInfo: threadInfo(),
            stackTrace: stackTrace
        )
        
        addEvent(event)
        
        // Update metrics
        performanceMetrics.totalMainThreadBlocks += 1
        if duration > performanceMetrics.longestBlockDuration {
            performanceMetrics.longestBlockDuration = duration
        }
        
        // Calculate running average
        let total = performanceMetrics.averageBlockDuration * Double(performanceMetrics.totalMainThreadBlocks - 1) + duration
        performanceMetrics.averageBlockDuration = total / Double(performanceMetrics.totalMainThreadBlocks)
        
        logger.warning("⚠️ Main thread blocked for \(duration * 1000, format: .fixed(precision: 2))ms")
        
        // Console logging when debugger enabled
        let timeStr = formatTimestamp(timestamp)
        DebugLogger.log("🔴 [\(timeStr)] [MainThreadDebugger] MAIN THREAD BLOCKED: \(String(format: "%.2f", duration * 1000))ms")
        DebugLogger.log("🔴 [MainThreadDebugger] Stack trace:")
        for (index, frame) in stackTrace.enumerated() {
            DebugLogger.log("🔴   \(index): \(frame)")
        }
    }
    
    func recordLongOperation(name: String, duration: TimeInterval) {
        guard isEnabled else { return }
        
        let stackTrace = Thread.callStackSymbols.prefix(5).map { $0 }
        let timestamp = Date()
        
        let event = DebugEvent(
            timestamp: timestamp,
            type: .longOperation,
            message: "\(name) took \(String(format: "%.2f", duration * 1000))ms",
            threadInfo: threadInfo(),
            stackTrace: stackTrace
        )
        
        addEvent(event)
        logger.info("🐌 Long operation: \(name) - \(duration * 1000, format: .fixed(precision: 2))ms")
        
        // Console logging when debugger enabled
        let timeStr = formatTimestamp(timestamp)
        DebugLogger.log("🟡 [\(timeStr)] [MainThreadDebugger] LONG OPERATION: \(name) took \(String(format: "%.2f", duration * 1000))ms")
        if !stackTrace.isEmpty {
            DebugLogger.log("🟡 [MainThreadDebugger] Top of stack: \(stackTrace[0])")
        }
    }
    
    func recordTaskCreation(name: String) {
        guard isEnabled else { return }
        
        let timestamp = Date()
        let event = DebugEvent(
            timestamp: timestamp,
            type: .taskCreated,
            message: "Task created: \(name)",
            threadInfo: threadInfo(),
            stackTrace: Thread.callStackSymbols.prefix(3).map { $0 }
        )
        
        addEvent(event)
        performanceMetrics.activeTasks += 1
        
        // Console logging when debugger enabled
        let timeStr = formatTimestamp(timestamp)
        DebugLogger.log("📦 [\(timeStr)] [MainThreadDebugger] TASK CREATED: \(name) (Active: \(performanceMetrics.activeTasks))")
    }
    
    func recordTaskCompletion(name: String, duration: TimeInterval) {
        guard isEnabled else { return }
        
        let timestamp = Date()
        let event = DebugEvent(
            timestamp: timestamp,
            type: .taskCompleted,
            message: "Task completed: \(name) (\(String(format: "%.2f", duration * 1000))ms)",
            threadInfo: threadInfo(),
            stackTrace: []
        )
        
        addEvent(event)
        performanceMetrics.activeTasks = max(0, performanceMetrics.activeTasks - 1)
        
        // Console logging when debugger enabled
        let timeStr = formatTimestamp(timestamp)
        DebugLogger.log("✅ [\(timeStr)] [MainThreadDebugger] TASK COMPLETED: \(name) in \(String(format: "%.2f", duration * 1000))ms (Active: \(performanceMetrics.activeTasks))")
    }
    
    func recordWarning(message: String) {
        guard isEnabled else { return }
        
        let stackTrace = Thread.callStackSymbols.prefix(5).map { $0 }
        let timestamp = Date()
        
        let event = DebugEvent(
            timestamp: timestamp,
            type: .warning,
            message: message,
            threadInfo: threadInfo(),
            stackTrace: stackTrace
        )
        
        addEvent(event)
        logger.warning("⚠️ \(message)")
        
        // Console logging when debugger enabled
        let timeStr = formatTimestamp(timestamp)
        DebugLogger.log("⚠️  [\(timeStr)] [MainThreadDebugger] WARNING: \(message)")
        if !stackTrace.isEmpty {
            DebugLogger.log("⚠️  [MainThreadDebugger] Location: \(stackTrace[0])")
        }
    }
    
    func recordInfo(message: String) {
        guard isEnabled else { return }
        
        let timestamp = Date()
        let stack = Thread.callStackSymbols.prefix(8).map { $0 }
        let event = DebugEvent(
            timestamp: timestamp,
            type: .info,
            message: message,
            threadInfo: threadInfo(),
            stackTrace: stack
        )
        
        addEvent(event)
        logger.info("ℹ️ \(message)")
        
        // Console logging when debugger enabled with FULL details
        let timeStr = formatTimestamp(timestamp)
        let threadDetails = threadInfo()
        DebugLogger.log("ℹ️  [\(timeStr)] [MainThreadDebugger] \(message)")
        DebugLogger.log("ℹ️  Thread: \(threadDetails)")
        DebugLogger.log("ℹ️  Call stack:")
        for (index, frame) in stack.enumerated() {
            DebugLogger.log("ℹ️    [\(index)] \(frame)")
        }
        DebugLogger.log("ℹ️  Memory: \(String(format: "%.1f", performanceMetrics.memoryUsageMB))MB | Active Tasks: \(performanceMetrics.activeTasks)")
        DebugLogger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func addEvent(_ event: DebugEvent) {
        events.append(event)
        
        // Trim to max events
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
    }
    
    private func threadInfo() -> String {
        let thread = Thread.current
        var info = ""
        
        if Thread.isMainThread {
            info = "🔵 Main Thread"
        } else {
            info = "🟣 Background Thread"
            if let name = thread.name, !name.isEmpty {
                info += " (\(name))"
            }
        }
        
        info += " | Queue: \(getCurrentQueueName())"
        info += " | Priority: \(String(format: "%.2f", thread.threadPriority))"
        
        return info
    }
    
    private func getCurrentQueueName() -> String {
        let name = String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) ?? "unknown"
        return name.isEmpty ? "anonymous" : name
    }
    
    private func log(_ level: OSLogType, _ message: String) {
        logger.log(level: level, "\(message)")
    }
}

// MARK: - Convenience Functions

func debugMainThread(_ message: String) {
    MainThreadDebugger.shared.recordInfo(message: message)
}

func debugWarning(_ message: String) {
    MainThreadDebugger.shared.recordWarning(message: message)
}

func measureOperation<T>(_ name: String, operation: () throws -> T) rethrows -> T {
    let start = CFAbsoluteTimeGetCurrent()
    let result = try operation()
    let duration = CFAbsoluteTimeGetCurrent() - start
    
    if duration > 0.016 { // Longer than one frame
        MainThreadDebugger.shared.recordLongOperation(name: name, duration: duration)
    }
    
    return result
}

func measureAsyncOperation<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
    MainThreadDebugger.shared.recordTaskCreation(name: name)
    let start = CFAbsoluteTimeGetCurrent()
    let result = try await operation()
    let duration = CFAbsoluteTimeGetCurrent() - start
    MainThreadDebugger.shared.recordTaskCompletion(name: name, duration: duration)
    return result
}
