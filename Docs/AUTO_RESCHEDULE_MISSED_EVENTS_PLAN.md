# Auto-Reschedule Missed Events - Implementation Plan

**Feature Request**: Automatic rescheduling of tasks/events that pass their end time without completion

**Status**: 📋 Planning Phase  
**Priority**: High (User Experience Enhancement)  
**Complexity**: Medium-High  
**Estimated Effort**: 8-12 developer days

---

## Executive Summary

When a scheduled task/event passes its end time, the system should automatically detect this and attempt to reschedule it into available time slots later in the day. If no slots are available today, the system should evaluate whether to:
1. **Push other lower-priority events** to make room
2. **Reschedule for tomorrow** if pushing would be too disruptive

This creates a self-healing schedule that adapts to real-world usage patterns.

---

## Architecture Overview

### Components Involved

```
┌─────────────────────────────────────────────────────────┐
│                   User Interface Layer                   │
├─────────────────────────────────────────────────────────┤
│  - Real-time schedule display                           │
│  - Rescheduling notifications/toasts                    │
│  - Manual override controls                             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              MissedEventDetectionService                 │
├─────────────────────────────────────────────────────────┤
│  - Timer-based monitoring (every 5 minutes)             │
│  - Detect sessions with end < now && not completed      │
│  - Trigger rescheduling workflow                        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              AutoRescheduleEngine (NEW)                  │
├─────────────────────────────────────────────────────────┤
│  1. Identify missed sessions                            │
│  2. Find available slots (today first, tomorrow second) │
│  3. Evaluate slot feasibility using priority matrix     │
│  4. Apply rescheduling strategy                         │
│  5. Update PlannerStore with new schedule               │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Existing Components (Reused)                │
├─────────────────────────────────────────────────────────┤
│  - PlannerEngine (scheduling logic)                     │
│  - AIScheduler (intelligent slot finding)               │
│  - PlannerStore (persistence)                           │
│  - NotificationManager (user alerts)                    │
└─────────────────────────────────────────────────────────┘
```

---

## Detailed Design

### 1. MissedEventDetectionService

**Location**: `SharedCore/Services/FeatureServices/MissedEventDetectionService.swift`

**Responsibilities**:
- Run periodic checks (configurable interval: 5-15 minutes)
- Detect sessions where `session.end < Date()` and not marked complete
- Batch missed sessions for efficient processing
- Coordinate with AutoRescheduleEngine

**Key Methods**:
```swift
final class MissedEventDetectionService: ObservableObject {
    static let shared = MissedEventDetectionService()
    
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var lastCheckAt: Date?
    @Published private(set) var missedSessionsDetected: Int = 0
    
    private var timer: Timer?
    private let checkInterval: TimeInterval = 5 * 60 // 5 minutes
    private let plannerStore = PlannerStore.shared
    private let settings = AppSettingsModel.shared
    
    // Start monitoring (called on app launch)
    func startMonitoring() {
        guard settings.enableAutoReschedule else { return }
        stopMonitoring() // Clean up existing timer
        
        timer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForMissedSessions()
            }
        }
        isMonitoring = true
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    // Core detection logic
    private func checkForMissedSessions() async {
        lastCheckAt = Date()
        let now = Date()
        
        // Find sessions that ended but weren't completed
        let missedSessions = plannerStore.scheduled.filter { session in
            // Session ended in the past
            guard session.end < now else { return false }
            
            // Not user-edited (respect manual changes)
            guard !session.isUserEdited else { return false }
            
            // Not locked (respect fixed appointments)
            guard !session.isLocked else { return false }
            
            // Not already marked for rescheduling
            guard !session.isRescheduling else { return false }
            
            // Has valid assignment (not a break or event)
            guard session.type == .task || session.type == .study else { return false }
            
            return true
        }
        
        guard !missedSessions.isEmpty else { return }
        
        missedSessionsDetected = missedSessions.count
        LOG_UI(.info, "MissedEventDetection", "Detected \(missedSessions.count) missed sessions")
        
        // Trigger rescheduling
        await AutoRescheduleEngine.shared.reschedule(missedSessions)
    }
}
```

