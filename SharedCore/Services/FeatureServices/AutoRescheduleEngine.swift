import Foundation
import Combine

/// Time slot representation
struct TimeSlot: Equatable {
    let start: Date
    let end: Date
}

/// Engine that automatically reschedules missed sessions using intelligent strategies
@MainActor
final class AutoRescheduleEngine: ObservableObject {
    static let shared = AutoRescheduleEngine()
    
    // MARK: - Published State
    
    @Published private(set) var isRescheduling: Bool = false
    @Published private(set) var lastRescheduleAt: Date?
    @Published private(set) var rescheduleHistory: [RescheduleOperation] = []
    
    // MARK: - Dependencies
    
    private let plannerStore = PlannerStore.shared
    private let settings = AppSettingsModel.shared
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Models
    
    struct RescheduleOperation: Identifiable, Codable {
        let id: UUID
        let sessionId: UUID
        let originalStart: Date
        let originalEnd: Date
        let newStart: Date
        let newEnd: Date
        let strategy: RescheduleStrategy
        let pushedSessions: [UUID]
        let timestamp: Date
    }
    
    enum RescheduleStrategy: String, Codable {
        case sameDaySlot        // Found free slot today
        case sameDayPushed      // Pushed lower priority tasks today
        case nextDay            // Moved to tomorrow
        case overflow           // Could not reschedule
        
        var displayName: String {
            switch self {
            case .sameDaySlot: return "Rescheduled Today"
            case .sameDayPushed: return "Rescheduled Today (Pushed Others)"
            case .nextDay: return "Moved to Tomorrow"
            case .overflow: return "Needs Manual Scheduling"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        LOG_UI(.info, "AutoReschedule", "Engine initialized")
        loadHistory()
    }
    
    // MARK: - Public API
    
    /// Reschedule missed sessions using intelligent strategies
    func reschedule(_ missedSessions: [StoredScheduledSession]) async {
        await AutoRescheduleGate.run(reason: .rescheduleEngine, provenance: .automatic) { [weak self] in
            await self?.runReschedule(missedSessions)
        }
    }

    private func runReschedule(_ missedSessions: [StoredScheduledSession]) async {
        AutoRescheduleGate.debugAssertEnabled(reason: "Auto-reschedule engine executed while disabled")
        guard !isRescheduling else {
            LOG_UI(.warn, "AutoReschedule", "Already rescheduling, skipping")
            return
        }
        
        isRescheduling = true
        defer { isRescheduling = false }
        
        LOG_UI(.info, "AutoReschedule", "Starting reschedule for \(missedSessions.count) sessions")
        
        var operations: [RescheduleOperation] = []
        
        for session in missedSessions {
            if let operation = await rescheduleSession(session) {
                operations.append(operation)
            }
        }
        
        guard !operations.isEmpty else {
            AutoRescheduleAuditLog.shared.record(
                AutoRescheduleAuditEntry(
                    id: UUID(),
                    timestamp: Date(),
                    reason: .rescheduleEngine,
                    provenance: .automatic,
                    status: .executed,
                    detail: "No operations generated"
                )
            )
            LOG_UI(.info, "AutoReschedule", "No operations generated")
            return
        }
        
        // Apply all operations atomically
        await applyRescheduleOperations(operations)
        AutoRescheduleActivityCounter.shared.recordSessionsMoved(operations.count)
        
        lastRescheduleAt = Date()
        rescheduleHistory.append(contentsOf: operations)
        saveHistory()
        AutoRescheduleActivityCounter.shared.recordHistoryWritten(operations.count)
        
        // Notify user
        await notifyUserOfReschedule(operations)
        AutoRescheduleActivityCounter.shared.recordNotificationScheduled()
        
        let sameDayCount = operations.filter { $0.strategy == .sameDaySlot }.count
        let pushedCount = operations.filter { $0.strategy == .sameDayPushed }.count
        let nextDayCount = operations.filter { $0.strategy == .nextDay }.count
        let overflowCount = operations.filter { $0.strategy == .overflow }.count
        let detail = "Applied \(operations.count) ops (sameDay=\(sameDayCount), pushed=\(pushedCount), nextDay=\(nextDayCount), overflow=\(overflowCount))"
        AutoRescheduleAuditLog.shared.record(
            AutoRescheduleAuditEntry(
                id: UUID(),
                timestamp: Date(),
                reason: .rescheduleEngine,
                provenance: .automatic,
                status: .executed,
                detail: detail
            )
        )
        
        LOG_UI(.info, "AutoReschedule", "Reschedule complete: \(operations.count) operations applied")
    }
    
    // MARK: - Strategy Selection
    
    /// Analyze session and determine best rescheduling strategy
    private func rescheduleSession(_ session: StoredScheduledSession) async -> RescheduleOperation? {
        AutoRescheduleGate.debugAssertEnabled(reason: "Reschedule strategy executed while disabled")
        let now = Date()
        let calendar = Calendar.current
        let todayEnd = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now) ?? now
        
        LOG_UI(.debug, "AutoReschedule", "Analyzing session: \(session.title)")
        
        // Strategy 1: Find free slot today
        if let slot = findFreeSlot(for: session, within: now...todayEnd) {
            LOG_UI(.info, "AutoReschedule", "Strategy: Same day slot for \(session.title)")
            return RescheduleOperation(
                id: UUID(),
                sessionId: session.id,
                originalStart: session.start,
                originalEnd: session.end,
                newStart: slot.start,
                newEnd: slot.end,
                strategy: .sameDaySlot,
                pushedSessions: [],
                timestamp: now
            )
        }
        
        // Strategy 2: Push lower priority tasks today
        if settings.autoReschedulePushLowerPriority,
           let result = findSlotWithPush(for: session, within: now...todayEnd) {
            LOG_UI(.info, "AutoReschedule", "Strategy: Same day with push for \(session.title)")
            return RescheduleOperation(
                id: UUID(),
                sessionId: session.id,
                originalStart: session.start,
                originalEnd: session.end,
                newStart: result.slot.start,
                newEnd: result.slot.end,
                strategy: .sameDayPushed,
                pushedSessions: result.pushedSessionIds,
                timestamp: now
            )
        }
        
        // Strategy 3: Reschedule for tomorrow
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let tomorrowEnd = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: tomorrowStart) ?? tomorrowStart
        
