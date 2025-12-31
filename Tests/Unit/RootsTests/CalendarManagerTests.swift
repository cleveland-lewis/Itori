import XCTest
import EventKit
@testable import Roots

@MainActor
final class CalendarManagerTests: XCTestCase {
    var calendarManager: CalendarManager!
    
    override func setUp() {
        super.setUp()
        calendarManager = CalendarManager.shared
    }
    
    override func tearDown() {
        calendarManager = nil
        super.tearDown()
    }
    
    func testNextEventReturnsUpcomingEvent() {
        let now = Date()
        let past = now.addingTimeInterval(-3600)
        let future1 = now.addingTimeInterval(3600)
        let future2 = now.addingTimeInterval(7200)
        
        let pastEvent = createMockEvent(start: past)
        let futureEvent1 = createMockEvent(start: future1)
        let futureEvent2 = createMockEvent(start: future2)
        
        let events = [pastEvent, futureEvent2, futureEvent1]
        let next = calendarManager.nextEvent(allEvents: events)
        
        XCTAssertEqual(next?.startDate, future1)
    }
    
    func testNextEventReturnsNilWhenNoUpcoming() {
        let past1 = Date().addingTimeInterval(-7200)
        let past2 = Date().addingTimeInterval(-3600)
        
        let events = [createMockEvent(start: past1), createMockEvent(start: past2)]
        let next = calendarManager.nextEvent(allEvents: events)
        
        XCTAssertNil(next)
    }
    
    func testTasksDueTomorrowCountsCorrectly() {
        let mockAssignments = MockAssignmentsStore()
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        
        mockAssignments.tasks = [
            createMockTask(due: tomorrow),
            createMockTask(due: tomorrow.addingTimeInterval(3600)),
            createMockTask(due: Date()), // Today, not tomorrow
            createMockTask(due: nil) // No due date
        ]
        
        let count = calendarManager.tasksDueTomorrow(using: mockAssignments)
        XCTAssertEqual(count, 2)
    }
    
    func testTasksDueThisWeekCountsCorrectly() {
        let mockAssignments = MockAssignmentsStore()
        let cal = Calendar.current
        let now = Date()
        let inThreeDays = cal.date(byAdding: .day, value: 3, to: now)!
        let inEightDays = cal.date(byAdding: .day, value: 8, to: now)!
        
        mockAssignments.tasks = [
            createMockTask(due: now),
            createMockTask(due: inThreeDays),
            createMockTask(due: inEightDays), // Beyond 7 days
        ]
        
        let count = calendarManager.tasksDueThisWeek(using: mockAssignments)
        XCTAssertEqual(count, 2)
    }
    
    // MARK: - Helpers
    
    private func createMockEvent(start: Date, duration: TimeInterval = 3600) -> EKEvent {
        let event = EKEvent(eventStore: EKEventStore())
        event.startDate = start
        event.endDate = start.addingTimeInterval(duration)
        event.title = "Mock Event"
        return event
    }
    
    private func createMockTask(due: Date?) -> PlannerTask {
        PlannerTask(
            id: UUID(),
            name: "Mock Task",
            due: due,
            duration: 60,
            priority: .medium,
            course: nil
        )
    }
}

// MARK: - Mock

class MockAssignmentsStore: AssignmentsStore {
    var tasks: [PlannerTask] = []
    
    func addTask(_ task: PlannerTask) {
        tasks.append(task)
    }
    
    func updateTask(_ task: PlannerTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
    }
    
    func fetchTasks() -> [PlannerTask] {
        return tasks
    }
}