**Configuration Settings** (added to `AppSettingsModel`):
```swift
// Auto-reschedule settings
@AppStorage("enableAutoReschedule") var enableAutoReschedule: Bool = true
@AppStorage("autoRescheduleCheckInterval") var autoRescheduleCheckInterval: Int = 5 // minutes
@AppStorage("autoReschedulePushLowerPriority") var autoReschedulePushLowerPriority: Bool = true
@AppStorage("autoRescheduleMaxPushCount") var autoRescheduleMaxPushCount: Int = 2
@AppStorage("autoReschedulePreferSameDayThreshold") var autoReschedulePreferSameDayThreshold: Double = 0.7
```

---

### 2. AutoRescheduleEngine

**Location**: `SharedCore/Services/FeatureServices/AutoRescheduleEngine.swift`

**Responsibilities**:
- Analyze missed sessions and determine rescheduling strategy
- Find available slots using intelligent time slot analysis
- Evaluate priority conflicts and decide push vs reschedule-tomorrow
- Execute rescheduling and update all affected sessions
- Log all decisions for user review

**Core Algorithm**:

```swift
@MainActor
final class AutoRescheduleEngine: ObservableObject {
    static let shared = AutoRescheduleEngine()
    
    @Published private(set) var isRescheduling: Bool = false
    @Published private(set) var lastRescheduleAt: Date?
    @Published private(set) var rescheduleHistory: [RescheduleOperation] = []
    
    private let plannerStore = PlannerStore.shared
    private let settings = AppSettingsModel.shared
    private let notificationManager = NotificationManager.shared
    
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
        case multiDay           // Split across multiple days
        case overflow           // Could not reschedule (manual intervention needed)
    }
    
    // Main entry point
    func reschedule(_ missedSessions: [StoredScheduledSession]) async {
        guard !isRescheduling else { return }
        isRescheduling = true
        defer { isRescheduling = false }
        
        let operations: [RescheduleOperation] = []
        
        for session in missedSessions {
            if let operation = await rescheduleSession(session) {
                operations.append(operation)
            }
        }
        
        // Apply all operations atomically
        await applyRescheduleOperations(operations)
        
        lastRescheduleAt = Date()
        rescheduleHistory.append(contentsOf: operations)
        
        // Notify user
        await notifyUserOfReschedule(operations)
    }
    
    // Step 1: Analyze single session and determine best strategy
    private func rescheduleSession(_ session: StoredScheduledSession) async -> RescheduleOperation? {
        let now = Date()
        let calendar = Calendar.current
        let todayEnd = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now) ?? now
        
        // Try strategy 1: Find free slot today
        if let slot = findFreeSlot(
            for: session,
            within: now...todayEnd,
            allowPush: false
        ) {
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
        
        // Try strategy 2: Push lower priority tasks today
        if settings.autoReschedulePushLowerPriority,
           let result = findSlotWithPush(
               for: session,
               within: now...todayEnd
           ) {
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
        
        // Try strategy 3: Reschedule for tomorrow
        let tomorrowStart = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ) ?? now
        let tomorrowEnd = calendar.date(
            bySettingHour: 21,
            minute: 0,
            second: 0,
            of: tomorrowStart
        ) ?? tomorrowStart
        
        if let slot = findFreeSlot(
            for: session,
            within: tomorrowStart...tomorrowEnd,
            allowPush: false
        ) {
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
        
        // Strategy 4: Move to overflow (requires user intervention)
        LOG_UI(.warn, "AutoReschedule", "Could not reschedule session \(session.title)")
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
    
    // Step 2: Find free time slot without pushing
    private func findFreeSlot(
        for session: StoredScheduledSession,
        within range: ClosedRange<Date>,
        allowPush: Bool
    ) -> TimeSlot? {
        let durationMinutes = Int(session.end.timeIntervalSince(session.start) / 60)
        let calendar = Calendar.current
        
        // Build occupancy map for the range
        let occupiedSlots = plannerStore.scheduled
            .filter { $0.id != session.id && $0.start < range.upperBound && $0.end > range.lowerBound }
            .sorted { $0.start < $1.start }
        
        // Iterate through time in 15-minute increments
        var currentTime = range.lowerBound
        while currentTime < range.upperBound {
            let proposedEnd = calendar.date(
                byAdding: .minute,
                value: durationMinutes,
                to: currentTime
            ) ?? currentTime
            
            guard proposedEnd <= range.upperBound else { break }
            
            // Check if this slot is free
            let isOccupied = occupiedSlots.contains { slot in
                // Check for overlap
                !(proposedEnd <= slot.start || currentTime >= slot.end)
            }
            
            if !isOccupied {
                return TimeSlot(start: currentTime, end: proposedEnd)
            }
            
            // Move to next 15-minute increment
            guard let next = calendar.date(byAdding: .minute, value: 15, to: currentTime) else { break }
            currentTime = next
        }
        
        return nil
    }
    
    // Step 3: Find slot by pushing lower priority sessions
    private func findSlotWithPush(
        for session: StoredScheduledSession,
        within range: ClosedRange<Date>
    ) -> (slot: TimeSlot, pushedSessionIds: [UUID])? {
        let durationMinutes = Int(session.end.timeIntervalSince(session.start) / 60)
        let calendar = Calendar.current
        let maxPush = settings.autoRescheduleMaxPushCount
        
        // Calculate priority for the session
        let sessionPriority = calculatePriority(session)
        
        // Get all sessions in range, sorted by start time
        let sessionsInRange = plannerStore.scheduled
            .filter { $0.id != session.id && $0.start < range.upperBound && $0.end > range.lowerBound }
            .sorted { $0.start < $1.start }
        
        // Try each potential start time
        var currentTime = range.lowerBound
        while currentTime < range.upperBound {
            let proposedEnd = calendar.date(
                byAdding: .minute,
                value: durationMinutes,
                to: currentTime
            ) ?? currentTime
            
            guard proposedEnd <= range.upperBound else { break }
            
            // Find conflicting sessions
            let conflicts = sessionsInRange.filter { existingSession in
                !(proposedEnd <= existingSession.start || currentTime >= existingSession.end)
            }
            
            // Check if we can push these conflicts
            if conflicts.count <= maxPush {
                // All conflicts must be lower priority
                let canPushAll = conflicts.allSatisfy { conflict in
                    let conflictPriority = calculatePriority(conflict)
                    return conflictPriority < sessionPriority && !conflict.isLocked && !conflict.isUserEdited
                }
                
                if canPushAll {
                    // We can push these sessions
                    return (
                        slot: TimeSlot(start: currentTime, end: proposedEnd),
                        pushedSessionIds: conflicts.map { $0.id }
                    )
                }
            }
            
            // Move forward
            guard let next = calendar.date(byAdding: .minute, value: 15, to: currentTime) else { break }
            currentTime = next
        }
        
        return nil
    }
    
    // Priority calculation (0.0 - 1.0, higher = more important)
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
        
        // Locked/user-edited sessions always have max priority
        if session.isLocked || session.isUserEdited {
            return 1.0
        }
        
        // Composite priority
        return 0.6 * categoryPriority + 0.4 * urgencyFactor
    }
    
    // Step 4: Apply all rescheduling operations atomically
    private func applyRescheduleOperations(_ operations: [RescheduleOperation]) async {
        var updatedSessions = plannerStore.scheduled
        
        for operation in operations {
            // Update the rescheduled session
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
                        isUserEdited: false, // Clear user-edited flag when auto-rescheduled
                        userEditedAt: nil,
                        aiInputHash: session.aiInputHash,
                        aiComputedAt: Date(), // Mark as freshly computed
                        aiConfidence: session.aiConfidence,
                        aiProvenance: "auto-reschedule-\(operation.strategy.rawValue)"
                    )
                    updatedSessions[idx] = session
                }
            }
            
            // Push conflicting sessions if needed
            if !operation.pushedSessions.isEmpty {
                for pushedId in operation.pushedSessions {
                    if let idx = updatedSessions.firstIndex(where: { $0.id == pushedId }) {
                        // Recursively reschedule pushed sessions (they become "missed")
                        // This will cascade through the algorithm
                        let pushed = updatedSessions[idx]
                        // Add small time buffer to avoid immediate conflicts
                        let buffer = 15 * 60.0 // 15 minutes
                        if let newStart = Calendar.current.date(
                            byAdding: .second,
                            value: Int(buffer),
                            to: operation.newEnd
                        ) {
                            var updated = pushed
                            let newEnd = Calendar.current.date(
                                byAdding: .minute,
                                value: pushed.estimatedMinutes,
                                to: newStart
                            ) ?? newStart
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
        
        // Commit changes to store
        plannerStore.updateBulk(updatedSessions)
    }
    
    // Step 5: Notify user of rescheduling
    private func notifyUserOfReschedule(_ operations: [RescheduleOperation]) async {
        guard !operations.isEmpty else { return }
        
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
}

struct TimeSlot {
    let start: Date
    let end: Date
}
```

