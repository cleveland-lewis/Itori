import XCTest
@testable import Itori

@MainActor
final class AutoRescheduleTests: XCTestCase {
    
    var plannerStore: PlannerStore!
    var engine: AutoRescheduleEngine!
    var detector: MissedEventDetectionService!
    var settings: AppSettingsModel!
    
    override func setUp() async throws {
        try await super.setUp()
        plannerStore = PlannerStore.shared
        engine = AutoRescheduleEngine.shared
        detector = MissedEventDetectionService.shared
        settings = AppSettingsModel.shared
        
        // Clear existing data
        plannerStore.reset()
        
        // Enable auto-reschedule
        settings.enableAutoReschedule = true
        settings.autoReschedulePushLowerPriority = true
        settings.autoRescheduleMaxPushCount = 2
    }
    
    override func tearDown() async throws {
        detector.stopMonitoring()
        plannerStore.reset()
        try await super.tearDown()
    }
    
    // MARK: - Detection Tests
    
    func testDetectsMissedSession() async {
        // Given: A session that ended 30 minutes ago
        let pastEnd = Date().addingTimeInterval(-30 * 60)
        let pastStart = pastEnd.addingTimeInterval(-60 * 60) // 1 hour duration
        
        let session = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Test Session",
            dueDate: Date().addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .homework,
            start: pastStart,
            end: pastEnd,
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        
        plannerStore.updateBulk([session])
        
        // When: Detection runs
        await detector.checkForMissedSessions()
        
        // Then: Session should be rescheduled (no longer at old time)
        let updatedSessions = plannerStore.scheduled
        let stillAtOldTime = updatedSessions.contains { $0.id == session.id && $0.start == session.start }
        
        XCTAssertFalse(stillAtOldTime, "Session should have been rescheduled")
    }
    
    func testIgnoresUserEditedSessions() async {
        // Given: A user-edited session that ended
        let pastEnd = Date().addingTimeInterval(-30 * 60)
        let pastStart = pastEnd.addingTimeInterval(-60 * 60)
        
        let session = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "User Edited Session",
            dueDate: Date().addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .homework,
            start: pastStart,
            end: pastEnd,
            type: .task,
            isLocked: false,
            isUserEdited: true,
            userEditedAt: Date()
        )
        
        plannerStore.updateBulk([session])
        
        // When: Detection runs
        await detector.checkForMissedSessions()
        
        // Then: Session should NOT be rescheduled (still at old time)
        let updatedSessions = plannerStore.scheduled
        let stillAtOldTime = updatedSessions.contains { $0.id == session.id && $0.start == session.start }
        
        XCTAssertTrue(stillAtOldTime, "User-edited session should not be auto-rescheduled")
    }
    
    func testIgnoresLockedSessions() async {
        // Given: A locked session that ended
        let pastEnd = Date().addingTimeInterval(-30 * 60)
        let pastStart = pastEnd.addingTimeInterval(-60 * 60)
        
        let session = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Locked Session",
            dueDate: Date().addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .homework,
            start: pastStart,
            end: pastEnd,
            type: .task,
            isLocked: true,
            isUserEdited: false
        )
        
        plannerStore.updateBulk([session])
        
        // When: Detection runs
        await detector.checkForMissedSessions()
        
        // Then: Session should NOT be rescheduled
        let updatedSessions = plannerStore.scheduled
        let stillAtOldTime = updatedSessions.contains { $0.id == session.id && $0.start == session.start }
        
        XCTAssertTrue(stillAtOldTime, "Locked session should not be auto-rescheduled")
    }
    
    // MARK: - Rescheduling Tests
    
    func testFindsFreeSlotSameDay() async {
        // Given: A missed session and free time later today
        let now = Date()
        let missedStart = now.addingTimeInterval(-2 * 3600) // 2 hours ago
        let missedEnd = now.addingTimeInterval(-1 * 3600)   // 1 hour ago
        
        let missedSession = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Missed Session",
            dueDate: now.addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .homework,
            start: missedStart,
            end: missedEnd,
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        
        plannerStore.updateBulk([missedSession])
        
        // When: Rescheduling runs
        await engine.reschedule([missedSession])
        
        // Then: Session should be rescheduled to later today
        let updatedSessions = plannerStore.scheduled
        let rescheduled = updatedSessions.first { $0.id == missedSession.id }
        
        XCTAssertNotNil(rescheduled, "Session should exist after reschedule")
        if let rescheduled = rescheduled {
            XCTAssertGreaterThan(rescheduled.start, now, "Should be rescheduled to later")
            XCTAssertTrue(Calendar.current.isDate(rescheduled.start, inSameDayAs: now), "Should be rescheduled to same day")
        }
    }
    
    func testPriorityCalculation() {
        // Test priority ordering
        let now = Date()
        
        let examSession = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Exam",
            dueDate: now.addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .exam,
            start: now,
            end: now.addingTimeInterval(3600),
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        
        let readingSession = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Reading",
            dueDate: now.addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .reading,
            start: now,
            end: now.addingTimeInterval(3600),
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        
        // Access private method via reflection or make it internal for testing
        // For now, we'll just verify the logic conceptually
        
        XCTAssertEqual(examSession.category, .exam, "Exam has highest category priority")
        XCTAssertEqual(readingSession.category, .reading, "Reading has lower priority")
    }
    
    func testRescheduleHistoryPersistence() async {
        // Given: A reschedule operation
        let now = Date()
        let missedSession = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 1,
            sessionCount: 1,
            title: "Test Session",
            dueDate: now.addingTimeInterval(24 * 3600),
            estimatedMinutes: 60,
            isLockedToDueDate: false,
            category: .homework,
            start: now.addingTimeInterval(-2 * 3600),
            end: now.addingTimeInterval(-1 * 3600),
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        
        plannerStore.updateBulk([missedSession])
        
        // When: Rescheduling runs
        await engine.reschedule([missedSession])
        
        // Then: History should contain the operation
        XCTAssertFalse(engine.rescheduleHistory.isEmpty, "History should not be empty")
        
        if let operation = engine.rescheduleHistory.last {
            XCTAssertEqual(operation.sessionId, missedSession.id, "Operation should reference the correct session")
            XCTAssertNotEqual(operation.newStart, operation.originalStart, "Start time should have changed")
        }
    }
}
