import Combine
import Foundation

enum AutoRescheduleProvenance: String, Codable {
    case automatic
    case userTriggered
}

enum AutoRescheduleGateReason: String, Codable {
    case startMonitoring
    case timerTick
    case manualTrigger
    case rescheduleEngine
    case applyOperations
    case notifyUser
    case historyWrite
}

enum AutoRescheduleGateStatus: String, Codable {
    case executed
    case suppressed
    case failed
}

struct AutoRescheduleAuditEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let reason: AutoRescheduleGateReason
    let provenance: AutoRescheduleProvenance
    let status: AutoRescheduleGateStatus
    let detail: String
}

@MainActor
final class AutoRescheduleAuditLog: ObservableObject {
    static let shared = AutoRescheduleAuditLog()

    @Published private(set) var entries: [AutoRescheduleAuditEntry] = []

    private init() {}

    func record(_ entry: AutoRescheduleAuditEntry) {
        entries.append(entry)
        save()
    }

    private var logURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("ItoriPlanner", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("auto-reschedule-audit.json")
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries.suffix(500))
            try data.write(to: logURL)
        } catch {
            LOG_UI(
                .error,
                "AutoReschedule",
                "Failed to save audit log",
                metadata: ["error": error.localizedDescription]
            )
        }
    }
}

enum AutoRescheduleContext {
    @TaskLocal static var isActive: Bool = false
}

enum AutoRescheduleGate {
    static func isEnabled() -> Bool {
        AppSettingsModel.shared.enableAutoReschedule
    }

    static func shouldAllow(reason: AutoRescheduleGateReason, provenance: AutoRescheduleProvenance) -> Bool {
        guard isEnabled() else {
            recordSuppressed(reason: reason, provenance: provenance)
            return false
        }
        return true
    }

    static func run(
        reason: AutoRescheduleGateReason,
        provenance: AutoRescheduleProvenance,
        work: @escaping @MainActor () async -> Void
    ) async -> Bool {
        guard shouldAllow(reason: reason, provenance: provenance) else { return false }
        return await AutoRescheduleContext.$isActive.withValue(true) {
            await work()
            recordExecuted(reason: reason, provenance: provenance)
            return true
        }
    }

    static func recordExecuted(reason: AutoRescheduleGateReason, provenance: AutoRescheduleProvenance) {
        AutoRescheduleActivityCounter.shared.recordCheckExecuted()
        AutoRescheduleAuditLog.shared.record(
            AutoRescheduleAuditEntry(
                id: UUID(),
                timestamp: Date(),
                reason: reason,
                provenance: provenance,
                status: .executed,
                detail: "Auto-reschedule executed"
            )
        )
    }

    static func recordSuppressed(reason: AutoRescheduleGateReason, provenance: AutoRescheduleProvenance) {
        AutoRescheduleActivityCounter.shared.recordSuppressed(reason: reason.rawValue)
        AutoRescheduleAuditLog.shared.record(
            AutoRescheduleAuditEntry(
                id: UUID(),
                timestamp: Date(),
                reason: reason,
                provenance: provenance,
                status: .suppressed,
                detail: "Auto-reschedule suppressed (disabled)"
            )
        )
    }

    static func debugAssertEnabled(reason: String) {
        #if DEBUG
            if !isEnabled() {
                assertionFailure(
                    "Auto-Reschedule invariant violated: \(reason). Guard must be used for all auto-reschedule work."
                )
            }
        #endif
    }
}

// MARK: - Dev Counters

struct AutoRescheduleCounters: Codable {
    var checksExecuted: Int = 0
    var sessionsAnalyzed: Int = 0
    var sessionsMoved: Int = 0
    var historyEntriesWritten: Int = 0
    var notificationsScheduled: Int = 0
    var suppressedExecutions: Int = 0
    var lastSuppressionReason: String?
    var lastUpdatedAt: Date?
}

#if DEBUG || DEVELOPER_MODE
    final class AutoRescheduleActivityCounter {
        static let shared = AutoRescheduleActivityCounter()
        private let lock = NSLock()
        private var counters = AutoRescheduleCounters()

        func snapshot() -> AutoRescheduleCounters { counters }

        func reset() {
            lock.lock()
            counters = AutoRescheduleCounters()
            lock.unlock()
        }

        func recordCheckExecuted() {
            mutate { $0.checksExecuted += 1 }
        }

        func recordSessionsAnalyzed(_ count: Int) {
            mutate { $0.sessionsAnalyzed += count }
        }

        func recordSessionsMoved(_ count: Int) {
            mutate { $0.sessionsMoved += count }
        }

        func recordHistoryWritten(_ count: Int) {
            mutate { $0.historyEntriesWritten += count }
        }

        func recordNotificationScheduled() {
            mutate { $0.notificationsScheduled += 1 }
        }

        func recordSuppressed(reason: String) {
            mutate {
                $0.suppressedExecutions += 1
                $0.lastSuppressionReason = reason
            }
        }

        private func mutate(_ block: (inout AutoRescheduleCounters) -> Void) {
            lock.lock()
            block(&counters)
            counters.lastUpdatedAt = Date()
            lock.unlock()
        }
    }
#else
    final class AutoRescheduleActivityCounter {
        static let shared = AutoRescheduleActivityCounter()
        func snapshot() -> AutoRescheduleCounters { AutoRescheduleCounters() }
        func reset() {}
        func recordCheckExecuted() {}
        func recordSessionsAnalyzed(_: Int) {}
        func recordSessionsMoved(_: Int) {}
        func recordHistoryWritten(_: Int) {}
        func recordNotificationScheduled() {}
        func recordSuppressed(reason _: String) {}
    }
#endif