---

### 3. Data Model Extensions

**Add to `StoredScheduledSession`**:
```swift
// New fields for auto-rescheduling
var isRescheduling: Bool = false        // Flag to prevent duplicate rescheduling
var rescheduledFrom: UUID? = nil        // Track original session ID
var rescheduledAt: Date? = nil          // When it was rescheduled
var rescheduleReason: String? = nil     // Why it was rescheduled
```

**Add to `PlannerStore`**:
```swift
func addToOverflow(_ session: StoredOverflowSession) {
    overflow.append(session)
    save()
}

func updateBulk(_ sessions: [StoredScheduledSession]) {
    self.scheduled = sessions
    save()
}
```

---

### 4. UI Components

#### A. Settings Toggle (in Settings → Planner)

**Location**: `Platforms/iOS/Scenes/Settings/Categories/IOSPlannerSettingsView.swift`

```swift
Section("Auto-Reschedule") {
    Toggle("Enable Auto-Reschedule", isOn: $settings.enableAutoReschedule)
        .help("Automatically reschedule missed tasks")
    
    if settings.enableAutoReschedule {
        Toggle("Allow Pushing Lower Priority Tasks", isOn: $settings.autoReschedulePushLowerPriority)
            .help("Move lower priority tasks to make room for missed high-priority tasks")
        
        Stepper("Max Tasks to Push: \(settings.autoRescheduleMaxPushCount)", 
                value: $settings.autoRescheduleMaxPushCount, 
                in: 1...5)
        
        Stepper("Check Interval: \(settings.autoRescheduleCheckInterval) min", 
                value: $settings.autoRescheduleCheckInterval, 
                in: 1...30)
    }
}
```

