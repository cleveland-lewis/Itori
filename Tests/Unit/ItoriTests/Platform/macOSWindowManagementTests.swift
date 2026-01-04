import XCTest
@testable import Itori

#if os(macOS)
@MainActor
final class macOSWindowManagementTests: XCTestCase {
    var coursesStore: CoursesStore!
    var assignmentsStore: AssignmentsStore!
    var plannerStore: PlannerStore!
    
    override func setUp() async throws {
        try await super.setUp()
        let container = PersistenceController.preview.container
        coursesStore = CoursesStore(context: container.viewContext)
        assignmentsStore = AssignmentsStore(context: container.viewContext)
        plannerStore = PlannerStore(context: container.viewContext)
    }
    
    override func tearDown() async throws {
        coursesStore = nil
        assignmentsStore = nil
        plannerStore = nil
        try await super.tearDown()
    }
    
    // MARK: - Course Window Scene Tests
    
    func testCourseSceneExtractsCourseIdFromStorage() {
        let course = Course(
            id: UUID(),
            code: "CS101",
            title: "Intro to CS",
            semesterId: UUID(),
            colorHex: "#FF0000",
            location: "Room 101",
            instructor: "Dr. Smith",
            meetingTimes: "MWF 10-11"
        )
        coursesStore.addCourse(course)
        
        let courseIdString = course.id.uuidString
        XCTAssertNotNil(UUID(uuidString: courseIdString))
        
        let foundCourse = coursesStore.courses.first(where: { $0.id == course.id })
        XCTAssertNotNil(foundCourse)
        XCTAssertEqual(foundCourse?.title, "Intro to CS")
    }
    
    func testCourseSceneHandlesInvalidCourseId() {
        let invalidId = "not-a-uuid"
        let uuid = UUID(uuidString: invalidId)
        XCTAssertNil(uuid, "Invalid UUID string should return nil")
    }
    
    func testCourseSceneFindsAssignmentsForCourse() {
        let courseId = UUID()
        let course = Course(
            id: courseId,
            code: "MATH201",
            title: "Calculus",
            semesterId: UUID(),
            colorHex: "#00FF00"
        )
        coursesStore.addCourse(course)
        
        let task1 = AppTask(
            id: UUID(),
            title: "Homework 1",
            taskType: .assignment,
            due: Date(),
            courseId: courseId,
            estimatedMinutes: 60,
            priority: .medium,
            status: .todo
        )
        let task2 = AppTask(
            id: UUID(),
            title: "Homework 2",
            taskType: .assignment,
            due: Date().addingTimeInterval(86400),
            courseId: courseId,
            estimatedMinutes: 90,
            priority: .high,
            status: .todo
        )
        assignmentsStore.addTask(task1)
        assignmentsStore.addTask(task2)
        
        let assignmentsForCourse = assignmentsStore.tasks
            .filter { $0.courseId == courseId }
            .sorted { ($0.due ?? Date.distantFuture) < ($1.due ?? Date.distantFuture) }
        
        XCTAssertEqual(assignmentsForCourse.count, 2)
        XCTAssertEqual(assignmentsForCourse[0].title, "Homework 1")
        XCTAssertEqual(assignmentsForCourse[1].title, "Homework 2")
    }
    
    func testCourseSceneHandlesMissingSemester() {
        let course = Course(
            id: UUID(),
            code: "ENG101",
            title: "English",
            semesterId: UUID(),
            colorHex: "#0000FF"
        )
        coursesStore.addCourse(course)
        
        let semester = coursesStore.semesters.first(where: { $0.id == course.semesterId })
        XCTAssertNil(semester, "Should not find semester that doesn't exist")
    }
    
    // MARK: - Planner Window Scene Tests
    
    func testPlannerSceneParsesDateFromStorage() {
        let testDate = Date()
        let dateString = SceneActivationHelper.dateId(from: testDate)
        let parsedDate = SceneActivationHelper.date(from: dateString)
        
        XCTAssertNotNil(parsedDate)
        if let parsed = parsedDate {
            let calendar = Calendar.current
            XCTAssertTrue(calendar.isDate(parsed, inSameDayAs: testDate))
        }
    }
    
    func testPlannerSceneFiltersSessionsByDate() {
        let targetDate = Date()
        let calendar = Calendar.current
        
        let session1 = StoredScheduledSession(
            id: UUID(),
            title: "Morning Study",
            start: targetDate,
            end: targetDate.addingTimeInterval(3600),
            estimatedMinutes: 60,
            taskId: nil,
            eventId: nil
        )
        
        let otherDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        let session2 = StoredScheduledSession(
            id: UUID(),
            title: "Next Day Study",
            start: otherDate,
            end: otherDate.addingTimeInterval(3600),
            estimatedMinutes: 60,
            taskId: nil,
            eventId: nil
        )
        
        plannerStore.scheduled = [session1, session2]
        
        let filteredSessions = plannerStore.scheduled
            .filter { calendar.isDate($0.start, inSameDayAs: targetDate) }
        
        XCTAssertEqual(filteredSessions.count, 1)
        XCTAssertEqual(filteredSessions[0].title, "Morning Study")
    }
    
    func testPlannerSceneSortsSessions() {
        let baseDate = Date()
        
        let session1 = StoredScheduledSession(
            id: UUID(),
            title: "Afternoon",
            start: baseDate.addingTimeInterval(7200),
            end: baseDate.addingTimeInterval(10800),
            estimatedMinutes: 60,
            taskId: nil,
            eventId: nil
        )
        let session2 = StoredScheduledSession(
            id: UUID(),
            title: "Morning",
            start: baseDate,
            end: baseDate.addingTimeInterval(3600),
            estimatedMinutes: 60,
            taskId: nil,
            eventId: nil
        )
        
        plannerStore.scheduled = [session1, session2]
        
        let sortedSessions = plannerStore.scheduled.sorted { $0.start < $1.start }
        
        XCTAssertEqual(sortedSessions[0].title, "Morning")
        XCTAssertEqual(sortedSessions[1].title, "Afternoon")
    }
    
    // MARK: - Window State Restoration Tests
    
    func testSceneActivationHelperEncodesAndDecodesWindowState() {
        let state = WindowState(
            windowId: WindowIdentifier.courseDetail.rawValue,
            entityId: UUID().uuidString
        )
        
        let activity = SceneActivationHelper.encodeWindowState(state)
        XCTAssertNotNil(activity)
        
        let decoded = SceneActivationHelper.decodeWindowState(from: activity)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.windowId, state.windowId)
        XCTAssertEqual(decoded?.entityId, state.entityId)
    }
    
    func testSceneActivationHelperHandlesInvalidData() {
        let emptyActivity = NSUserActivity(activityType: SceneActivationHelper.windowActivityType)
        let decoded = SceneActivationHelper.decodeWindowState(from: emptyActivity)
        XCTAssertNil(decoded, "Should return nil for activity with no user info")
    }
}
#endif
