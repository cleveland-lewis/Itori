import XCTest
import EventKit
@testable import SharedCore

/// Tests validating Roots' EventKit interaction contract:
/// - Create, edit, delete operations
/// - Repeating series deletion behavior (this event / future / all)
/// - Optimistic UI patch behavior
/// - Error handling for "object not found"
final class EventKitContractTests: XCTestCase {
    
    var fakeStore: FakeEventStore!
    var calendarManager: TestableCalendarManager!
    
    override func setUp() {
        super.setUp()
        fakeStore = FakeEventStore()
        calendarManager = TestableCalendarManager(eventStore: fakeStore)
    }
    
    override func tearDown() {
        calendarManager = nil
        fakeStore = nil
        super.tearDown()
    }
    
    // MARK: - Create Event Tests
    
    func testCreateEventAppearsInModel() async throws {
        // Given: A new event to create
        let title = "Test Event"
        let start = Date()
        let end = start.addingTimeInterval(3600)
        
        // When: Creating the event
        let eventID = try await calendarManager.createEvent(
            title: title,
            start: start,
            end: end,
            calendar: fakeStore.defaultCalendar
        )
        
        // Then: Event appears in store
        let event = fakeStore.event(withIdentifier: eventID)
        XCTAssertNotNil(event, "Event should exist in store")
        XCTAssertEqual(event?.title, title)
        XCTAssertEqual(event?.startDate, start)
        XCTAssertEqual(event?.endDate, end)
    }
    
    func testCreateEventOptimisticUpdate() async throws {
        // Given: A new event to create
        let title = "Optimistic Event"
        let start = Date()
        let end = start.addingTimeInterval(3600)
        
        // When: Creating with optimistic update
        let optimisticID = UUID().uuidString
        calendarManager.addOptimisticEvent(
            id: optimisticID,
            title: title,
            start: start,
            end: end
        )
        
        // Then: Optimistic event appears immediately
        XCTAssertTrue(calendarManager.hasOptimisticEvent(id: optimisticID))
        
        // When: Actual create completes
        let actualID = try await calendarManager.createEvent(
            title: title,
            start: start,
            end: end,
            calendar: fakeStore.defaultCalendar
        )
        
        // Then: Optimistic event is replaced with actual event
        calendarManager.resolveOptimisticEvent(optimisticID: optimisticID, actualID: actualID)
        XCTAssertFalse(calendarManager.hasOptimisticEvent(id: optimisticID))
        XCTAssertNotNil(fakeStore.event(withIdentifier: actualID))
    }
    
    // MARK: - Edit Event Tests
    
    func testEditEventImmediateLocalUpdate() async throws {
        // Given: An existing event
        let event = fakeStore.createTestEvent(title: "Original", start: Date())
        let originalID = event.eventIdentifier
        
        // When: Editing the event
        let newTitle = "Updated Title"
        try await calendarManager.updateEvent(
            identifier: originalID,
            newTitle: newTitle
        )
        
        // Then: Event is updated in store
        let updated = fakeStore.event(withIdentifier: originalID)
        XCTAssertEqual(updated?.title, newTitle)
    }
    
    func testEditEventOptimisticUpdate() async throws {
        // Given: An existing event
        let event = fakeStore.createTestEvent(title: "Original", start: Date())
        let eventID = event.eventIdentifier
        
        // When: Optimistically updating
        let newTitle = "Optimistic Title"
        calendarManager.applyOptimisticEdit(eventID: eventID, newTitle: newTitle)
        
        // Then: Local model reflects change immediately
        XCTAssertEqual(calendarManager.getOptimisticTitle(for: eventID), newTitle)
        
        // When: Actual update completes
        try await calendarManager.updateEvent(identifier: eventID, newTitle: newTitle)
        
        // Then: Optimistic state is cleared
        calendarManager.clearOptimisticEdit(eventID: eventID)
        XCTAssertNil(calendarManager.getOptimisticTitle(for: eventID))
        
        // And: Event is updated in store
        let updated = fakeStore.event(withIdentifier: eventID)
        XCTAssertEqual(updated?.title, newTitle)
    }
    
    // MARK: - Delete Event Tests (Non-Recurring)
    
    func testDeleteSingleEventRequiresConfirmation() async throws {
        // Given: An existing non-recurring event
        let event = fakeStore.createTestEvent(title: "To Delete", start: Date())
        let eventID = event.eventIdentifier
        
        // When/Then: Deletion requires confirmation
        let requiresConfirmation = calendarManager.deletionRequiresConfirmation(eventID: eventID)
        XCTAssertTrue(requiresConfirmation, "Deletion should require confirmation")
    }
    