#### B. Reschedule History View (new)

**Location**: `Platforms/iOS/Scenes/RescheduleHistoryView.swift`

```swift
struct RescheduleHistoryView: View {
    @StateObject private var engine = AutoRescheduleEngine.shared
    
    var body: some View {
        List(engine.rescheduleHistory) { operation in
            VStack(alignment: .leading, spacing: 4) {
                Text(operation.strategy.displayName)
                    .font(.headline)
                Text("Session: \(operation.sessionId)")
                    .font(.caption)
                HStack {
                    Text(operation.originalStart, style: .time)
                    Image(systemName: "arrow.right")
                    Text(operation.newStart, style: .time)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Reschedule History")
    }
}
```

#### C. Visual Indicators in Planner

**Add indicator for rescheduled sessions**:
```swift
// In planner cell view
if session.rescheduledFrom != nil {
    Image(systemName: "arrow.clockwise")
        .foregroundColor(.orange)
        .help("This task was automatically rescheduled")
}
```

---

## Implementation Phases

### Phase 1: Core Detection (2 days)
- [ ] Create `MissedEventDetectionService.swift`
- [ ] Implement timer-based monitoring
- [ ] Add detection logic for missed sessions
- [ ] Add configuration settings to `AppSettingsModel`
- [ ] Unit tests for detection logic

**Deliverable**: System can detect missed sessions

### Phase 2: Rescheduling Engine (3 days)
- [ ] Create `AutoRescheduleEngine.swift`
- [ ] Implement free slot finding algorithm
- [ ] Implement priority-based push logic
- [ ] Implement next-day fallback
- [ ] Add overflow handling
- [ ] Unit tests for all strategies

**Deliverable**: System can reschedule missed sessions

### Phase 3: Data Model & Persistence (1 day)
- [ ] Extend `StoredScheduledSession` with rescheduling fields
- [ ] Add bulk update methods to `PlannerStore`
- [ ] Add overflow management
- [ ] Migration for existing data

**Deliverable**: Rescheduling state persists correctly

