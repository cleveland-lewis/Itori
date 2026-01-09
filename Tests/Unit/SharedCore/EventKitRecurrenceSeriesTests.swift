import EventKit
import XCTest
@testable import SharedCore

/// Advanced tests for recurring event series operations
/// Tests complex scenarios including:
/// - Modifying single occurrences within a series
/// - Exception handling for edited occurrences
/// - Series boundary conditions
/// - Detached events from modified series
final class EventKitRecurrenceSeriesTests: XCTestCase {
    var fakeStore: RecurringEventStore!
    var seriesManager: RecurrenceSeriesManager!

    override func setUp() {
        super.setUp()
        fakeStore = RecurringEventStore()
        seriesManager = RecurrenceSeriesManager(store: fakeStore)
    }

    override func tearDown() {
        seriesManager = nil
        fakeStore = nil
        super.tearDown()
    }

    // MARK: - Modify Single Occurrence Tests

    func testEditSingleOccurrenceCreatesDetachedEvent() async throws {
        // Given: A weekly recurring series
        let series = fakeStore.createWeeklySeries(
            title: "Weekly Meeting",
            start: Date(),
            occurrences: 10
        )
        let secondOccurrence = series.occurrences[1]

        // When: Editing only the second occurrence
        try await seriesManager.editOccurrence(
            seriesID: series.identifier,
            occurrenceDate: secondOccurrence.start,
            newTitle: "Special Meeting"
        )

        // Then: A detached event is created for that occurrence
        let detached = fakeStore.getDetachedEvent(
            seriesID: series.identifier,
            originalDate: secondOccurrence.start
        )
        XCTAssertNotNil(detached)
        XCTAssertEqual(detached?.title, "Special Meeting")

        // And: Original series remains unchanged
        let originalSeries = fakeStore.getSeries(identifier: series.identifier)
        XCTAssertEqual(originalSeries?.title, "Weekly Meeting")
    }

