import XCTest
import EventKit
@testable import SharedCore

final class AutoSchedulerDiffTests: XCTestCase {
    func testAutoSchedulerProducesDeterministicDiff() {
        let store = EKEventStore()
        let calendar = Calendar(identifier: .gregorian)
        let startDate = date(2025, 1, 1, 9, 0, calendar: calendar)
        let endDate = date(2025, 1, 8, 9, 0, calendar: calendar)

        let tasks = [
            AutoScheduleTask(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                title: "Read chapter",
                estimatedDurationMinutes: 120,
                dueDate: date(2025, 1, 3, 12, 0, calendar: calendar),
                priority: 5
            ),
            AutoScheduleTask(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                title: "Draft outline",
                estimatedDurationMinutes: 90,
                dueDate: date(2025, 1, 4, 12, 0, calendar: calendar),
                priority: 4
            )
        ]

        let existingEvent = EKEvent(eventStore: store)
        existingEvent.startDate = date(2025, 1, 1, 10, 0, calendar: calendar)
        existingEvent.endDate = date(2025, 1, 1, 11, 0, calendar: calendar)

        let diff1 = AutoScheduler.generateSchedule(
            tasks: tasks,
            existingEvents: [existingEvent],
            startDate: startDate,
            daysToPlan: 7,
            workDayStart: 9,
            workDayEnd: 17
        )
        let diff2 = AutoScheduler.generateSchedule(
            tasks: tasks,
            existingEvents: [existingEvent],
            startDate: startDate,
            daysToPlan: 7,
            workDayStart: 9,
            workDayEnd: 17
        )

        XCTAssertEqual(snapshot(diff1), snapshot(diff2), "Same input should produce the same schedule diff")
        XCTAssertTrue(diff1.isIdempotent(), "Generated diff should be idempotent")
        XCTAssertTrue(diff2.isIdempotent(), "Generated diff should be idempotent")
    }

    private func snapshot(_ diff: ScheduleDiff) -> [BlockSnapshot] {
        diff.addedBlocks
            .map { BlockSnapshot(tempID: $0.tempID, title: $0.title, start: $0.startDate, duration: $0.duration) }
            .sorted { $0.tempID < $1.tempID }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

private struct BlockSnapshot: Equatable {
    let tempID: String
    let title: String
    let start: Date
    let duration: TimeInterval
}