### Phase 4: User Interface (2 days)
- [ ] Settings toggles for auto-reschedule
- [ ] Reschedule history view
- [ ] Visual indicators in planner
- [ ] Notification/toast for rescheduling events
- [ ] Manual override controls

**Deliverable**: Users can control and monitor auto-rescheduling

### Phase 5: Testing & Polish (2 days)
- [ ] Integration tests for end-to-end workflow
- [ ] Performance testing (monitor timer overhead)
- [ ] Edge case testing (timezone changes, app background)
- [ ] User acceptance testing
- [ ] Documentation

**Deliverable**: Production-ready feature

---

## Testing Strategy

### Unit Tests

```swift
// MissedEventDetectionServiceTests.swift
func testDetectsMissedSessions() {
    // Given: A session that ended 30 minutes ago
    let past = Date().addingTimeInterval(-30 * 60)
    let session = createSession(end: past)
    
    // When: Detection runs
    let missed = detector.findMissedSessions([session])
    
    // Then: Session is detected as missed
    XCTAssertEqual(missed.count, 1)
}

func testIgnoresUserEditedSessions() {
    // Given: A user-edited session that ended
    let session = createSession(end: Date().addingTimeInterval(-30 * 60), isUserEdited: true)
    
    // When: Detection runs
    let missed = detector.findMissedSessions([session])
    
    // Then: Session is not rescheduled (respects user intent)
    XCTAssertEqual(missed.count, 0)
}

// AutoRescheduleEngineTests.swift
func testFindsFreeSlotSameDay() {
    // Given: A missed session and a free slot later today
    let session = createMissedSession(duration: 60)
    let freeSlot = TimeSlot(start: Date().addingTimeInterval(2 * 3600), end: Date().addingTimeInterval(3 * 3600))
    
    // When: Rescheduling runs
    let operation = engine.rescheduleSession(session)
    
    // Then: Session is rescheduled to free slot
    XCTAssertEqual(operation?.strategy, .sameDaySlot)
}

func testPushesLowerPriorityTasks() {
    // Given: High priority missed session, low priority session in the way
    let highPriority = createMissedSession(category: .exam)
    let lowPriority = createSession(category: .reading, start: Date().addingTimeInterval(3600))
    
    // When: Rescheduling with push enabled
    let operation = engine.rescheduleSession(highPriority)
    
    // Then: Low priority task is pushed
    XCTAssertEqual(operation?.strategy, .sameDayPushed)
    XCTAssertEqual(operation?.pushedSessions.count, 1)
}

func testFallsBackToNextDay() {
    // Given: Missed session, no slots today
    let session = createMissedSession(duration: 120)
    // Fill today's schedule completely
    fillSchedule(for: Date())
    
    // When: Rescheduling runs
    let operation = engine.rescheduleSession(session)
    
    // Then: Session moves to tomorrow
    XCTAssertEqual(operation?.strategy, .nextDay)
}

func testRespectsMaxPushLimit() {
    // Given: Setting to push max 2 tasks, but 3 conflicts
    settings.autoRescheduleMaxPushCount = 2
    let session = createMissedSession(category: .exam)
    createConflicts(count: 3, category: .reading)
    
    // When: Rescheduling runs
    let operation = engine.rescheduleSession(session)
    
    // Then: Falls back to next day (can't push 3 tasks)
    XCTAssertNotEqual(operation?.strategy, .sameDayPushed)
}
```

### Integration Tests

```swift
func testEndToEndAutoReschedule() async {
    // Given: Monitoring is active, session passes end time
    detector.startMonitoring()
    let session = createSession(end: Date().addingTimeInterval(-60))
    plannerStore.persist(scheduled: [session], overflow: [])
    
    // When: Detection cycle runs
    await detector.checkForMissedSessions()
    
    // Then: Session is rescheduled
    let updated = plannerStore.scheduled.first { $0.id == session.id }
    XCTAssertNotNil(updated)
    XCTAssertNotEqual(updated?.start, session.start)
}
```

### Manual Testing Scenarios

1. **Basic Reschedule**
   - Schedule a task for 2:00 PM - 3:00 PM
   - Fast-forward system time to 3:30 PM
   - Verify task is automatically rescheduled

