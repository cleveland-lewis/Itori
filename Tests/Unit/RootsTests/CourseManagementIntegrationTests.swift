//
//  CourseManagementIntegrationTests.swift
//  RootsTests
//
//  Integration tests for course updates → UI refresh flow
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class CourseManagementIntegrationTests: BaseTestCase {
    
    var coursesStore: CoursesStore!
    var assignmentsStore: AssignmentsStore!
    var tempDir: URL!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let coursesURL = tempDir.appendingPathComponent("courses.json")
        let assignmentsURL = tempDir.appendingPathComponent("assignments.json")
        
        coursesStore = CoursesStore(storageURL: coursesURL)
        assignmentsStore = AssignmentsStore(storageURL: assignmentsURL)
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        assignmentsStore = nil
        coursesStore?.clear()
        coursesStore = nil
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Course CRUD Operations
    
    func testAddCoursePublishesUpdate() {
        let expectation = XCTestExpectation(description: "Course added")
        
        coursesStore.$courses
            .dropFirst() // Skip initial value
            .sink { courses in
                if courses.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let course = Course(name: "Biology", courseCode: "BIO101", semesterId: UUID())
        coursesStore.addCourse(course)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(coursesStore.allCourses.count, 1)
    }
    
    func testUpdateCoursePublishesChange() {
        var course = Course(name: "Chemistry", courseCode: "CHEM101", semesterId: UUID())
        coursesStore.addCourse(course)
        
        let expectation = XCTestExpectation(description: "Course updated")
        
        coursesStore.$courses
            .dropFirst() // Skip current value
            .sink { courses in
                if let updated = courses.first, updated.name == "Advanced Chemistry" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        course.name = "Advanced Chemistry"
        coursesStore.updateCourse(course)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(coursesStore.allCourses.first?.name, "Advanced Chemistry")
    }
    
    func testDeleteCoursePublishesRemoval() {
        let course = Course(name: "History", courseCode: "HIST101", semesterId: UUID())
        coursesStore.addCourse(course)
        
        let expectation = XCTestExpectation(description: "Course deleted")
        
        coursesStore.$courses
            .dropFirst()
            .sink { courses in
                if courses.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        coursesStore.deleteCourse(course)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(coursesStore.allCourses.isEmpty)
    }
    
    // MARK: - Semester Management
    
    func testAddSemesterUpdatesStore() {
        let semester = Semester(name: "Fall 2024", startDate: Date(), endDate: Date())
        coursesStore.addSemester(semester)
        
        XCTAssertEqual(coursesStore.semesters.count, 1)
        XCTAssertEqual(coursesStore.semesters.first?.name, "Fall 2024")
    }
    
    func testSetCurrentSemester() {
        let semester1 = Semester(name: "Spring 2024", startDate: Date(), endDate: Date())
        let semester2 = Semester(name: "Fall 2024", startDate: Date(), endDate: Date())
        
        coursesStore.addSemester(semester1)
        coursesStore.addSemester(semester2)
        
        coursesStore.currentSemesterId = semester2.id
        
        XCTAssertEqual(coursesStore.currentSemesterId, semester2.id)
        XCTAssertTrue(coursesStore.semesters.first { $0.id == semester2.id }?.isCurrent ?? false)
    }
    
    // MARK: - Course Filtering
    
    func testActiveCoursesFiltering() {
        var activeCourse = Course(name: "Active", courseCode: "ACT", semesterId: UUID())
        activeCourse.isArchived = false
        
        var archivedCourse = Course(name: "Archived", courseCode: "ARC", semesterId: UUID())
        archivedCourse.isArchived = true
        
        coursesStore.addCourse(activeCourse)
        coursesStore.addCourse(archivedCourse)
        
        XCTAssertEqual(coursesStore.activeCourses.count, 1)
        XCTAssertEqual(coursesStore.activeCourses.first?.name, "Active")
    }
    
    func testArchivedCoursesFiltering() {
        var activeCourse = Course(name: "Active", courseCode: "ACT", semesterId: UUID())
        activeCourse.isArchived = false
        
        var archivedCourse = Course(name: "Archived", courseCode: "ARC", semesterId: UUID())
        archivedCourse.isArchived = true
        
        coursesStore.addCourse(activeCourse)
        coursesStore.addCourse(archivedCourse)
        
        XCTAssertEqual(coursesStore.archivedCourses.count, 1)
        XCTAssertEqual(coursesStore.archivedCourses.first?.name, "Archived")
    }
    
    // MARK: - GPA Calculation Integration
    
    func testGPAUpdatesWhenCourseGradeChanges() {
        var course = Course(name: "Math", courseCode: "MATH", semesterId: UUID())
        course.currentGrade = 95.0
        
        coursesStore.addCourse(course)
        
        // GPA should reflect the course grade
        XCTAssertGreaterThan(coursesStore.currentGPA, 0)
    }
}