    func testDeleteSingleOccurrenceAddsExceptionDate() async throws {
        // Given: A daily recurring series with 7 occurrences
        let series = fakeStore.createDailySeries(
            title: "Daily Task",
            start: Date(),
            occurrences: 7
        )
        let thirdOccurrence = series.occurrences[2]

        // When: Deleting the third occurrence only
        try await seriesManager.deleteOccurrence(
            seriesID: series.identifier,
            occurrenceDate: thirdOccurrence.start,
            span: .thisEvent
        )

        // Then: Exception date is added to series
        let updated = fakeStore.getSeries(identifier: series.identifier)
        XCTAssertTrue(updated?.exceptionDates.contains(thirdOccurrence.start) ?? false)

        // And: Series still exists
        XCTAssertNotNil(updated)

        // And: Only that occurrence is removed
        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: series.occurrences[0].start,
            to: series.occurrences[6].end
        )
        XCTAssertEqual(occurrences.count, 6, "Should have 6 occurrences after deleting one")
    }

    func testDeleteFutureEventsModifiesSeriesEnd() async throws {
        // Given: A series with 10 weekly occurrences
        let series = fakeStore.createWeeklySeries(
            title: "Weekly Task",
            start: Date(),
            occurrences: 10
        )
        let fifthOccurrence = series.occurrences[4]

        // When: Deleting from the fifth occurrence onward
        try await seriesManager.deleteOccurrence(
            seriesID: series.identifier,
            occurrenceDate: fifthOccurrence.start,
            span: .futureEvents
        )

        // Then: Series end date is updated to the fourth occurrence
        let updated = fakeStore.getSeries(identifier: series.identifier)
        let fourthOccurrenceEnd = series.occurrences[3].end
        XCTAssertNotNil(updated?.recurrenceEnd)

        // And: Only first 4 occurrences remain
        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: series.occurrences[0].start,
            to: series.occurrences[9].end
        )
        XCTAssertEqual(occurrences.count, 4)
    }

    // MARK: - Series Boundary Tests

    func testSeriesWithNoEndDate() async throws {
        // Given: An infinite daily series (no end date)
        let series = fakeStore.createInfiniteSeries(
            title: "Infinite Task",
            start: Date(),
            frequency: .daily
        )

        // When: Fetching occurrences within a specific window
        let windowStart = Date()
        let windowEnd = Calendar.current.date(byAdding: .day, value: 30, to: windowStart)!

        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: windowStart,
            to: windowEnd
        )

        // Then: Only occurrences within the window are returned
        XCTAssertEqual(occurrences.count, 30, "Should return 30 daily occurrences")

        // And: All occurrences are within the window
        for occurrence in occurrences {
            XCTAssertTrue(occurrence.start >= windowStart)
            XCTAssertTrue(occurrence.end <= windowEnd)
        }
    }

    func testSeriesWithOccurrenceCountEnd() async throws {
        // Given: A series ending after exactly 5 occurrences
        let series = fakeStore.createWeeklySeries(
            title: "5-Week Course",
            start: Date(),
            occurrences: 5
        )

        // When: Fetching all occurrences
        let windowStart = series.occurrences[0].start
        let windowEnd = Calendar.current.date(byAdding: .month, value: 3, to: windowStart)!

        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: windowStart,
            to: windowEnd
        )

        // Then: Exactly 5 occurrences are returned
        XCTAssertEqual(occurrences.count, 5)
    }

    func testSeriesWithEndDate() async throws {
        // Given: A series ending on a specific date
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 2, to: startDate)!

        let series = fakeStore.createSeriesWithEndDate(
            title: "2-Month Project",
            start: startDate,
            end: endDate,
            frequency: .weekly
        )

        // When: Fetching occurrences beyond the end date
        let queryEnd = Calendar.current.date(byAdding: .month, value: 6, to: startDate)!

        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: startDate,
            to: queryEnd
        )

        // Then: Only occurrences before end date are returned
        XCTAssertTrue(occurrences.allSatisfy { $0.start <= endDate })
        XCTAssertEqual(occurrences.count, 8, "Should have ~8 weekly occurrences in 2 months")
    }

    // MARK: - Exception Handling Tests

    func testMultipleExceptionDatesInSeries() async throws {
        // Given: A daily series
        let series = fakeStore.createDailySeries(
            title: "Daily Standup",
            start: Date(),
            occurrences: 14
        )

        // When: Deleting multiple specific occurrences
        let datesToDelete = [
            series.occurrences[2].start, // Day 3
            series.occurrences[5].start, // Day 6
            series.occurrences[9].start // Day 10
        ]

        for date in datesToDelete {
            try await seriesManager.deleteOccurrence(
                seriesID: series.identifier,
                occurrenceDate: date,
                span: .thisEvent
            )
        }

        // Then: All exception dates are recorded
        let updated = fakeStore.getSeries(identifier: series.identifier)
        for date in datesToDelete {
            XCTAssertTrue(updated?.exceptionDates.contains(date) ?? false)
        }

        // And: Total occurrences is reduced by 3
        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: series.occurrences[0].start,
            to: series.occurrences[13].end
        )
        XCTAssertEqual(occurrences.count, 11, "Should have 11 occurrences (14 - 3)")
    }

    func testEditedOccurrenceWithDifferentTime() async throws {
        // Given: A series at 10:00 AM daily
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!

        let series = fakeStore.createDailySeries(
            title: "Morning Task",
            start: start,
            occurrences: 5
        )
        let secondOccurrence = series.occurrences[1]

        // When: Editing the second occurrence to 2:00 PM
        let newStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: secondOccurrence.start)!
        let newEnd = calendar.date(byAdding: .hour, value: 1, to: newStart)!

        try await seriesManager.editOccurrence(
            seriesID: series.identifier,
            occurrenceDate: secondOccurrence.start,
            newStart: newStart,
            newEnd: newEnd
        )

        // Then: A detached event is created with the new time
        let detached = fakeStore.getDetachedEvent(
            seriesID: series.identifier,
            originalDate: secondOccurrence.start
        )
        XCTAssertNotNil(detached)
        XCTAssertEqual(detached?.start, newStart)
        XCTAssertEqual(detached?.end, newEnd)

        // And: Original series maintains 10:00 AM for other occurrences
        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: series.occurrences[0].start,
            to: series.occurrences[4].end
        )
        let uneditedOccurrences = occurrences.filter {
            !calendar.isDate($0.start, inSameDayAs: secondOccurrence.start)
        }
        XCTAssertTrue(uneditedOccurrences.allSatisfy {
            calendar.component(.hour, from: $0.start) == 10
        })
    }

    // MARK: - Detached Event Tests

    func testDetachedEventDoesNotAffectOriginalSeries() async throws {
        // Given: A series with a detached occurrence
        let series = fakeStore.createWeeklySeries(
            title: "Team Meeting",
            start: Date(),
            occurrences: 8
        )
        let thirdOccurrence = series.occurrences[2]

        try await seriesManager.editOccurrence(
            seriesID: series.identifier,
            occurrenceDate: thirdOccurrence.start,
            newTitle: "Special Team Meeting"
        )

        // When: Editing the original series
        try await seriesManager.editSeries(
            seriesID: series.identifier,
            newTitle: "Updated Team Meeting"
        )

        // Then: Detached event keeps its custom title
        let detached = fakeStore.getDetachedEvent(
            seriesID: series.identifier,
            originalDate: thirdOccurrence.start
        )
        XCTAssertEqual(detached?.title, "Special Team Meeting")

        // And: Other occurrences get the new title
        let updated = fakeStore.getSeries(identifier: series.identifier)
        XCTAssertEqual(updated?.title, "Updated Team Meeting")
    }

    func testDeletingSeriesRemovesDetachedEvents() async throws {
        // Given: A series with multiple detached occurrences
        let series = fakeStore.createDailySeries(
            title: "Daily Task",
            start: Date(),
            occurrences: 7
        )

        // Create some detached events
        try await seriesManager.editOccurrence(
            seriesID: series.identifier,
            occurrenceDate: series.occurrences[1].start,
            newTitle: "Special Task 1"
        )
        try await seriesManager.editOccurrence(
            seriesID: series.identifier,
            occurrenceDate: series.occurrences[3].start,
            newTitle: "Special Task 2"
        )

        // When: Deleting the entire series
        try await seriesManager.deleteSeries(seriesID: series.identifier)

        // Then: All detached events are also removed
        let detached1 = fakeStore.getDetachedEvent(
            seriesID: series.identifier,
            originalDate: series.occurrences[1].start
        )
        let detached2 = fakeStore.getDetachedEvent(
            seriesID: series.identifier,
            originalDate: series.occurrences[3].start
        )
        XCTAssertNil(detached1)
        XCTAssertNil(detached2)

        // And: Series is removed
        XCTAssertNil(fakeStore.getSeries(identifier: series.identifier))
    }

    // MARK: - Complex Frequency Tests

    func testBiWeeklyRecurrence() async throws {
        // Given: A bi-weekly series (every 2 weeks)
        let series = fakeStore.createCustomSeries(
            title: "Bi-weekly Review",
            start: Date(),
            frequency: .weekly,
            interval: 2,
            count: 6
        )

        // When: Fetching occurrences over 3 months
        let windowStart = series.occurrences[0].start
        let windowEnd = Calendar.current.date(byAdding: .month, value: 3, to: windowStart)!

        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: windowStart,
            to: windowEnd
        )

        // Then: Exactly 6 occurrences (every 2 weeks)
        XCTAssertEqual(occurrences.count, 6)

        // And: Occurrences are 2 weeks apart
        for i in 1 ..< occurrences.count {
            let previous = occurrences[i - 1].start
            let current = occurrences[i].start
            let days = Calendar.current.dateComponents([.day], from: previous, to: current).day
            XCTAssertEqual(days, 14, "Occurrences should be 14 days apart")
        }
    }

    func testMonthlyRecurrenceOnSpecificDay() async throws {
        // Given: Monthly series on the 15th
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = 15
        let start = calendar.date(from: components)!

        let series = fakeStore.createMonthlySeriesOnDay(
            title: "Monthly Review",
            start: start,
            dayOfMonth: 15,
            occurrences: 6
        )

        // When: Fetching occurrences
        let windowStart = series.occurrences[0].start
        let windowEnd = calendar.date(byAdding: .month, value: 7, to: windowStart)!

        let occurrences = seriesManager.getOccurrences(
            for: series.identifier,
            from: windowStart,
            to: windowEnd
        )

        // Then: All occurrences are on the 15th
        XCTAssertEqual(occurrences.count, 6)
        for occurrence in occurrences {
            let day = calendar.component(.day, from: occurrence.start)
            XCTAssertEqual(day, 15, "All occurrences should be on the 15th")
        }
    }
}