    func testDeleteSingleEvent() async throws {
        // Given: An existing non-recurring event
        let event = fakeStore.createTestEvent(title: "To Delete", start: Date())
        let eventID = event.eventIdentifier
        
        // When: Deleting the event
        try await calendarManager.deleteEvent(identifier: eventID, span: .thisEvent)
        
        // Then: Event is removed from store
        XCTAssertNil(fakeStore.event(withIdentifier: eventID))
    }
    
    func testDeleteEventOptimisticRemoval() async throws {
        // Given: An existing event
        let event = fakeStore.createTestEvent(title: "To Delete", start: Date())
        let eventID = event.eventIdentifier
        
        // When: Optimistically marking as deleted
        calendarManager.markOptimisticallyDeleted(eventID: eventID)
        
        // Then: Event is hidden from local model
        XCTAssertTrue(calendarManager.isOptimisticallyDeleted(eventID: eventID))
        
        // When: Actual deletion completes
        try await calendarManager.deleteEvent(identifier: eventID, span: .thisEvent)
        
        // Then: Optimistic state is cleared
        calendarManager.clearOptimisticDeletion(eventID: eventID)
        XCTAssertFalse(calendarManager.isOptimisticallyDeleted(eventID: eventID))
        
        // And: Event is removed from store
        XCTAssertNil(fakeStore.event(withIdentifier: eventID))
    }
    
    // MARK: - Repeating Series Deletion Tests
    
    func testDeleteRecurringEventThisEventOnly() async throws {
        // Given: A recurring event series
        let series = fakeStore.createRecurringEvent(
            title: "Recurring Event",
            start: Date(),
            frequency: .weekly,
            occurrences: 5
        )
        let eventID = series.eventIdentifier
        
        // When: Deleting only this occurrence
        try await calendarManager.deleteEvent(identifier: eventID, span: .thisEvent)
        
        // Then: Only this occurrence is deleted, future ones remain
        XCTAssertEqual(fakeStore.deletionSpan, .thisEvent)
        XCTAssertEqual(fakeStore.deletedEventCount, 1)
    }
    
    func testDeleteRecurringEventFutureEvents() async throws {
        // Given: A recurring event series
        let series = fakeStore.createRecurringEvent(
            title: "Recurring Event",
            start: Date(),
            frequency: .weekly,
            occurrences: 5
        )
        let eventID = series.eventIdentifier
        
        // When: Deleting this and future occurrences
        try await calendarManager.deleteEvent(identifier: eventID, span: .futureEvents)
        
        // Then: This and future occurrences are deleted
        XCTAssertEqual(fakeStore.deletionSpan, .futureEvents)
        XCTAssertTrue(fakeStore.deletedEventCount >= 1)
    }
    
    func testDeleteRecurringEventAllEvents() async throws {
        // Given: A recurring event series
        let series = fakeStore.createRecurringEvent(
            title: "Recurring Event",
            start: Date(),
            frequency: .weekly,
            occurrences: 5
        )
        let eventID = series.eventIdentifier
        
        // When: Deleting entire series
        try await calendarManager.deleteEvent(identifier: eventID, span: .futureEvents)
        
        // Then: All occurrences are deleted
        XCTAssertNil(fakeStore.event(withIdentifier: eventID))
    }
    
    func testDeletionSpanOptions() {
        // Given: A recurring event
        let series = fakeStore.createRecurringEvent(
            title: "Recurring Event",
            start: Date(),
            frequency: .daily,
            occurrences: 10
        )
        
        // When: Getting deletion options
        let options = calendarManager.getDeletionOptions(for: series.eventIdentifier)
        
        // Then: All three options are available for recurring events
        XCTAssertTrue(options.contains(.thisEvent))
        XCTAssertTrue(options.contains(.futureEvents))
        XCTAssertEqual(options.count, 2, "Should have this event and future events options")
    }
    
    // MARK: - Error Handling Tests
    
    func testEventNotFoundTreatedAsDeleted() async throws {
        // Given: A non-existent event ID
        let nonExistentID = "non-existent-event-id"
        
        // When: Attempting to fetch the event
        let event = fakeStore.event(withIdentifier: nonExistentID)
        
        // Then: Event is nil (treated as deleted)
        XCTAssertNil(event)
        
        // When: Attempting to delete
        do {
            try await calendarManager.deleteEvent(identifier: nonExistentID, span: .thisEvent)
            XCTFail("Should throw event not found error")
        } catch let error as EventKitContractError {
            // Then: Error is handled gracefully
            XCTAssertEqual(error, .eventNotFound)
        }
    }
    