2. **Priority Push**
   - Schedule low-priority reading (3:00 PM)
   - Let high-priority exam (2:00 PM) pass
   - Verify exam pushes reading to later time

3. **Next Day Fallback**
   - Fill schedule completely for rest of day
   - Let a task pass its time
   - Verify it moves to tomorrow

4. **Respects User Edits**
   - User manually moves a task
   - Let it pass its time
   - Verify it is NOT auto-rescheduled

5. **Multiple Missed Tasks**
   - Let 3 tasks pass
   - Verify all 3 are rescheduled intelligently

---

## Performance Considerations

### Timer Overhead
- **Check interval**: Default 5 minutes (configurable)
- **CPU usage**: < 0.1% (runs for ~50ms every 5 minutes)
- **Battery impact**: Negligible (comparable to notification polling)

### Optimization Strategies
1. **Batch processing**: Process all missed sessions in one pass
2. **Incremental updates**: Only recalculate affected time ranges
3. **Background execution**: Use `DispatchQueue.background` for heavy computation
4. **Caching**: Cache free slot calculations for same time ranges

---

## Edge Cases & Error Handling

### Edge Cases

1. **App in background**
   - Use background tasks API to continue monitoring
   - Limit frequency to conserve battery
   - Catch up on foreground return

2. **Timezone changes**
   - Recalculate all times in current timezone
   - Don't reschedule sessions if time moves backward

3. **Due date conflicts**
   - If rescheduling would place session after due date, prioritize overflow
   - Warn user via notification

4. **Recurring sessions**
   - Only reschedule current occurrence
   - Don't affect future recurrences

5. **Cascading pushes**
   - Limit recursion depth to 3 levels
   - If cascade exceeds limit, move to next day

### Error Handling

```swift
enum RescheduleError: Error {
    case noAvailableSlots
    case exceedsPushLimit
    case afterDueDate
    case circularDependency
}

private func rescheduleSession(_ session: StoredScheduledSession) async throws -> RescheduleOperation {
    do {
        // Try rescheduling
        return try performReschedule(session)
    } catch RescheduleError.noAvailableSlots {
        LOG_UI(.warn, "AutoReschedule", "No slots available for session \(session.title)")
        return overflowOperation(for: session)
    } catch {
        LOG_UI(.error, "AutoReschedule", "Unexpected error: \(error)")
        throw error
    }
}
```

---

## User Experience Flow

### Scenario: User misses a study session

**1. Initial State** (2:00 PM)
```
User's Schedule:
├─ 2:00 PM - 3:00 PM: Math Study (High Priority)
├─ 3:30 PM - 4:30 PM: Reading Chapter 5 (Low Priority)
└─ 5:00 PM - 6:00 PM: Project Work (Medium Priority)
```

**2. User Doesn't Start Math Study** (3:00 PM)
- Session ends at 3:00 PM
- User never marked it complete
- System detects at 3:05 PM check

**3. Auto-Reschedule Evaluates** (3:05 PM)
```
Options:
✓ Push reading to 4:30 PM, schedule math at 3:30 PM (SELECTED)
✗ Schedule after project work (too late, 6:00 PM+)
✗ Move to tomorrow (prefer same-day)
```

**4. Updated Schedule** (3:05 PM)
```
User's Schedule:
├─ 3:30 PM - 4:30 PM: Math Study (rescheduled) 🔄
├─ 4:30 PM - 5:30 PM: Reading Chapter 5 (pushed) ⬆️
└─ 5:30 PM - 6:30 PM: Project Work (adjusted) ⬆️
```

**5. User Notification** (3:05 PM)
```
📱 "Math Study rescheduled to 3:30 PM
   (Reading pushed to 4:30 PM)"
```

**6. User Opens App** (3:10 PM)
- Sees updated schedule
- Orange icon 🔄 indicates rescheduled session
- Can tap for reschedule history
- Can manually override if desired

---

## Configuration & Settings

### Default Settings (Recommended)

```swift
// AppSettingsModel defaults
enableAutoReschedule = true
autoRescheduleCheckInterval = 5 // minutes
autoReschedulePushLowerPriority = true
autoRescheduleMaxPushCount = 2
autoReschedulePreferSameDayThreshold = 0.7 // 70% preference for same day
```

