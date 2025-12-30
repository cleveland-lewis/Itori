#if canImport(XCTest)
import XCTest
@testable import Roots

final class PlannerSafetyNetTests: XCTestCase {

    func testAssignmentToSessions_examGeneratesMultipleSessions() {
        let due = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let exam = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Midterm",
            courseCode: "",
            courseName: "",
            category: .exam,
            dueDate: due,
            estimatedMinutes: 180,
            status: .notStarted,
            urgency: .high,
            weightPercent: 30,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )
        let sessions = PlannerEngine.generateSessions(for: exam, settings: StudyPlanSettings())
        XCTAssertGreaterThanOrEqual(sessions.count, 3, "Exams should be split into multiple sessions.")
        XCTAssertTrue(sessions.allSatisfy { $0.assignmentId == exam.id })
    }

    func testAssignmentToSessions_homeworkGeneratesAtLeastOneSession() {
        let due = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let hw = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Homework 1",
            courseCode: "",
            courseName: "",
            category: .homework,
            dueDate: due,
            estimatedMinutes: 60,
            status: .notStarted,
            urgency: .medium,
            weightPercent: 5,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )
        let sessions = PlannerEngine.generateSessions(for: hw, settings: StudyPlanSettings())
        XCTAssertFalse(sessions.isEmpty, "Homework should yield at least one study session.")
    }

    func testPlannerSchedulesWithinWindow() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 3, to: start)!
        let constraints = Constraints(
            horizonStart: start,
            horizonEnd: end,
            dayStartHour: 8,
            dayEndHour: 22,
            maxStudyMinutesPerDay: 360,
            maxStudyMinutesPerBlock: 120,
            minGapBetweenBlocksMinutes: 15,
            doNotScheduleWindows: [],
            energyProfile: Dictionary(uniqueKeysWithValues: (0..<24).map { ($0, 0.5) })
        )

        let task = AppTask(
            id: UUID(),
            title: "Project",
            courseId: nil,
            due: end,
            estimatedMinutes: 180,
            minBlockMinutes: 30,
            maxBlockMinutes: 120,
            difficulty: 0.5,
            importance: 0.6,
            type: .project,
            locked: false,
            attachments: [],
            isCompleted: false
        )

        let result = AIScheduler.generateSchedule(tasks: [task], fixedEvents: [], constraints: constraints, preferences: SchedulerPreferences.default())
        XCTAssertFalse(result.blocks.isEmpty, "Scheduling should produce blocks for the task.")
        XCTAssertTrue(result.blocks.allSatisfy { $0.start >= start && $0.end <= end }, "All blocks must fall within the horizon.")
    }

    @MainActor
    func testAutoRescheduleDisabledInvariant() async {
        let settings = AppSettingsModel.shared
        let original = settings.enableAutoReschedule
        settings.enableAutoReschedule = false
        AutoRescheduleActivityCounter.shared.reset()

        let plannerStore = PlannerStore.shared
        let now = Date()
        let session = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 0,
            sessionCount: 1,
            title: "Missed Session",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now,
            estimatedMinutes: 30,
            isLockedToDueDate: false,
            category: .homework,
            start: now.addingTimeInterval(-3600),
            end: now.addingTimeInterval(-1800),
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        plannerStore.updateBulk([session])

        MissedEventDetectionService.shared.triggerCheck()
        try? await Task.sleep(nanoseconds: 200_000_000)

        let counters = AutoRescheduleActivityCounter.shared.snapshot()
        XCTAssertEqual(counters.checksExecuted, 0)
        XCTAssertEqual(counters.sessionsAnalyzed, 0)
        XCTAssertEqual(counters.sessionsMoved, 0)
        XCTAssertEqual(counters.historyEntriesWritten, 0)
        XCTAssertEqual(counters.notificationsScheduled, 0)
        XCTAssertGreaterThanOrEqual(counters.suppressedExecutions, 1)

        XCTAssertEqual(plannerStore.scheduled.count, 1)
        XCTAssertTrue(plannerStore.overflow.isEmpty)

        settings.enableAutoReschedule = original
    }

    @MainActor
    func testAutoRescheduleDisabledConcurrencySuppression() async {
        let settings = AppSettingsModel.shared
        let original = settings.enableAutoReschedule
        settings.enableAutoReschedule = false
        AutoRescheduleActivityCounter.shared.reset()

        let plannerStore = PlannerStore.shared
        let now = Date()
        let session = StoredScheduledSession(
            id: UUID(),
            assignmentId: UUID(),
            sessionIndex: 0,
            sessionCount: 1,
            title: "Concurrent Missed",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now,
            estimatedMinutes: 30,
            isLockedToDueDate: false,
            category: .reading,
            start: now.addingTimeInterval(-3600),
            end: now.addingTimeInterval(-1800),
            type: .task,
            isLocked: false,
            isUserEdited: false
        )
        plannerStore.updateBulk([session])

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    MissedEventDetectionService.shared.triggerCheck()
                }
            }
            await group.waitForAll()
        }
        try? await Task.sleep(nanoseconds: 200_000_000)

        let counters = AutoRescheduleActivityCounter.shared.snapshot()
        XCTAssertEqual(counters.sessionsMoved, 0)
        XCTAssertEqual(counters.historyEntriesWritten, 0)
        XCTAssertEqual(counters.notificationsScheduled, 0)
        XCTAssertGreaterThanOrEqual(counters.suppressedExecutions, 1)
        XCTAssertEqual(plannerStore.scheduled.count, 1)

        settings.enableAutoReschedule = original
    }
}
#endif