// MARK: - Test Infrastructure

class RecurringEventStore {
    private var series: [String: RecurringSeries] = [:]
    private var detachedEvents: [String: [Date: DetachedEvent]] = [:]

    func getSeries(identifier: String) -> RecurringSeries? {
        series[identifier]
    }

    func createWeeklySeries(title: String, start: Date, occurrences: Int) -> RecurringSeries {
        createCustomSeries(
            title: title,
            start: start,
            frequency: .weekly,
            interval: 1,
            count: occurrences
        )
    }

    func createDailySeries(title: String, start: Date, occurrences: Int) -> RecurringSeries {
        createCustomSeries(
            title: title,
            start: start,
            frequency: .daily,
            interval: 1,
            count: occurrences
        )
    }

    func createInfiniteSeries(title: String, start: Date, frequency: EKRecurrenceFrequency) -> RecurringSeries {
        let series = RecurringSeries(
            identifier: UUID().uuidString,
            title: title,
            start: start,
            frequency: frequency,
            interval: 1,
            recurrenceEnd: nil
        )
        self.series[series.identifier] = series
        return series
    }

    func createSeriesWithEndDate(
        title: String,
        start: Date,
        end: Date,
        frequency: EKRecurrenceFrequency
    ) -> RecurringSeries {
        let series = RecurringSeries(
            identifier: UUID().uuidString,
            title: title,
            start: start,
            frequency: frequency,
            interval: 1,
            recurrenceEnd: EKRecurrenceEnd(end: end)
        )
        self.series[series.identifier] = series
        return series
    }