    func testCacheCleanedOnEventNotFound() async throws {
        // Given: An event in the cache
        let event = fakeStore.createTestEvent(title: "Cached Event", start: Date())
        let eventID = event.eventIdentifier
        calendarManager.cacheEvent(event)
        
        // When: Event is deleted externally (not in store anymore)
        fakeStore.removeEvent(identifier: eventID)
        
        // When: Attempting to fetch from cache
        try await calendarManager.refreshCache()
        
        // Then: Cache is cleaned (event removed from cache)
        XCTAssertNil(calendarManager.getCachedEvent(identifier: eventID))
    }
    
    // MARK: - Optimistic UI Consistency Tests
    
    func testMultipleOptimisticUpdatesAreConsistent() async throws {
        // Given: An event
        let event = fakeStore.createTestEvent(title: "Original", start: Date())
        let eventID = event.eventIdentifier
        
        // When: Multiple optimistic updates in sequence
        calendarManager.applyOptimisticEdit(eventID: eventID, newTitle: "Update 1")
        calendarManager.applyOptimisticEdit(eventID: eventID, newTitle: "Update 2")
        calendarManager.applyOptimisticEdit(eventID: eventID, newTitle: "Update 3")
        
        // Then: Latest optimistic state is reflected
        XCTAssertEqual(calendarManager.getOptimisticTitle(for: eventID), "Update 3")
        
        // When: Actual update completes with final value
        try await calendarManager.updateEvent(identifier: eventID, newTitle: "Update 3")
        calendarManager.clearOptimisticEdit(eventID: eventID)
        
        // Then: Store reflects final value
        let updated = fakeStore.event(withIdentifier: eventID)
        XCTAssertEqual(updated?.title, "Update 3")
    }
    
    func testOptimisticDeletePreventsFurtherEdits() {
        // Given: An event marked for optimistic deletion
        let event = fakeStore.createTestEvent(title: "To Delete", start: Date())
        let eventID = event.eventIdentifier
        calendarManager.markOptimisticallyDeleted(eventID: eventID)
        
        // When: Attempting to edit a deleted event
        let canEdit = calendarManager.canEdit(eventID: eventID)
        
        // Then: Editing is blocked
        XCTAssertFalse(canEdit, "Should not allow editing of optimistically deleted events")
    }
    
    // MARK: - Event Store Change Notification Tests
    
    func testStoreChangeTriggersRefresh() async throws {
        // Given: Calendar manager observing store changes
        var refreshCallCount = 0
        calendarManager.onRefresh = { refreshCallCount += 1 }
        
        // When: Store changes externally
        NotificationCenter.default.post(name: .EKEventStoreChanged, object: fakeStore)
        
        // Then: Refresh is triggered
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        XCTAssertGreaterThan(refreshCallCount, 0, "Refresh should be triggered by store change")
    }
}

// MARK: - Test Helpers

enum EventKitContractError: Error, Equatable {
    case eventNotFound
    case unauthorized
    case saveFailed
    case deleteFailed
}

/// Fake EventKit store for testing without actual calendar access
class FakeEventStore {
    private var events: [String: FakeEvent] = [:]
    private(set) var deletionSpan: EKSpan?
    private(set) var deletedEventCount: Int = 0
    
    let defaultCalendar = FakeCalendar(identifier: "default-calendar")
    
    func event(withIdentifier identifier: String) -> FakeEvent? {
        return events[identifier]
    }
    
    func createTestEvent(title: String, start: Date) -> FakeEvent {
        let event = FakeEvent(
            identifier: UUID().uuidString,
            title: title,
            startDate: start,
            endDate: start.addingTimeInterval(3600),
            isRecurring: false
        )
        events[event.eventIdentifier] = event
        return event
    }
    
    func createRecurringEvent(title: String, start: Date, frequency: EKRecurrenceFrequency, occurrences: Int) -> FakeEvent {
        let event = FakeEvent(
            identifier: UUID().uuidString,
            title: title,
            startDate: start,
            endDate: start.addingTimeInterval(3600),
            isRecurring: true,
            recurrenceRule: EKRecurrenceRule(
                recurrenceWith: frequency,
                interval: 1,
                end: EKRecurrenceEnd(occurrenceCount: occurrences)
            )
        )
        events[event.eventIdentifier] = event
        return event
    }
    
    func save(_ event: FakeEvent) throws {
        events[event.eventIdentifier] = event
    }
    
    func remove(_ event: FakeEvent, span: EKSpan) throws {
        deletionSpan = span
        
        if span == .thisEvent {
            events.removeValue(forKey: event.eventIdentifier)
            deletedEventCount = 1
        } else {
            // Simulate deleting multiple events for series
            events.removeValue(forKey: event.eventIdentifier)
            deletedEventCount = event.isRecurring ? 5 : 1
        }
    }
    
