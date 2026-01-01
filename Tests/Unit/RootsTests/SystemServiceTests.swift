import XCTest
import EventKit
@testable import Roots

final class EventKitIntegrationTests: XCTestCase {
    var mockStore: MockEventStore!
    
    override func setUp() {
        super.setUp()
        mockStore = MockEventStore()
    }
    
    override func tearDown() {
        mockStore = nil
        super.tearDown()
    }
    
    // MARK: - Access Tests
    
    func testRequestAccessSuccess() async throws {
        mockStore.hasAccess = true
        
        let granted = try await mockStore.requestFullAccessToEvents()
        
        XCTAssertTrue(granted)
    }
    
    func testRequestAccessDenied() async throws {
        mockStore.hasAccess = false
        
        let granted = try await mockStore.requestFullAccessToEvents()
        
        XCTAssertFalse(granted)
    }
    
    func testRequestAccessFailure() async {
        mockStore.shouldFailAccess = true
        
        do {
            _ = try await mockStore.requestFullAccessToEvents()
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "EKErrorDomain")
        }
    }
    
    // MARK: - Event CRUD Tests
    
    func testSaveEvent() throws {
        let event = EKEvent(eventStore: EKEventStore())
        event.title = "Test Event"
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(3600)
        
        try mockStore.save(event, span: .thisEvent, commit: true)
        
        XCTAssertEqual(mockStore.storedEvents.count, 1)
        XCTAssertEqual(mockStore.storedEvents.first?.title, "Test Event")
    }
    
    func testRemoveEvent() throws {
        let event = EKEvent(eventStore: EKEventStore())
        event.title = "To Remove"
        try mockStore.save(event, span: .thisEvent, commit: true)
        
        XCTAssertEqual(mockStore.storedEvents.count, 1)
        
        try mockStore.remove(event, span: .thisEvent, commit: true)
        
        XCTAssertEqual(mockStore.storedEvents.count, 0)
    }
    
    func testFetchEvents() throws {
        let event1 = EKEvent(eventStore: EKEventStore())
        event1.title = "Event 1"
        event1.startDate = Date()
        
        let event2 = EKEvent(eventStore: EKEventStore())
        event2.title = "Event 2"
        event2.startDate = Date().addingTimeInterval(86400)
        
        try mockStore.save(event1, span: .thisEvent, commit: true)
        try mockStore.save(event2, span: .thisEvent, commit: true)
        
        let predicate = NSPredicate(value: true)
        let fetched = mockStore.fetchEvents(matching: predicate)
        
        XCTAssertEqual(fetched.count, 2)
    }
    
    // MARK: - Calendar Tests
    
    func testGetCalendars() {
        let calendar = EKCalendar(for: .event, eventStore: EKEventStore())
        calendar.title = "Test Calendar"
        mockStore.storedCalendars = [calendar]
        
        let calendars = mockStore.calendars(for: .event)
        
        XCTAssertEqual(calendars.count, 1)
        XCTAssertEqual(calendars.first?.title, "Test Calendar")
    }
    
    func testDefaultCalendar() {
        let calendar = EKCalendar(for: .event, eventStore: EKEventStore())
        calendar.title = "Default"
        mockStore.defaultCalendar = calendar
        
        let def = mockStore.defaultCalendarForNewEvents()
        
        XCTAssertEqual(def?.title, "Default")
    }
}