        // Don't reschedule to tomorrow if it would be after the due date
        if session.dueDate >= tomorrowStart, let slot = findFreeSlot(for: session, within: tomorrowStart...tomorrowEnd) {
            LOG_UI(.info, "AutoReschedule", "Strategy: Next day for \(session.title)")
            return RescheduleOperation(
                id: UUID(),
                sessionId: session.id,
                originalStart: session.start,
                originalEnd: session.end,
                newStart: slot.start,
                newEnd: slot.end,
                strategy: .nextDay,
                pushedSessions: [],
                timestamp: now
            )
        }
        
        // Strategy 4: Move to overflow
        LOG_UI(.warn, "AutoReschedule", "Could not reschedule session \(session.title) - moving to overflow")
        return RescheduleOperation(
            id: UUID(),
            sessionId: session.id,
            originalStart: session.start,
            originalEnd: session.end,
            newStart: session.start,
            newEnd: session.end,
            strategy: .overflow,
            pushedSessions: [],
            timestamp: now
        )
    }
    
    // MARK: - Slot Finding
    
    /// Find a free time slot without pushing other sessions
    private func findFreeSlot(for session: StoredScheduledSession, within range: ClosedRange<Date>) -> TimeSlot? {
        let durationMinutes = Int(session.end.timeIntervalSince(session.start) / 60)
        let calendar = Calendar.current
        
        // Build occupancy map
        let occupiedSlots = plannerStore.scheduled
            .filter { $0.id != session.id && $0.start < range.upperBound && $0.end > range.lowerBound }
            .sorted { $0.start < $1.start }
        
        // Iterate through time in 15-minute increments
        var currentTime = range.lowerBound
        while currentTime < range.upperBound {
            let proposedEnd = calendar.date(byAdding: .minute, value: durationMinutes, to: currentTime) ?? currentTime
            
            guard proposedEnd <= range.upperBound else { break }
            
            // Check if slot is free
            let isOccupied = occupiedSlots.contains { slot in
                !(proposedEnd <= slot.start || currentTime >= slot.end)
            }
            
            if !isOccupied {
                return TimeSlot(start: currentTime, end: proposedEnd)
            }
            
            // Move to next increment
            guard let next = calendar.date(byAdding: .minute, value: 15, to: currentTime) else { break }
            currentTime = next
        }
        
        return nil
    }
    