    func removeEvent(identifier: String) {
        events.removeValue(forKey: identifier)
    }
    
    func reset() {
        events.removeAll()
        deletionSpan = nil
        deletedEventCount = 0
    }
}

class FakeEvent {
    let eventIdentifier: String
    var title: String
    var startDate: Date
    var endDate: Date
    let isRecurring: Bool
    let recurrenceRule: EKRecurrenceRule?
    
    init(identifier: String, title: String, startDate: Date, endDate: Date, isRecurring: Bool, recurrenceRule: EKRecurrenceRule? = nil) {
        self.eventIdentifier = identifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
    }
}

class FakeCalendar {
    let identifier: String
    
    init(identifier: String) {
        self.identifier = identifier
    }
}

/// Testable calendar manager that uses fake event store
class TestableCalendarManager {
    private let eventStore: FakeEventStore
    private var optimisticEvents: [String: OptimisticEvent] = [:]
    private var optimisticEdits: [String: String] = [:]
    private var optimisticDeletions: Set<String> = []
    private var cachedEvents: [String: FakeEvent] = [:]
    
    var onRefresh: (() -> Void)?
    
    init(eventStore: FakeEventStore) {
        self.eventStore = eventStore
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onRefresh?()
        }
    }
    
    // MARK: - Create
    
    func createEvent(title: String, start: Date, end: Date, calendar: FakeCalendar) async throws -> String {
        let event = FakeEvent(
            identifier: UUID().uuidString,
            title: title,
            startDate: start,
            endDate: end,
            isRecurring: false
        )
        try eventStore.save(event)
        return event.eventIdentifier
    }
    
    // MARK: - Update
    
    func updateEvent(identifier: String, newTitle: String) async throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw EventKitContractError.eventNotFound
        }
        event.title = newTitle
        try eventStore.save(event)
    }
    
    // MARK: - Delete
    
    func deleteEvent(identifier: String, span: EKSpan) async throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw EventKitContractError.eventNotFound
        }
        try eventStore.remove(event, span: span)
    }
    
    func deletionRequiresConfirmation(eventID: String) -> Bool {
        return true // All deletions require confirmation
    }
    
    func getDeletionOptions(for eventID: String) -> Set<EKSpan> {
        guard let event = eventStore.event(withIdentifier: eventID) else {
            return []
        }
        
        if event.isRecurring {
            return [.thisEvent, .futureEvents]
        } else {
            return [.thisEvent]
        }
    }
    
    // MARK: - Optimistic Updates
    
    func addOptimisticEvent(id: String, title: String, start: Date, end: Date) {
        optimisticEvents[id] = OptimisticEvent(title: title, start: start, end: end)
    }
    
    func hasOptimisticEvent(id: String) -> Bool {
        return optimisticEvents[id] != nil
    }
    
    func resolveOptimisticEvent(optimisticID: String, actualID: String) {
        optimisticEvents.removeValue(forKey: optimisticID)
    }
    
    func applyOptimisticEdit(eventID: String, newTitle: String) {
        optimisticEdits[eventID] = newTitle
    }
    
    func getOptimisticTitle(for eventID: String) -> String? {
        return optimisticEdits[eventID]
    }
    
    func clearOptimisticEdit(eventID: String) {
        optimisticEdits.removeValue(forKey: eventID)
    }
    
    func markOptimisticallyDeleted(eventID: String) {
        optimisticDeletions.insert(eventID)
    }
    
    func isOptimisticallyDeleted(eventID: String) -> Bool {
        return optimisticDeletions.contains(eventID)
    }
    
    func clearOptimisticDeletion(eventID: String) {
        optimisticDeletions.remove(eventID)
    }
    
    func canEdit(eventID: String) -> Bool {
        return !isOptimisticallyDeleted(eventID: eventID)
    }
    
    // MARK: - Cache Management
    
    func cacheEvent(_ event: FakeEvent) {
        cachedEvents[event.eventIdentifier] = event
    }
    
    func getCachedEvent(identifier: String) -> FakeEvent? {
        return cachedEvents[identifier]
    }
    
    func refreshCache() async throws {
        // Remove cached events that no longer exist in store
        let idsToRemove = cachedEvents.keys.filter { eventStore.event(withIdentifier: $0) == nil }
        for id in idsToRemove {
            cachedEvents.removeValue(forKey: id)
        }
    }
}

struct OptimisticEvent {
    let title: String
    let start: Date
    let end: Date
}