### Conservative Settings (Battery-Conscious)

```swift
enableAutoReschedule = true
autoRescheduleCheckInterval = 15 // minutes
autoReschedulePushLowerPriority = false
autoRescheduleMaxPushCount = 1
```

### Aggressive Settings (Maximize Same-Day Completion)

```swift
enableAutoReschedule = true
autoRescheduleCheckInterval = 3 // minutes
autoReschedulePushLowerPriority = true
autoRescheduleMaxPushCount = 5
```

---

## Dependencies

### Existing Components (Reuse)
- ✅ `PlannerEngine` - Session scheduling logic
- ✅ `AIScheduler` - Intelligent slot finding
- ✅ `PlannerStore` - State management
- ✅ `NotificationManager` - User alerts
- ✅ `AppSettingsModel` - Configuration

### New Components (Create)
- ⭐ `MissedEventDetectionService` - Detection loop
- ⭐ `AutoRescheduleEngine` - Rescheduling logic

### External Dependencies
- None (uses only Foundation + existing Itori architecture)

---

## Metrics & Monitoring

### Key Metrics to Track

```swift
struct AutoRescheduleMetrics: Codable {
    let totalDetected: Int
    let sameDayReschedules: Int
    let sameDayPushes: Int
    let nextDayReschedules: Int
    let overflowCount: Int
    let averageRescheduleTime: TimeInterval
    let userOverrides: Int // User manually changed auto-rescheduled session
}
```

### Logging Strategy

```swift
LOG_UI(.info, "AutoReschedule", "Detected \(count) missed sessions")
LOG_UI(.info, "AutoReschedule", "Rescheduled session \(id) using strategy: \(strategy)")
LOG_UI(.warn, "AutoReschedule", "Could not reschedule session \(id) - moved to overflow")
LOG_UI(.error, "AutoReschedule", "Rescheduling failed: \(error)")
```

---

## Rollout Plan

### Alpha (Internal Testing)
- Enable for developer builds only
- Manual trigger via debug menu
- Collect crash logs and performance data

### Beta (TestFlight)
- Enable by default with opt-out
- Add telemetry to measure usage patterns
- Gather user feedback via in-app survey

### Production (App Store)
- Gradual rollout: 10% → 50% → 100%
- Monitor crash rates and battery impact
- A/B test different check intervals

---

## Future Enhancements

### Phase 2 Features (After Initial Release)

1. **Smart Prediction**
   - Learn user patterns (often misses morning sessions)
   - Proactively suggest schedule adjustments