    /// Find slot by pushing lower priority sessions
    private func findSlotWithPush(for session: StoredScheduledSession, within range: ClosedRange<Date>) -> (slot: TimeSlot, pushedSessionIds: [UUID])? {
        let durationMinutes = Int(session.end.timeIntervalSince(session.start) / 60)
        let calendar = Calendar.current
        let maxPush = settings.autoRescheduleMaxPushCount
        
        let sessionPriority = calculatePriority(session)
        
        let sessionsInRange = plannerStore.scheduled
            .filter { $0.id != session.id && $0.start < range.upperBound && $0.end > range.lowerBound }
            .sorted { $0.start < $1.start }
        
        var currentTime = range.lowerBound
        while currentTime < range.upperBound {
            let proposedEnd = calendar.date(byAdding: .minute, value: durationMinutes, to: currentTime) ?? currentTime
            
            guard proposedEnd <= range.upperBound else { break }
            
            // Find conflicts
            let conflicts = sessionsInRange.filter { existingSession in
                !(proposedEnd <= existingSession.start || currentTime >= existingSession.end)
            }
            
            // Check if we can push
            if conflicts.count <= maxPush {
                let canPushAll = conflicts.allSatisfy { conflict in
                    let conflictPriority = calculatePriority(conflict)
                    return conflictPriority < sessionPriority && !conflict.isLocked && !conflict.isUserEdited
                }
                
                if canPushAll {
                    return (
                        slot: TimeSlot(start: currentTime, end: proposedEnd),
                        pushedSessionIds: conflicts.map { $0.id }
                    )
                }
            }
            
            guard let next = calendar.date(byAdding: .minute, value: 15, to: currentTime) else { break }
            currentTime = next
        }
        
        return nil
    }
    
    // MARK: - Priority Calculation
    
    /// Calculate priority for a session (0.0-1.0, higher = more important)
    private func calculatePriority(_ session: StoredScheduledSession) -> Double {
        guard let category = session.category else { return 0.5 }
        
        // Base priority from category
        let categoryPriority: Double = {
            switch category {
            case .exam: return 1.0
            case .quiz: return 0.9
            case .project: return 0.8
            case .homework: return 0.7
            case .reading: return 0.6
            case .review: return 0.5
            }
        }()
        
        // Time urgency factor
        let now = Date()
        let daysUntilDue = Calendar.current.dateComponents([.day], from: now, to: session.dueDate).day ?? 0
        let urgencyFactor: Double = {
            if daysUntilDue <= 1 { return 1.0 }
            if daysUntilDue <= 3 { return 0.9 }
            if daysUntilDue <= 7 { return 0.7 }
            return 0.5
        }()
        
        // Locked/user-edited always max priority
        if session.isLocked || session.isUserEdited {
            return 1.0
        }
        
        // Composite priority
        return 0.6 * categoryPriority + 0.4 * urgencyFactor
    }
    
    // MARK: - Apply Operations
    
