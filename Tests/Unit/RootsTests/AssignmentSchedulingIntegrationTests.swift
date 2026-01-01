//
//  AssignmentSchedulingIntegrationTests.swift
//  RootsTests
//
//  Integration tests for assignment → planner → calendar flow
//

import XCTest
@testable import Roots

@MainActor
final class AssignmentSchedulingIntegrationTests: BaseTestCase {
    
    var assignmentsStore: AssignmentsStore!
    var coursesStore: CoursesStore!
    var tempDir: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let assignmentsURL = tempDir.appendingPathComponent("assignments.json")
        let coursesURL = tempDir.appendingPathComponent("courses.json")
        
        assignmentsStore = AssignmentsStore(storageURL: assignmentsURL)
        coursesStore = CoursesStore(storageURL: coursesURL)
    }
    
    override func tearDownWithError() throws {
        assignmentsStore = nil
        coursesStore?.clear()
        coursesStore = nil
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Assignment Creation Flow
    
    func testCreateAssignmentUpdatesStore() {
        let course = Course(name: "CS 101", courseCode: "CS101", semesterId: UUID())
        coursesStore.addCourse(course)
        
        var assignment = Assignment(courseId: course.id, name: "Homework 1", dueDate: Date())
        assignment.id = UUID()
        
        assignmentsStore.createTask(assignment)
        
        XCTAssertEqual(assignmentsStore.tasks.count, 1)
        XCTAssertEqual(assignmentsStore.tasks.first?.name, "Homework 1")
        XCTAssertEqual(assignmentsStore.tasks.first?.courseId, course.id)
    }
    
    func testUpdateAssignmentReflectsInStore() {
        var assignment = Assignment(courseId: UUID(), name: "Essay", dueDate: Date())
        assignment.id = UUID()
        
        assignmentsStore.createTask(assignment)
        
        var updated = assignment
        updated.name = "Research Essay"
        updated.isCompleted = true
        
        assignmentsStore.updateTask(updated)
        
        let stored = assignmentsStore.tasks.first
        XCTAssertEqual(stored?.name, "Research Essay")
        XCTAssertTrue(stored?.isCompleted ?? false)
    }
    
    func testDeleteAssignmentRemovesFromStore() {
        var assignment = Assignment(courseId: UUID(), name: "Quiz", dueDate: Date())
        assignment.id = UUID()
        
        assignmentsStore.createTask(assignment)
        XCTAssertEqual(assignmentsStore.tasks.count, 1)
        
        assignmentsStore.deleteTask(assignment.id)
        XCTAssertEqual(assignmentsStore.tasks.count, 0)
    }
    
    // MARK: - Assignment-Course Relationship
    
    func testAssignmentLinkedToCourse() {
        let course = Course(name: "Math 200", courseCode: "MATH200", semesterId: UUID())
        coursesStore.addCourse(course)
        
        var assignment = Assignment(courseId: course.id, name: "Problem Set", dueDate: Date())
        assignment.id = UUID()
        
        assignmentsStore.createTask(assignment)
        
        let stored = assignmentsStore.tasks.first
        XCTAssertEqual(stored?.courseId, course.id)
        
        // Verify course still exists
        XCTAssertNotNil(coursesStore.allCourses.first { $0.id == course.id })
    }
    
    func testMultipleAssignmentsForSameCourse() {
        let course = Course(name: "Physics", courseCode: "PHYS101", semesterId: UUID())
        coursesStore.addCourse(course)
        
        for i in 1...3 {
            var assignment = Assignment(courseId: course.id, name: "Lab \(i)", dueDate: Date())
            assignment.id = UUID()
            assignmentsStore.createTask(assignment)
        }
        
        let courseAssignments = assignmentsStore.tasks.filter { $0.courseId == course.id }
        XCTAssertEqual(courseAssignments.count, 3)
    }
    
    // MARK: - Completion & Status Flow
    
    func testMarkingAssignmentComplete() {
        var assignment = Assignment(courseId: UUID(), name: "Exam Prep", dueDate: Date())
        assignment.id = UUID()
        
        assignmentsStore.createTask(assignment)
        
        var updated = assignment
        updated.isCompleted = true
        assignmentsStore.updateTask(updated)
        
        let completed = assignmentsStore.tasks.first?.isCompleted
        XCTAssertTrue(completed ?? false)
    }
    
    func testOverdueAssignmentDetection() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var assignment = Assignment(courseId: UUID(), name: "Late Work", dueDate: yesterday)
        assignment.id = UUID()
        
        assignmentsStore.createTask(assignment)
        
        let stored = assignmentsStore.tasks.first
        XCTAssertNotNil(stored)
        XCTAssertTrue(stored!.dueDate < Date())
    }
}
