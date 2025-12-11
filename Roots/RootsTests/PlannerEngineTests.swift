import XCTest
@testable import Roots

final class PlannerEngineTests: XCTestCase {
    private let calendar = Calendar.current

    // MARK: Session generation

    func testExamGeneratesAtLeastThreeSessions() {
        let due = calendar.date(byAdding: .day, value: 5, to: referenceDate)!
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Biology Final",
            courseCode: "",
            courseName: "",
            category: .exam,
            dueDate: due,
            estimatedMinutes: 240,
            status: .notStarted,
            urgency: .high,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )

        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        XCTAssertGreaterThanOrEqual(sessions.count, 3)
        XCTAssertEqual(Set(sessions.map { $0.sessionIndex }).count, sessions.count)
    }

    func testQuizGeneratesMaxTwoSessions() {
        let due = calendar.date(byAdding: .day, value: 3, to: referenceDate)!
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Quiz 1",
            courseCode: "",
            courseName: "",
            category: .quiz,
            dueDate: due,
            estimatedMinutes: 120,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )

        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        XCTAssertLessThanOrEqual(sessions.count, 2)
    }

    func testHomeworkSplitsWhenLong() {
        let due = calendar.date(byAdding: .day, value: 2, to: referenceDate)!
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Problem Set",
            courseCode: "",
            courseName: "",
            category: .practiceHomework,
            dueDate: due,
            estimatedMinutes: 120,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )

        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        XCTAssertGreaterThan(sessions.count, 1)
        XCTAssertEqual(sessions.first?.sessionCount, sessions.count)
    }

    func testProjectUsesCustomPlanWhenProvided() {
        let due = calendar.date(byAdding: .day, value: 7, to: referenceDate)!
        let steps = [
            PlanStep(id: UUID(), title: "Outline", targetDate: nil, expectedMinutes: 60, notes: nil),
            PlanStep(id: UUID(), title: "Draft", targetDate: nil, expectedMinutes: 90, notes: nil)
        ]
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Term Paper",
            courseCode: "",
            courseName: "",
            category: .project,
            dueDate: due,
            estimatedMinutes: 150,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: steps
        )

        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        XCTAssertEqual(sessions.count, steps.count)
        XCTAssertTrue(sessions.allSatisfy { $0.title.contains("Outline") || $0.title.contains("Draft") })
    }

    // MARK: Scheduling

    func testSchedulesWithoutCollisionAndDeterministicOrder() {
        let due = calendar.date(byAdding: .day, value: 1, to: referenceDate)!
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Reading",
            courseCode: "",
            courseName: "",
            category: .reading,
            dueDate: due,
            estimatedMinutes: 60,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let energy: [Int: Double] = [:] // default 0.5
        let result = PlannerEngine.scheduleSessions(sessions, settings: StudyPlanSettings(), energyProfile: energy)
        XCTAssertEqual(result.scheduled.count, sessions.count)

        let starts = result.scheduled.map { $0.start }.sorted()
        XCTAssertEqual(starts, result.scheduled.map { $0.start }, "Scheduling should be deterministic for equal scores.")
    }

    func testOverflowWhenTimeInsufficient() {
        let due = referenceDate
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Crash Study",
            courseCode: "",
            courseName: "",
            category: .exam,
            dueDate: due,
            estimatedMinutes: 600, // 10 hours, only 12 slots available in one day
            status: .notStarted,
            urgency: .critical,
            weightPercent: nil,
            isLockedToDueDate: true,
            notes: "",
            plan: []
        )
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let result = PlannerEngine.scheduleSessions(sessions, settings: StudyPlanSettings(), energyProfile: [:])
        XCTAssertFalse(result.overflow.isEmpty, "Expect overflow when the window is too tight.")
    }

    func testInvalidWindowFallsBackToOverflow() {
        // Due date in the past with lock should yield invalid window and overflow.
        let pastDue = calendar.date(byAdding: .day, value: -1, to: referenceDate)!
        let assignment = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Past Due",
            courseCode: "",
            courseName: "",
            category: .reading,
            dueDate: pastDue,
            estimatedMinutes: 60,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: true,
            notes: "",
            plan: []
        )
        let sessions = PlannerEngine.generateSessions(for: assignment, settings: StudyPlanSettings())
        let result = PlannerEngine.scheduleSessions(sessions, settings: StudyPlanSettings(), energyProfile: [:])
        XCTAssertEqual(result.scheduled.count, 0)
        XCTAssertEqual(result.overflow.count, sessions.count)
    }

    func testReschedulesWhenDueDateChanges() {
        let originalDue = calendar.date(byAdding: .day, value: 5, to: referenceDate)!
        let earlierDue = calendar.date(byAdding: .day, value: 2, to: referenceDate)!
        let assignmentOriginal = Assignment(
            id: UUID(),
            courseId: nil,
            title: "Project",
            courseCode: "",
            courseName: "",
            category: .project,
            dueDate: originalDue,
            estimatedMinutes: 180,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )
        let assignmentEarlier = Assignment(
            id: assignmentOriginal.id,
            courseId: nil,
            title: "Project",
            courseCode: "",
            courseName: "",
            category: .project,
            dueDate: earlierDue,
            estimatedMinutes: 180,
            status: .notStarted,
            urgency: .medium,
            weightPercent: nil,
            isLockedToDueDate: false,
            notes: "",
            plan: []
        )

        let sessionsOriginal = PlannerEngine.generateSessions(for: assignmentOriginal, settings: StudyPlanSettings())
        let sessionsEarlier = PlannerEngine.generateSessions(for: assignmentEarlier, settings: StudyPlanSettings())

        let resultOriginal = PlannerEngine.scheduleSessions(sessionsOriginal, settings: StudyPlanSettings(), energyProfile: [:])
        let resultEarlier = PlannerEngine.scheduleSessions(sessionsEarlier, settings: StudyPlanSettings(), energyProfile: [:])

        let latestOriginal = resultOriginal.scheduled.map { $0.start }.max() ?? referenceDate
        let latestEarlier = resultEarlier.scheduled.map { $0.start }.max() ?? referenceDate

        XCTAssertTrue(latestEarlier <= latestOriginal, "Rescheduled earlier due date should not push tasks later.")
    }

    private var referenceDate: Date {
        let comps = DateComponents(calendar: calendar, year: 2025, month: 12, day: 10, hour: 9, minute: 0)
        return comps.date ?? Date()
    }
}