    /// Apply all rescheduling operations atomically
    private func applyRescheduleOperations(_ operations: [RescheduleOperation]) async {
        guard AutoRescheduleGate.isEnabled() else { return }
        AutoRescheduleGate.debugAssertEnabled(reason: "Planner mutation executed while disabled")
        var updatedSessions = plannerStore.scheduled
        
        for operation in operations {
            if let idx = updatedSessions.firstIndex(where: { $0.id == operation.sessionId }) {
                var session = updatedSessions[idx]
                
                if operation.strategy == .overflow {
                    // Move to overflow
                    let overflowSession = StoredOverflowSession(
                        id: session.id,
                        assignmentId: session.assignmentId,
                        sessionIndex: session.sessionIndex,
                        sessionCount: session.sessionCount,
                        title: session.title,
                        dueDate: session.dueDate,
                        estimatedMinutes: session.estimatedMinutes,
                        isLockedToDueDate: session.isLockedToDueDate,
                        category: session.category,
                        aiInputHash: session.aiInputHash,
                        aiComputedAt: session.aiComputedAt,
                        aiConfidence: session.aiConfidence,
                        aiProvenance: "auto-reschedule-overflow"
                    )
                    plannerStore.addToOverflow(overflowSession)
                    updatedSessions.remove(at: idx)
                } else {
                    // Update time
                    session = StoredScheduledSession(
                        id: session.id,
                        assignmentId: session.assignmentId,
                        sessionIndex: session.sessionIndex,
                        sessionCount: session.sessionCount,
                        title: session.title,
                        dueDate: session.dueDate,
                        estimatedMinutes: session.estimatedMinutes,
                        isLockedToDueDate: session.isLockedToDueDate,
                        category: session.category,
                        start: operation.newStart,
                        end: operation.newEnd,
                        type: session.type,
                        isLocked: session.isLocked,
                        isUserEdited: false,
                        userEditedAt: nil,
                        aiInputHash: session.aiInputHash,
                        aiComputedAt: Date(),
                        aiConfidence: session.aiConfidence,
                        aiProvenance: "auto-reschedule-\(operation.strategy.rawValue)"
                    )
                    updatedSessions[idx] = session
                }
            }
            
            // Push conflicting sessions
            if !operation.pushedSessions.isEmpty {
                for pushedId in operation.pushedSessions {
                    if let idx = updatedSessions.firstIndex(where: { $0.id == pushedId }) {
                        let pushed = updatedSessions[idx]
                        let buffer = 15 * 60.0 // 15 minute buffer
                        
                        if let newStart = Calendar.current.date(byAdding: .second, value: Int(buffer), to: operation.newEnd) {
                            let newEnd = Calendar.current.date(byAdding: .minute, value: pushed.estimatedMinutes, to: newStart) ?? newStart
                            
                            var updated = pushed
                            updated = StoredScheduledSession(
                                id: updated.id,
                                assignmentId: updated.assignmentId,
                                sessionIndex: updated.sessionIndex,
                                sessionCount: updated.sessionCount,
                                title: updated.title,
                                dueDate: updated.dueDate,
                                estimatedMinutes: updated.estimatedMinutes,
                                isLockedToDueDate: updated.isLockedToDueDate,
                                category: updated.category,
                                start: newStart,
                                end: newEnd,
                                type: updated.type,
                                isLocked: updated.isLocked,
                                isUserEdited: false,
                                userEditedAt: nil,
                                aiInputHash: updated.aiInputHash,
                                aiComputedAt: Date(),
                                aiConfidence: updated.aiConfidence,
                                aiProvenance: "auto-reschedule-pushed"
                            )
                            updatedSessions[idx] = updated
                        }
                    }
                }
            }
        }
        
        // Commit changes
        plannerStore.updateBulk(updatedSessions)
    }
    
    // MARK: - Notifications
    
    /// Notify user of rescheduling
    private func notifyUserOfReschedule(_ operations: [RescheduleOperation]) async {
        guard AutoRescheduleGate.isEnabled() else { return }
        AutoRescheduleGate.debugAssertEnabled(reason: "Notification scheduled while disabled")
        guard !operations.isEmpty else { return }
        
        // Check if notifications are enabled
        guard settings.notificationsEnabled || settings.smartNotifications else {
            LOG_UI(.debug, "AutoReschedule", "Notifications disabled, skipping user notification")
            return
        }
        
        let sameDayCount = operations.filter { $0.strategy == .sameDaySlot || $0.strategy == .sameDayPushed }.count
        let nextDayCount = operations.filter { $0.strategy == .nextDay }.count
        let overflowCount = operations.filter { $0.strategy == .overflow }.count
        
        var message = ""
        if sameDayCount > 0 {
            message += "Rescheduled \(sameDayCount) task(s) for later today. "
        }
        if nextDayCount > 0 {
            message += "Moved \(nextDayCount) task(s) to tomorrow. "
        }
        if overflowCount > 0 {
            message += "\(overflowCount) task(s) need manual scheduling."
        }
        
        await notificationManager.scheduleLocalNotification(
            title: "Schedule Updated",
            body: message,
            identifier: "auto-reschedule-\(UUID().uuidString)"
        )
    }
    
    func clearHistory() {
        rescheduleHistory.removeAll()
        saveHistory()
    }
    
    // MARK: - Persistence
    
    private var historyURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("RootsPlanner", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("reschedule-history.json")
    }
    
    private func saveHistory() {
        guard AutoRescheduleGate.isEnabled() else { return }
        AutoRescheduleGate.debugAssertEnabled(reason: "History write while disabled")
        do {
            let data = try JSONEncoder().encode(rescheduleHistory)
            try data.write(to: historyURL)
        } catch {
            LOG_UI(.error, "AutoReschedule", "Failed to save history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyURL.path) else { return }
        do {
            let data = try Data(contentsOf: historyURL)
            rescheduleHistory = try JSONDecoder().decode([RescheduleOperation].self, from: data)
        } catch {
            LOG_UI(.error, "AutoReschedule", "Failed to load history: \(error)")
        }
    }
}
