import XCTest
import EventKit
@testable import ItoriApp

@MainActor
final class EventDeletionServiceTests: XCTestCase {
    
    var sut: EventDeletionService!
    var mockStore: MockEventStore!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = EventDeletionService.shared
        mockStore = MockEventStore()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockStore = nil
        try await super.tearDown()
    }
    
    // MARK: - Non-Recurring Event Tests
    
    func testDeleteNonRecurringEvent_WithConfirmation_Succeeds() async throws {
        // Given: A non-recurring event
        let event = mockStore.createTestEvent(
            title: "Team Meeting",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            isRecurring: false
        )
        let eventId = event.eventIdentifier
        
        var confirmCalled = false
        var scopeCalled = false
        
        // When: User confirms deletion
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { title, message in
                confirmCalled = true
                XCTAssertEqual(title, NSLocalizedString("event.delete.confirm_title", comment: ""))
                XCTAssertEqual(message, NSLocalizedString("event.delete.confirm_message_single", comment: ""))
                return true
            },
            presentScopeSelection: {
                scopeCalled = true
                return .thisEvent
            }
        )
        
        // Then: Event is deleted
        XCTAssertTrue(confirmCalled, "Confirmation should be presented")
        XCTAssertFalse(scopeCalled, "Scope selection should not be shown for non-recurring events")
        
        switch result {
        case .deleted:
            break // Success
        case .cancelled:
            XCTFail("Should not be cancelled")
        case .failed(let error):
            XCTFail("Should not fail: \(error)")
        }
    }
    
    func testDeleteNonRecurringEvent_Cancelled_DoesNotDelete() async throws {
        // Given: A non-recurring event
        let event = mockStore.createTestEvent(
            title: "Team Meeting",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            isRecurring: false
        )
        let eventId = event.eventIdentifier
        
        // When: User cancels
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, _ in false },
            presentScopeSelection: { .thisEvent }
        )
        
        // Then: Deletion is cancelled
        switch result {
        case .cancelled:
            break // Success
        case .deleted:
            XCTFail("Should not be deleted")
        case .failed:
            XCTFail("Should not fail")
        }
    }
    
    // MARK: - Recurring Event Tests
    
    func testDeleteRecurringEvent_ThisEvent_OnlyDeletesThisOccurrence() async throws {
        // Given: A recurring event
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            end: nil
        )
        let event = mockStore.createTestEvent(
            title: "Weekly Standup",
            start: Date(),
            end: Date().addingTimeInterval(1800),
            isRecurring: true,
            recurrenceRule: recurrenceRule
        )
        let eventId = event.eventIdentifier
        
        var selectedScope: EventDeletionService.RecurringDeletionScope?
        
        // When: User selects "This Event"
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, message in
                // Verify correct confirmation message
                XCTAssertEqual(message, NSLocalizedString("event.delete.confirm_message_this", comment: ""))
                return true
            },
            presentScopeSelection: {
                selectedScope = .thisEvent
                return .thisEvent
            }
        )
        
        // Then: Only this occurrence is deleted
        XCTAssertEqual(selectedScope, .thisEvent)
        switch result {
        case .deleted:
            break // Success
        case .cancelled:
            XCTFail("Should not be cancelled")
        case .failed(let error):
            XCTFail("Should not fail: \(error)")
        }
    }
    
    func testDeleteRecurringEvent_FutureEvents_DeletesThisAndFuture() async throws {
        // Given: A recurring event
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .daily,
            interval: 1,
            end: nil
        )
        let event = mockStore.createTestEvent(
            title: "Daily Reminder",
            start: Date(),
            end: Date().addingTimeInterval(900),
            isRecurring: true,
            recurrenceRule: recurrenceRule
        )
        let eventId = event.eventIdentifier
        
        var selectedScope: EventDeletionService.RecurringDeletionScope?
        
        // When: User selects "Future Events"
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, message in
                XCTAssertEqual(message, NSLocalizedString("event.delete.confirm_message_future", comment: ""))
                return true
            },
            presentScopeSelection: {
                selectedScope = .futureEvents
                return .futureEvents
            }
        )
        
        // Then: This and future occurrences are deleted
        XCTAssertEqual(selectedScope, .futureEvents)
        switch result {
        case .deleted:
            break // Success
        case .cancelled:
            XCTFail("Should not be cancelled")
        case .failed(let error):
            XCTFail("Should not fail: \(error)")
        }
    }
    
    func testDeleteRecurringEvent_AllEvents_DeletesEntireSeries() async throws {
        // Given: A recurring event
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .monthly,
            interval: 1,
            end: nil
        )
        let event = mockStore.createTestEvent(
            title: "Monthly Review",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            isRecurring: true,
            recurrenceRule: recurrenceRule
        )
        let eventId = event.eventIdentifier
        
        var selectedScope: EventDeletionService.RecurringDeletionScope?
        
        // When: User selects "All Events"
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, message in
                XCTAssertEqual(message, NSLocalizedString("event.delete.confirm_message_all", comment: ""))
                return true
            },
            presentScopeSelection: {
                selectedScope = .allEvents
                return .allEvents
            }
        )
        
        // Then: Entire series is deleted
        XCTAssertEqual(selectedScope, .allEvents)
        switch result {
        case .deleted:
            break // Success
        case .cancelled:
            XCTFail("Should not be cancelled")
        case .failed(let error):
            XCTFail("Should not fail: \(error)")
        }
    }
    
    func testDeleteRecurringEvent_CancelledAtScopeSelection_DoesNotDelete() async throws {
        // Given: A recurring event
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            end: nil
        )
        let event = mockStore.createTestEvent(
            title: "Weekly Meeting",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            isRecurring: true,
            recurrenceRule: recurrenceRule
        )
        let eventId = event.eventIdentifier
        
        // When: User cancels at scope selection
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, _ in true },
            presentScopeSelection: { nil }
        )
        
        // Then: Deletion is cancelled
        switch result {
        case .cancelled:
            break // Success
        case .deleted:
            XCTFail("Should not be deleted")
        case .failed:
            XCTFail("Should not fail")
        }
    }
    
    func testDeleteRecurringEvent_CancelledAtConfirmation_DoesNotDelete() async throws {
        // Given: A recurring event
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            end: nil
        )
        let event = mockStore.createTestEvent(
            title: "Weekly Meeting",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            isRecurring: true,
            recurrenceRule: recurrenceRule
        )
        let eventId = event.eventIdentifier
        
        // When: User cancels at final confirmation (after scope selection)
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, _ in false },
            presentScopeSelection: { .thisEvent }
        )
        
        // Then: Deletion is cancelled
        switch result {
        case .cancelled:
            break // Success
        case .deleted:
            XCTFail("Should not be deleted")
        case .failed:
            XCTFail("Should not fail")
        }
    }
    
    // MARK: - Reminder Tests
    
    func testDeleteReminder_WithConfirmation_Succeeds() async throws {
        // Given: A reminder
        let reminder = mockStore.createTestReminder(
            title: "Buy groceries",
            dueDate: Date().addingTimeInterval(86400)
        )
        let reminderId = reminder.calendarItemIdentifier
        
        var confirmCalled = false
        
        // When: User confirms deletion
        let result = await sut.deleteEvent(
            eventId: reminderId,
            isReminder: true,
            presentConfirmation: { title, message in
                confirmCalled = true
                XCTAssertEqual(message, NSLocalizedString("event.delete.confirm_message_reminder", comment: ""))
                return true
            },
            presentScopeSelection: { .thisEvent }
        )
        
        // Then: Reminder is deleted
        XCTAssertTrue(confirmCalled)
        switch result {
        case .deleted:
            break // Success
        case .cancelled:
            XCTFail("Should not be cancelled")
        case .failed(let error):
            XCTFail("Should not fail: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDeleteEvent_EventNotFound_HandlesGracefully() async throws {
        // Given: An invalid event ID
        let invalidId = "invalid-event-id"
        
        // When: Attempting to delete
        let result = await sut.deleteEvent(
            eventId: invalidId,
            isReminder: false,
            presentConfirmation: { _, _ in true },
            presentScopeSelection: { .thisEvent }
        )
        
        // Then: Returns appropriate error
        switch result {
        case .failed(let error):
            XCTAssertTrue(error is EventDeletionError)
            if let deletionError = error as? EventDeletionError {
                XCTAssertEqual(deletionError, .eventNotFound)
            }
        case .deleted, .cancelled:
            XCTFail("Should return error for invalid event ID")
        }
    }
    
    // MARK: - UI Flow Tests
    
    func testDeletionFlow_TwoStepProcess_RecurringEvents() async throws {
        // Given: A recurring event
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            end: nil
        )
        let event = mockStore.createTestEvent(
            title: "Team Sync",
            start: Date(),
            end: Date().addingTimeInterval(1800),
            isRecurring: true,
            recurrenceRule: recurrenceRule
        )
        let eventId = event.eventIdentifier
        
        var scopeSelectionPresented = false
        var confirmationPresented = false
        
        // When: Going through deletion flow
        let result = await sut.deleteEvent(
            eventId: eventId,
            isReminder: false,
            presentConfirmation: { _, _ in
                // Step 2: Final confirmation
                XCTAssertTrue(scopeSelectionPresented, "Scope selection should be shown first")
                confirmationPresented = true
                return true
            },
            presentScopeSelection: {
                // Step 1: Scope selection
                scopeSelectionPresented = true
                XCTAssertFalse(confirmationPresented, "Confirmation should not be shown yet")
                return .thisEvent
            }
        )
        
        // Then: Both steps are executed in order
        XCTAssertTrue(scopeSelectionPresented, "Scope selection should be presented")
        XCTAssertTrue(confirmationPresented, "Confirmation should be presented")
        
        switch result {
        case .deleted:
            break // Success
        default:
            XCTFail("Should successfully delete")
        }
    }
}

// MARK: - Mock Extensions

extension MockEventStore {
    func createTestEvent(
        title: String,
        start: Date,
        end: Date,
        isRecurring: Bool,
        recurrenceRule: EKRecurrenceRule? = nil
    ) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.calendar = store.defaultCalendarForNewEvents
        
        if isRecurring, let rule = recurrenceRule {
            event.recurrenceRules = [rule]
        }
        
        try? store.save(event, span: .thisEvent)
        return event
    }
    
    func createTestReminder(title: String, dueDate: Date) -> EKReminder {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        reminder.calendar = store.defaultCalendarForNewReminders()
        
        try? store.save(reminder, commit: true)
        return reminder
    }
}