    func createMonthlySeriesOnDay(title: String, start: Date, dayOfMonth _: Int, occurrences: Int) -> RecurringSeries {
        createCustomSeries(
            title: title,
            start: start,
            frequency: .monthly,
            interval: 1,
            count: occurrences
        )
    }

    func createCustomSeries(
        title: String,
        start: Date,
        frequency: EKRecurrenceFrequency,
        interval: Int,
        count: Int
    ) -> RecurringSeries {
        let series = RecurringSeries(
            identifier: UUID().uuidString,
            title: title,
            start: start,
            frequency: frequency,
            interval: interval,
            recurrenceEnd: EKRecurrenceEnd(occurrenceCount: count)
        )
        self.series[series.identifier] = series
        return series
    }

    func updateSeries(_ series: RecurringSeries) {
        self.series[series.identifier] = series
    }

    func deleteSeries(identifier: String) {
        series.removeValue(forKey: identifier)
        detachedEvents.removeValue(forKey: identifier)
    }

    func addDetachedEvent(seriesID: String, originalDate: Date, event: DetachedEvent) {
        if detachedEvents[seriesID] == nil {
            detachedEvents[seriesID] = [:]
        }
        detachedEvents[seriesID]?[originalDate] = event
    }

    func getDetachedEvent(seriesID: String, originalDate: Date) -> DetachedEvent? {
        detachedEvents[seriesID]?[originalDate]
    }

    func removeDetachedEvent(seriesID: String, originalDate: Date) {
        detachedEvents[seriesID]?.removeValue(forKey: originalDate)
    }
}

class RecurringSeries {
    let identifier: String
    var title: String
    let start: Date
    let frequency: EKRecurrenceFrequency
    let interval: Int
    var recurrenceEnd: EKRecurrenceEnd?
    var exceptionDates: Set<Date> = []