2. **Context Awareness**
   - Integrate with calendar events (meetings, appointments)
   - Consider location (don't schedule at home during commute time)

3. **Multi-Day Optimization**
   - Reschedule across entire week, not just today/tomorrow
   - Balance workload distribution

4. **Collaborative Rescheduling**
   - If multiple users on same calendar, coordinate rescheduling
   - Suggest group study sessions

5. **Manual Undo**
   - Allow user to revert auto-reschedule
   - Learn from user corrections

---

## Risk Assessment

### High Risk
- **Battery drain** from timer
  - Mitigation: Configurable interval, optimize algorithm
  
### Medium Risk
- **User confusion** from automatic changes
  - Mitigation: Clear notifications, undo capability, visual indicators

### Low Risk
- **Cascading reschedules** creating schedule chaos
  - Mitigation: Limit recursion depth, overflow threshold

---

## Success Criteria

### Functionality
- ✅ Detects 100% of missed sessions within check interval
- ✅ Reschedules 80%+ to same day when slots available
- ✅ Respects user-edited sessions
- ✅ No crashes or data loss

### Performance
- ✅ Check completes in < 100ms
- ✅ Rescheduling completes in < 500ms
- ✅ Battery impact < 1% per day

### User Experience
- ✅ 70%+ users keep feature enabled
- ✅ < 5% manual overrides (indicates good automatic decisions)
- ✅ Positive feedback on post-release survey

---

## Documentation

### User-Facing Documentation

**Help Article: Auto-Reschedule**
```markdown
# Auto-Reschedule

Itori can automatically reschedule tasks you miss, keeping your schedule up-to-date.

## How It Works
When you don't complete a task by its scheduled end time, Itori will:
1. Try to find a free slot later today
2. Push lower-priority tasks if needed
3. Move to tomorrow if today is full

## Settings
- **Enable Auto-Reschedule**: Turn the feature on/off
- **Allow Pushing**: Let Itori move lower-priority tasks
- **Max Tasks to Push**: Limit how many tasks can be moved
- **Check Interval**: How often Itori checks for missed tasks

## Visual Indicators
- 🔄 icon means task was auto-rescheduled
- View full history in Settings → Planner → Reschedule History
```

### Developer Documentation

```swift
/// Auto-Reschedule Architecture
///
/// **Detection**: `MissedEventDetectionService` runs every N minutes
/// - Identifies sessions where `end < now` and not completed
/// - Filters out user-edited and locked sessions
/// - Batches missed sessions for processing
///
/// **Rescheduling**: `AutoRescheduleEngine` applies strategies
/// 1. Find free slot same day
/// 2. Push lower-priority tasks (if enabled)
/// 3. Reschedule to tomorrow
/// 4. Move to overflow (manual intervention)
///
/// **Priority Calculation**:
/// - Category weight (exam > quiz > homework > reading > review)
/// - Time urgency (days until due date)
/// - User edits always max priority
///
/// **Atomicity**: All operations applied in single transaction
///
/// **Observability**: Comprehensive logging and metrics
```

---

## Files to Create

```
SharedCore/Services/FeatureServices/
├── MissedEventDetectionService.swift       (NEW, 300 lines)
└── AutoRescheduleEngine.swift              (NEW, 800 lines)

Platforms/iOS/Scenes/Settings/
└── RescheduleHistoryView.swift             (NEW, 150 lines)

Tests/Unit/SharedCore/
├── MissedEventDetectionServiceTests.swift  (NEW, 400 lines)
└── AutoRescheduleEngineTests.swift         (NEW, 600 lines)

Docs/
└── AUTO_RESCHEDULE_ARCHITECTURE.md         (NEW, this file)
```

## Files to Modify

```
SharedCore/State/AppSettingsModel.swift
  + Add auto-reschedule settings

SharedCore/Models/PlannerModels.swift
  + Add rescheduling fields to StoredScheduledSession

SharedCore/State/PlannerStore.swift
  + Add bulk update method
  + Add overflow management

Platforms/iOS/Root/IOSAppShell.swift
  + Start monitoring on app launch

Platforms/iOS/Scenes/Settings/Categories/IOSPlannerSettingsView.swift
  + Add auto-reschedule settings section
```

---

## Timeline

**Estimated Total**: 10-12 developer days

| Phase | Duration | Owner | Status |
|-------|----------|-------|--------|
| Planning & Design | 1 day | Lead Dev | ✅ Complete |
| Phase 1: Detection | 2 days | Dev 1 | 📋 Planned |
| Phase 2: Engine | 3 days | Dev 1 | 📋 Planned |
| Phase 3: Data Model | 1 day | Dev 2 | 📋 Planned |
| Phase 4: UI | 2 days | Dev 2 | 📋 Planned |
| Phase 5: Testing | 2 days | QA + Dev | 📋 Planned |
| Code Review | 0.5 days | Team | 📋 Planned |
| Bug Fixes | 0.5 days | Dev 1 | 📋 Planned |

**Target Release**: Sprint 23 (2 weeks from start)

---

## Conclusion

This implementation plan provides a comprehensive, production-ready approach to auto-rescheduling missed events. The design leverages existing Itori architecture (PlannerEngine, AIScheduler, PlannerStore) while adding two focused new components for detection and rescheduling logic.

Key strengths:
- ✅ **Minimal changes** to existing code
- ✅ **Testable** with comprehensive unit/integration tests
- ✅ **Performant** with configurable monitoring intervals
- ✅ **User-friendly** with clear notifications and controls
- ✅ **Scalable** to future enhancements (ML, multi-day, etc.)

The feature will significantly improve user experience by creating a "self-healing" schedule that adapts to real-world usage patterns.

---

**Next Steps**:
1. Review this plan with team
2. Create GitHub issues for each phase
3. Set up feature flag for gradual rollout
4. Begin Phase 1 implementation

**Questions/Feedback**: [Create GitHub issue with label `enhancement/auto-reschedule`]
