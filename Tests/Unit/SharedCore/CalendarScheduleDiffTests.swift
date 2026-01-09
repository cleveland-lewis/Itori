import EventKit
import XCTest
@testable import SharedCore

@MainActor
final class CalendarScheduleDiffTests: XCTestCase {
    func testRelaunchSimulationProducesNoDuplicateBlocks() {
        let store = EKEventStore()
        let calendar = Calendar(identifier: .gregorian)
        let startDate = date(2025, 1, 1, 9, 0, calendar: calendar)
        let endDate = date(2025, 1, 3, 9, 0, calendar: calendar)

        let tasks = [
            AutoScheduleTask(
                id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                title: "Problem Set",
                estimatedDurationMinutes: 120,
                dueDate: date(2025, 1, 2, 12, 0, calendar: calendar),
                priority: 8
            )
        ]

        let proposed = AutoScheduler.generateSchedule(
            tasks: tasks,
            existingEvents: [],
            startDate: startDate,
            daysToPlan: 3,
            workDayStart: 9,
            workDayEnd: 17
        )

        let existing = proposed.addedBlocks.map { block in
            let event = EKEvent(eventStore: store)
            event.startDate = block.startDate
            event.endDate = block.startDate.addingTimeInterval(block.duration)
            event.notes = block.tempID
            return event
        }

        let diff = CalendarRefreshCoordinator.shared.buildScheduleDiff(
            proposed: proposed,
            existingEvents: existing,
            within: startDate ... endDate
        )

        XCTAssertTrue(diff.addedBlocks.isEmpty)
        XCTAssertTrue(diff.movedBlocks.isEmpty)
        XCTAssertTrue(diff.resizedBlocks.isEmpty)
        XCTAssertTrue(diff.conflicts.isEmpty)
    }

    func testPendingSuggestionIsNotOverwritten() {
        let coordinator = CalendarRefreshCoordinator.shared
        coordinator.discardPendingScheduleSuggestion()

        let now = Date()
        let suggestionA = PendingScheduleSuggestion(
            id: UUID(),
            diff: ScheduleDiff(reason: "test", confidence: AIConfidence(0.7)),
            inputHash: "hashA",
            createdAt: now,
            featureStateVersion: 0,
            summaryText: "test",
            targetCalendarID: "calendarA",
            range: now ... now.addingTimeInterval(3600)
        )

        let suggestionB = PendingScheduleSuggestion(
            id: UUID(),
            diff: ScheduleDiff(reason: "test", confidence: AIConfidence(0.9)),
            inputHash: "hashB",
            createdAt: now,
            featureStateVersion: 0,
            summaryText: "test",
            targetCalendarID: "calendarB",
            range: now ... now.addingTimeInterval(7200)
        )

        XCTAssertTrue(coordinator.stageSuggestion(suggestionA))
        XCTAssertFalse(coordinator.stageSuggestion(suggestionB))
    }

    func testApplyingSameDiffTwiceProducesNoChanges() {
        let store = EKEventStore()
        let calendar = Calendar(identifier: .gregorian)
        let startDate = date(2025, 2, 1, 9, 0, calendar: calendar)
        let endDate = date(2025, 2, 2, 9, 0, calendar: calendar)

        let tasks = [
            AutoScheduleTask(
                id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
                title: "Lab writeup",
                estimatedDurationMinutes: 60,
                dueDate: date(2025, 2, 1, 18, 0, calendar: calendar),
                priority: 6
            )
        ]

        let proposed = AutoScheduler.generateSchedule(
            tasks: tasks,
            existingEvents: [],
            startDate: startDate,
            daysToPlan: 1,
            workDayStart: 9,
            workDayEnd: 17
        )

        let appliedEvents = proposed.addedBlocks.map { block in
            let event = EKEvent(eventStore: store)
            event.startDate = block.startDate
            event.endDate = block.startDate.addingTimeInterval(block.duration)
            event.notes = block.tempID
            return event
        }

        let firstDiff = CalendarRefreshCoordinator.shared.buildScheduleDiff(
            proposed: proposed,
            existingEvents: appliedEvents,
            within: startDate ... endDate
        )
        let secondDiff = CalendarRefreshCoordinator.shared.buildScheduleDiff(
            proposed: proposed,
            existingEvents: appliedEvents,
            within: startDate ... endDate
        )

        XCTAssertEqual(firstDiff.changeCount, 0)
        XCTAssertEqual(secondDiff.changeCount, 0)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