    init(
        identifier: String,
        title: String,
        start: Date,
        frequency: EKRecurrenceFrequency,
        interval: Int,
        recurrenceEnd: EKRecurrenceEnd?
    ) {
        self.identifier = identifier
        self.title = title
        self.start = start
        self.frequency = frequency
        self.interval = interval
        self.recurrenceEnd = recurrenceEnd
    }

    var occurrences: [SeriesOccurrence] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var currentDate = start

        let maxOccurrences: Int = if let end = recurrenceEnd {
            if let count = end.occurrenceCount {
                count
            } else if let endDate = end.endDate {
                100 // arbitrary limit for date-based end
            } else {
                100
            }
        } else {
            100
        }

        for _ in 0 ..< maxOccurrences {
            if let endDate = recurrenceEnd?.endDate, currentDate > endDate {
                break
            }

            if !exceptionDates.contains(currentDate) {
                dates.append(currentDate)
            }

            switch frequency {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: interval, to: currentDate)!
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: interval, to: currentDate)!
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: interval, to: currentDate)!
            case .yearly:
                currentDate = calendar.date(byAdding: .year, value: interval, to: currentDate)!
            @unknown default:
                break
            }
        }

        return dates.map { date in
            SeriesOccurrence(
                start: date,
                end: calendar.date(byAdding: .hour, value: 1, to: date)!,
                title: title
            )
        }
    }
}

struct SeriesOccurrence {
    let start: Date
    let end: Date
    let title: String
}

struct DetachedEvent {
    let identifier: String
    var title: String
    var start: Date
    var end: Date
}

class RecurrenceSeriesManager {
    private let store: RecurringEventStore

    init(store: RecurringEventStore) {
        self.store = store
    }

    func editOccurrence(seriesID: String, occurrenceDate: Date, newTitle: String) async throws {
        guard let series = store.getSeries(identifier: seriesID) else {
            throw EventKitContractError.eventNotFound
        }

        let detached = DetachedEvent(
            identifier: UUID().uuidString,
            title: newTitle,
            start: occurrenceDate,
            end: Calendar.current.date(byAdding: .hour, value: 1, to: occurrenceDate)!
        )
        store.addDetachedEvent(seriesID: seriesID, originalDate: occurrenceDate, event: detached)
    }

    func editOccurrence(seriesID: String, occurrenceDate: Date, newStart: Date, newEnd: Date) async throws {
        guard let series = store.getSeries(identifier: seriesID) else {
            throw EventKitContractError.eventNotFound
        }

        let detached = DetachedEvent(
            identifier: UUID().uuidString,
            title: series.title,
            start: newStart,
            end: newEnd
        )
        store.addDetachedEvent(seriesID: seriesID, originalDate: occurrenceDate, event: detached)
    }

    func deleteOccurrence(seriesID: String, occurrenceDate: Date, span: EKSpan) async throws {
        guard let series = store.getSeries(identifier: seriesID) else {
            throw EventKitContractError.eventNotFound
        }

        if span == .thisEvent {
            series.exceptionDates.insert(occurrenceDate)
            store.updateSeries(series)
        } else {
            // Future events: update series end date
            let occurrences = series.occurrences
            if let index = occurrences
                .firstIndex(where: { Calendar.current.isDate($0.start, inSameDayAs: occurrenceDate) }),
                index > 0
            {
                let previousOccurrence = occurrences[index - 1]
                series.recurrenceEnd = EKRecurrenceEnd(end: previousOccurrence.end)
                store.updateSeries(series)
            }
        }
    }

    func editSeries(seriesID: String, newTitle: String) async throws {
        guard let series = store.getSeries(identifier: seriesID) else {
            throw EventKitContractError.eventNotFound
        }
        series.title = newTitle
        store.updateSeries(series)
    }

    func deleteSeries(seriesID: String) async throws {
        store.deleteSeries(identifier: seriesID)
    }

    func getOccurrences(for seriesID: String, from start: Date, to end: Date) -> [SeriesOccurrence] {
        guard let series = store.getSeries(identifier: seriesID) else {
            return []
        }

        return series.occurrences.filter { occurrence in
            occurrence.start >= start && occurrence.end <= end
        }
    }
}
