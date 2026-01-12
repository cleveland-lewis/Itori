import Foundation
import Testing
@testable import Itori

@MainActor
struct PlannerCalendarSyncTests {
    @Test func deterministicAggregation() async throws {
        let base = Date(timeIntervalSince1970: 1_735_000_000)
        let sessions = [
            makeSession(
                id: "11111111-1111-1111-1111-111111111111",
                title: "Exam 1",
                category: .exam,
                start: base,
                minutes: 60
            ),
            makeSession(
                id: "22222222-2222-2222-2222-222222222222",
                title: "Exam 2",
                category: .exam,
                start: base.addingTimeInterval(60 * 60),
                minutes: 120
            )
        ]
        let shuffled = sessions.shuffled()
        let blocksA = PlannerCalendarSync.buildBlocks(from: sessions, gapMinutes: 10)
        let blocksB = PlannerCalendarSync.buildBlocks(from: shuffled, gapMinutes: 10)
        #expect(blocksA == blocksB)
    }

    @Test func contiguityThreshold() async throws {
        let base = Date(timeIntervalSince1970: 1_735_000_000)
        let sessions = [
            makeSession(
                id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                title: "Exam 1",
                category: .exam,
                start: base,
                minutes: 60
            ),
            makeSession(
                id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                title: "Exam 2",
                category: .exam,
                start: base.addingTimeInterval(60 * 60 + 11 * 60),
                minutes: 60
            )
        ]
        let blocks = PlannerCalendarSync.buildBlocks(from: sessions, gapMinutes: 10)
        #expect(blocks.count == 2)
    }

    @Test func contiguityMergeWithinThreshold() async throws {
        let base = Date(timeIntervalSince1970: 1_735_000_000)
        let sessions = [
            makeSession(
                id: "abababab-abab-abab-abab-abababababab",
                title: "Exam 1",
                category: .exam,
                start: base,
                minutes: 60
            ),
            makeSession(
                id: "bcbcbcbc-bcbc-bcbc-bcbc-bcbcbcbcbcbc",
                title: "Exam 2",
                category: .exam,
                start: base.addingTimeInterval(60 * 60 + 10 * 60),
                minutes: 60
            )
        ]
        let blocks = PlannerCalendarSync.buildBlocks(from: sessions, gapMinutes: 10)
        #expect(blocks.count == 1)
    }

    @Test func dayKeyTimezoneStability() async throws {
        let tz = TimeZone(secondsFromGMT: -8 * 3600) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = tz
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let start = formatter.date(from: "2025-01-15 23:30")!
        let session = makeSession(
            id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
            title: "Reading",
            category: .reading,
            start: start,
            minutes: 30
        )
        let blocks = PlannerCalendarSync.buildBlocks(from: [session], gapMinutes: 10, calendar: calendar, timeZone: tz)
        #expect(blocks.first?.dayKey == "2025-01-15")
    }

    @Test func idempotentSyncPlan() async throws {
        let base = Date(timeIntervalSince1970: 1_735_000_000)
        let session = makeSession(
            id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
            title: "Review",
            category: .review,
            start: base,
            minutes: 45
        )
        let blocks = PlannerCalendarSync.buildBlocks(from: [session], gapMinutes: 10)
        let block = blocks[0]
        let event = PlannerCalendarEventSnapshot(
            identifier: "event-1",
            title: block.title,
            start: block.start,
            end: block.end,
            notes: block.notes
        )
        let plan = PlannerCalendarSync.syncPlan(
            blocks: blocks,
            existingEvents: [event],
            range: block.start ... block.end
        )
        #expect(plan.upserts.isEmpty)
        #expect(plan.deletions.isEmpty)
    }

    @Test func deletionSafetySkipsUnknownEvents() async throws {
        let base = Date(timeIntervalSince1970: 1_735_000_000)
        let session = makeSession(
            id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
            title: "Homework",
            category: .homework,
            start: base,
            minutes: 30
        )
        let blocks = PlannerCalendarSync.buildBlocks(from: [session], gapMinutes: 10)
        let foreign = PlannerCalendarEventSnapshot(
            identifier: "foreign",
            title: "Homework",
            start: base,
            end: base.addingTimeInterval(1800),
            notes: "No metadata"
        )
        let plan = PlannerCalendarSync.syncPlan(
            blocks: blocks,
            existingEvents: [foreign],
            range: base ... base.addingTimeInterval(3600)
        )
        #expect(plan.deletions.isEmpty)
    }

    @Test func deletionSafetySkipsBadMetadata() async throws {
        let base = Date(timeIntervalSince1970: 1_735_000_000)
        let session = makeSession(
            id: "ffffffff-0000-0000-0000-ffffffffffff",
            title: "Review",
            category: .review,
            start: base,
            minutes: 30
        )
        let blocks = PlannerCalendarSync.buildBlocks(from: [session], gapMinutes: 10)
        let bad = PlannerCalendarEventSnapshot(
            identifier: "bad-meta",
            title: "Review",
            start: base,
            end: base.addingTimeInterval(1800),
            notes: "[ItoriPlanner]\nblock_id: \nsource: planner\n[/ItoriPlanner]"
        )
        let plan = PlannerCalendarSync.syncPlan(
            blocks: blocks,
            existingEvents: [bad],
            range: base ... base.addingTimeInterval(3600)
        )
        #expect(plan.deletions.isEmpty)
    }

    private func makeSession(
        id: String,
        title: String,
        category: AssignmentCategory,
        start: Date,
        minutes: Int
    ) -> StoredScheduledSession {
        StoredScheduledSession(
            id: UUID(uuidString: id)!,
            assignmentId: UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff"),
            sessionIndex: 0,
            sessionCount: 1,
            title: title,
            dueDate: start,
            estimatedMinutes: minutes,
            isLockedToDueDate: false,
            category: category,
            start: start,
            end: start.addingTimeInterval(TimeInterval(minutes * 60)),
            type: .task,
            isLocked: false,
            isUserEdited: false,
            userEditedAt: nil,
            aiInputHash: nil,
            aiComputedAt: nil,
            aiConfidence: nil,
            aiProvenance: nil
        )
    }
}
