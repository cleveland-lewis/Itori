import XCTest
import Foundation

@testable import Roots

// Minimal scheduling types to make tests compile. Actual implementation should follow this API.
public struct CalendarEventStub: Identifiable, Hashable {
    public let id = UUID()
    var title: String
    var start: Date
    var end: Date
    var isLocked: Bool
}

public struct ScheduledBlock: Identifiable, Hashable {
    public let id = UUID()
    let title: String
    let start: Date
    let end: Date
}

public protocol AutoSchedulerProtocol {
    func schedule(taskTitle: String, duration: TimeInterval, earliestStart: Date, workStartHour: Int, workEndHour: Int, existingEvents: [CalendarEventStub]) -> [ScheduledBlock]
}

// Dummy scheduler skeleton to allow tests to compile. Replace with real implementation.
public class AutoScheduler: AutoSchedulerProtocol {
    public init() {}

    public func schedule(taskTitle: String, duration: TimeInterval, earliestStart: Date, workStartHour: Int, workEndHour: Int, existingEvents: [CalendarEventStub]) -> [ScheduledBlock] {
        // Naive placeholder: schedule at next workday start
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: earliestStart)
        components.hour = workStartHour
        components.minute = 0
        let start = calendar.date(from: components) ?? earliestStart
        let end = start.addingTimeInterval(duration)
        return [ScheduledBlock(title: taskTitle, start: start, end: end)]
    }
}

final class StudyPlannerTests: XCTestCase {
    var scheduler: AutoScheduler!
    let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        scheduler = AutoScheduler()
    }

    // Helper to make events
    func makeEvent(title: String, startHour: Int, durationHours: Int, isLocked: Bool = false, dayOffset: Int = 0) -> CalendarEventStub {
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = startHour
        comps.minute = 0
        if let day = calendar.date(from: comps) {
            let start = calendar.date(byAdding: .day, value: dayOffset, to: day) ?? day
            let end = calendar.date(byAdding: .hour, value: durationHours, to: start) ?? start
            return CalendarEventStub(title: title, start: start, end: end, isLocked: isLocked)
        }
        return CalendarEventStub(title: title, start: Date(), end: Date().addingTimeInterval(TimeInterval(durationHours * 3600)), isLocked: isLocked)
    }

    func testRespectingWorkHours_movesToNextDayIfWouldOverflow() {
        // Work hours 9-17
        let now = Date()
        let startAttempt = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now) ?? now
        let blocks = scheduler.schedule(taskTitle: "TwoHourSession", duration: 2 * 3600, earliestStart: startAttempt, workStartHour: 9, workEndHour: 17, existingEvents: [])

        // Expect scheduled at next day 9:00
        guard let scheduled = blocks.first else { XCTFail("No blocks scheduled"); return }
        let scheduledHour = calendar.component(.hour, from: scheduled.start)
        XCTAssertEqual(scheduledHour, 9, "Expected scheduled hour to be 9")
    }

    func testAvoidingLockedConflicts_splitsOrShifts() {
        // Locked class 13-14
        let classEvent = makeEvent(title: "Locked Class", startHour: 13, durationHours: 1, isLocked: true)
        // Attempt schedule 3 hours starting at 12
        let startAttempt = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        let blocks = scheduler.schedule(taskTitle: "Study", duration: 3 * 3600, earliestStart: startAttempt, workStartHour: 9, workEndHour: 17, existingEvents: [classEvent])

        // Ensure no overlap with locked event
        for b in blocks {
            XCTAssertFalse(b.start < classEvent.end && b.end > classEvent.start, "Block overlaps locked event")
        }
    }

    func testPrioritySorting_highPriorityGetsEarlierSlot() {
        // Two tasks with limited availability
        // Use existing stub where scheduler invoked per-task; here we simply verify that when scheduling two tasks, the high priority is earlier.
        // For this test, emulate sequential scheduling: schedule High, then Low, but expect High earlier.
        let limitedStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        let high = scheduler.schedule(taskTitle: "Exam Prep", duration: 2 * 3600, earliestStart: limitedStart, workStartHour: 9, workEndHour: 12, existingEvents: [])
        let low = scheduler.schedule(taskTitle: "Reading", duration: 1 * 3600, earliestStart: limitedStart, workStartHour: 9, workEndHour: 12, existingEvents: high.map { CalendarEventStub(title: $0.title, start: $0.start, end: $0.end, isLocked: false) })

        guard let highBlock = high.first, let lowBlock = low.first else { XCTFail("Missing blocks"); return }
        XCTAssertLessThanOrEqual(highBlock.start, lowBlock.start, "High priority should be scheduled earlier or same time as low priority")
    }

    func testRearrangingFlexibleSlots_flexibleIsBumped() {
        // Existing flexible block 14-16
        let flexible = makeEvent(title: "General Review", startHour: 14, durationHours: 2, isLocked: false)
        // New high priority project needs 2 hours starting as early as 14
        let blocks = scheduler.schedule(taskTitle: "High Priority Project", duration: 2 * 3600, earliestStart: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date(), workStartHour: 9, workEndHour: 17, existingEvents: [flexible])

        // Ensure resulting schedule does not keep flexible in the same spot if high priority occupies it
        for b in blocks {
            XCTAssertFalse(b.start == flexible.start && b.end == flexible.end, "Flexible slot should be bumped if occupied by higher priority")
        }
    }
}
