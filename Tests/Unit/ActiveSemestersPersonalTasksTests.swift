//
//  ActiveSemestersPersonalTasksTests.swift
//  ItoriTests
//
//  Tests for active semesters and personal tasks functionality
//

import XCTest
@testable import Itori

@MainActor
final class ActiveSemestersPersonalTasksTests: XCTestCase {
    
    var coursesStore: CoursesStore!
    var assignmentsStore: AssignmentsStore!
    
    override func setUp() async throws {
        // Create test stores with in-memory storage
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        
        coursesStore = CoursesStore(storageURL: tempURL)
        assignmentsStore = AssignmentsStore.shared
    }
    
    override func tearDown() async throws {
        coursesStore = nil
        assignmentsStore = nil
    }
    
    // MARK: - Active Semesters Tests
    
    func testAddSemesterMarksAsActive() async throws {
        // Given: A new semester marked as current
        let semester = Semester(
            id: UUID(),
            name: "Fall 2025",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 120),
            semesterTerm: .fall,
            isCurrent: true,
            isArchived: false,
            educationLevel: .college
        )
        
        // When: Adding the semester
        coursesStore.addSemester(semester)
        
        // Then: It should be in activeSemesterIds
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(semester.id))
        XCTAssertEqual(coursesStore.activeSemesterIds.count, 1)
    }
    
    func testToggleActiveSemester() async throws {
        // Given: Two semesters
        let fall = createTestSemester(name: "Fall 2025", isCurrent: true)
        let spring = createTestSemester(name: "Spring 2026", isCurrent: false)
        
        coursesStore.addSemester(fall)
        coursesStore.addSemester(spring)
        
        // When: Toggling spring to active
        coursesStore.toggleActiveSemester(spring)
        
        // Then: Both should be active
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(fall.id))
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(spring.id))
        XCTAssertEqual(coursesStore.activeSemesterIds.count, 2)
        
        // When: Toggling spring off
        coursesStore.toggleActiveSemester(spring)
        
        // Then: Only fall should be active
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(fall.id))
        XCTAssertFalse(coursesStore.activeSemesterIds.contains(spring.id))
        XCTAssertEqual(coursesStore.activeSemesterIds.count, 1)
    }
    
    func testSetMultipleActiveSemesters() async throws {
        // Given: Three semesters
        let summer = createTestSemester(name: "Summer 2025", isCurrent: false)
        let fall = createTestSemester(name: "Fall 2025", isCurrent: true)
        let spring = createTestSemester(name: "Spring 2026", isCurrent: false)
        
        coursesStore.addSemester(summer)
        coursesStore.addSemester(fall)
        coursesStore.addSemester(spring)
        
        // When: Setting multiple active at once
        coursesStore.setActiveSemesters([summer.id, fall.id, spring.id])
        
        // Then: All should be active
        XCTAssertEqual(coursesStore.activeSemesterIds.count, 3)
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(summer.id))
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(fall.id))
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(spring.id))
    }
    
    func testActiveCoursesRespectsActiveSemesters() async throws {
        // Given: Two semesters with courses
        let fall = createTestSemester(name: "Fall 2025", isCurrent: true)
        let spring = createTestSemester(name: "Spring 2026", isCurrent: false)
        
        coursesStore.addSemester(fall)
        coursesStore.addSemester(spring)
        
        let fallCourse1 = createTestCourse(title: "Math 101", semester: fall)
        let fallCourse2 = createTestCourse(title: "CS 101", semester: fall)
        let springCourse = createTestCourse(title: "Physics 101", semester: spring)
        
        coursesStore.addCourse(fallCourse1)
        coursesStore.addCourse(fallCourse2)
        coursesStore.addCourse(springCourse)
        
        // When: Only fall is active
        XCTAssertEqual(coursesStore.activeSemesterIds.count, 1)
        
        // Then: Only fall courses should be in activeCourses
        XCTAssertEqual(coursesStore.activeCourses.count, 2)
        XCTAssertTrue(coursesStore.activeCourses.contains { $0.id == fallCourse1.id })
        XCTAssertTrue(coursesStore.activeCourses.contains { $0.id == fallCourse2.id })
        
        // When: Activating spring as well
        coursesStore.toggleActiveSemester(spring)
        
        // Then: All courses should be in activeCourses
        XCTAssertEqual(coursesStore.activeCourses.count, 3)
    }
    
    func testActiveSemestersComputedProperty() async throws {
        // Given: Multiple semesters, some archived
        let fall = createTestSemester(name: "Fall 2025", isCurrent: true)
        let spring = createTestSemester(name: "Spring 2026", isCurrent: false)
        var archivedSemester = createTestSemester(name: "Fall 2024", isCurrent: false)
        archivedSemester.isArchived = true
        
        coursesStore.addSemester(fall)
        coursesStore.addSemester(spring)
        coursesStore.addSemester(archivedSemester)
        
        coursesStore.setActiveSemesters([fall.id, spring.id, archivedSemester.id])
        
        // When: Getting activeSemesters
        let active = coursesStore.activeSemesters
        
        // Then: Should exclude archived semester
        XCTAssertEqual(active.count, 2)
        XCTAssertFalse(active.contains { $0.id == archivedSemester.id })
    }
    
    // MARK: - Personal Tasks Tests
    
    func testPersonalTaskCreation() async throws {
        // Given: A task without a course
        let personalTask = AppTask(
            id: UUID(),
            title: "Buy groceries",
            courseId: nil,  // No course = personal task
            due: Date(),
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 30,
            difficulty: 0.3,
            importance: 0.5,
            type: .homework,
            locked: false
        )
        
        // Then: Should be identified as personal
        XCTAssertTrue(personalTask.isPersonal)
        XCTAssertNil(personalTask.courseId)
    }
    
    func testCourseTaskIsNotPersonal() async throws {
        // Given: A task with a course
        let courseId = UUID()
        let courseTask = AppTask(
            id: UUID(),
            title: "Math homework",
            courseId: courseId,
            due: Date(),
            estimatedMinutes: 60,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.7,
            importance: 0.8,
            type: .homework,
            locked: false
        )
        
        // Then: Should NOT be personal
        XCTAssertFalse(courseTask.isPersonal)
        XCTAssertEqual(courseTask.courseId, courseId)
    }
    
    func testFilterPersonalTasks() async throws {
        // Given: Mixed personal and course tasks
        let personal1 = createPersonalTask(title: "Dentist appointment")
        let personal2 = createPersonalTask(title: "Call mom")
        let courseTask = createCourseTask(title: "Essay", courseId: UUID())
        
        let allTasks = [personal1, personal2, courseTask]
        
        // When: Filtering personal tasks
        let personalTasks = allTasks.filter { $0.isPersonal }
        
        // Then: Should only include personal tasks
        XCTAssertEqual(personalTasks.count, 2)
        XCTAssertTrue(personalTasks.allSatisfy { $0.isPersonal })
    }
    
    // MARK: - Migration Tests
    
    func testMigrationFromCurrentSemesterIdToActiveSemesterIds() async throws {
        // Given: A semester set as current (simulating old data)
        let semester = createTestSemester(name: "Fall 2025", isCurrent: true)
        coursesStore.addSemester(semester)
        coursesStore.setCurrentSemester(semester)
        
        // Then: Should be in activeSemesterIds automatically
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(semester.id))
        XCTAssertEqual(coursesStore.currentSemesterId, semester.id)
    }
    
    func testCurrentSemesterIdSyncsWithActiveSemesters() async throws {
        // Given: Setting currentSemesterId
        let semester = createTestSemester(name: "Fall 2025", isCurrent: false)
        coursesStore.addSemester(semester)
        
        // When: Setting as current
        coursesStore.setCurrentSemester(semester)
        
        // Then: Should be added to activeSemesterIds
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(semester.id))
    }
    
    func testDeleteSemesterRemovesFromActiveIds() async throws {
        // Given: An active semester
        let semester = createTestSemester(name: "Fall 2025", isCurrent: true)
        coursesStore.addSemester(semester)
        XCTAssertTrue(coursesStore.activeSemesterIds.contains(semester.id))
        
        // When: Deleting the semester
        coursesStore.deleteSemester(semester.id)
        
        // Then: Should be removed from activeSemesterIds
        XCTAssertFalse(coursesStore.activeSemesterIds.contains(semester.id))
    }
    
    // MARK: - Integration Tests
    
    func testMultipleSemestersWithPersonalTasks() async throws {
        // Given: Two active semesters with courses and personal tasks
        let fall = createTestSemester(name: "Fall 2025", isCurrent: true)
        let spring = createTestSemester(name: "Spring 2026", isCurrent: false)
        
        coursesStore.addSemester(fall)
        coursesStore.addSemester(spring)
        coursesStore.toggleActiveSemester(spring)
        
        let fallCourse = createTestCourse(title: "Math 101", semester: fall)
        let springCourse = createTestCourse(title: "CS 101", semester: spring)
        
        coursesStore.addCourse(fallCourse)
        coursesStore.addCourse(springCourse)
        
        // Create tasks: 2 course tasks + 2 personal tasks
        let mathTask = createCourseTask(title: "Math HW", courseId: fallCourse.id)
        let csTask = createCourseTask(title: "CS Project", courseId: springCourse.id)
        let personal1 = createPersonalTask(title: "Gym")
        let personal2 = createPersonalTask(title: "Groceries")
        
        // Then: Active courses should show both semesters
        XCTAssertEqual(coursesStore.activeCourses.count, 2)
        
        // Then: Can filter personal vs course tasks
        let allTasks = [mathTask, csTask, personal1, personal2]
        XCTAssertEqual(allTasks.filter { $0.isPersonal }.count, 2)
        XCTAssertEqual(allTasks.filter { !$0.isPersonal }.count, 2)
    }
    
    // MARK: - Helper Methods
    
    private func createTestSemester(name: String, isCurrent: Bool) -> Semester {
        Semester(
            id: UUID(),
            name: name,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 120),
            semesterTerm: .fall,
            isCurrent: isCurrent,
            isArchived: false,
            educationLevel: .college
        )
    }
    
    private func createTestCourse(title: String, semester: Semester) -> Course {
        Course(
            id: UUID(),
            title: title,
            code: "TEST101",
            instructor: "Test Professor",
            credits: 3.0,
            color: .blue,
            semesterId: semester.id,
            isArchived: false
        )
    }
    
    private func createPersonalTask(title: String) -> AppTask {
        AppTask(
            id: UUID(),
            title: title,
            courseId: nil,  // Personal task
            due: Date(),
            estimatedMinutes: 30,
            minBlockMinutes: 15,
            maxBlockMinutes: 60,
            difficulty: 0.3,
            importance: 0.5,
            type: .homework,
            locked: false
        )
    }
    
    private func createCourseTask(title: String, courseId: UUID) -> AppTask {
        AppTask(
            id: UUID(),
            title: title,
            courseId: courseId,
            due: Date(),
            estimatedMinutes: 60,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.7,
            importance: 0.8,
            type: .homework,
            locked: false
        )
    }
}
