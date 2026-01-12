import Combine
import Foundation

/// Service that monitors scheduled sessions and detects when they pass their end time
/// without being completed. Triggers automatic rescheduling for missed sessions.
@MainActor
final class MissedEventDetectionService: ObservableObject {
    static let shared = MissedEventDetectionService()

    // MARK: - Published State

    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var lastCheckAt: Date?
    @Published private(set) var missedSessionsDetected: Int = 0

    // MARK: - Dependencies

    private let plannerStore = PlannerStore.shared
    private let settings = AppSettingsModel.shared

    // MARK: - Monitoring State

    private var timer: Timer?
    private var checkInterval: TimeInterval {
        TimeInterval(settings.autoRescheduleCheckInterval * 60)
    }

    // MARK: - Initialization

    private init() {
        LOG_UI(.info, "MissedEventDetection", "Service initialized")
    }

    // MARK: - Public API

    /// Start monitoring for missed sessions
    /// Should be called on app launch
    func startMonitoring() {
        guard AutoRescheduleGate.shouldAllow(reason: .startMonitoring, provenance: .automatic) else {
            stopMonitoring()
            LOG_UI(.info, "MissedEventDetection", "Auto-reschedule disabled, not starting monitoring")
            return
        }

        // Clean up existing timer if any
        stopMonitoring()

        LOG_UI(.info, "MissedEventDetection", "Starting monitoring with interval: \(checkInterval)s")

        // Schedule timer
        timer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.runGateCheck(reason: .timerTick, provenance: .automatic)
            }
        }

        // Add to run loop to ensure it fires
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        isMonitoring = true

        // Perform initial check immediately
        Task {
            await runGateCheck(reason: .startMonitoring, provenance: .automatic)
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        LOG_UI(.info, "MissedEventDetection", "Monitoring stopped")
    }

    /// Manually trigger a check (for testing or manual refresh)
    func triggerCheck() {
        Task {
            await runGateCheck(reason: .manualTrigger, provenance: .userTriggered)
        }
    }

    // MARK: - Detection Logic

    private func runGateCheck(reason: AutoRescheduleGateReason, provenance: AutoRescheduleProvenance) async {
        _ = await AutoRescheduleGate.run(reason: reason, provenance: provenance) { [weak self] in
            await self?.checkForMissedSessions()
        }
    }

    /// Check for sessions that have ended but weren't completed
    private func checkForMissedSessions() async {
        AutoRescheduleGate.debugAssertEnabled(reason: "Missed session check executed while disabled")

        lastCheckAt = Date()
        let now = Date()

        LOG_UI(.debug, "MissedEventDetection", "Running check at \(now)")

        // Find sessions that meet missed criteria
        let missedSessions = plannerStore.scheduled.filter { session in
            // Session must have ended in the past
            guard session.end < now else { return false }

            // Don't reschedule sessions that ended more than 24 hours ago
            let hoursSinceEnd = now.timeIntervalSince(session.end) / 3600
            guard hoursSinceEnd < 24 else { return false }

            // Respect user-edited sessions (user manually moved it)
            guard !session.isUserEdited else { return false }

            // Respect locked sessions (fixed appointments)
            guard !session.isLocked else { return false }

            // Only reschedule actual tasks/study sessions, not breaks or events
            guard session.type == .task || session.type == .study else { return false }

            // Check if session has valid assignment
            guard session.assignmentId != nil else { return false }

            // IDEMPOTENCY: Don't reschedule if already marked as auto-rescheduled in this time window
            // Check if provenance indicates it was recently rescheduled (within last check interval)
            if let provenance = session.aiProvenance, provenance.contains("auto-reschedule"),
               let computed = session.aiComputedAt
            {
                let minutesSinceReschedule = now.timeIntervalSince(computed) / 60
                // Skip if rescheduled within last 2x check interval to avoid duplicate operations
                if minutesSinceReschedule < Double(settings.autoRescheduleCheckInterval * 2) {
                    return false
                }
            }

            return true
        }

        guard !missedSessions.isEmpty else {
            LOG_UI(.debug, "MissedEventDetection", "No missed sessions found")
            return
        }

        AutoRescheduleActivityCounter.shared.recordSessionsAnalyzed(missedSessions.count)
        missedSessionsDetected = missedSessions.count
        LOG_UI(.info, "MissedEventDetection", "Detected \(missedSessions.count) missed sessions", metadata: [
            "sessionIds": missedSessions.map(\.id.uuidString).joined(separator: ", ")
        ])

        // Trigger rescheduling
        await AutoRescheduleEngine.shared.reschedule(missedSessions)
    }
}
