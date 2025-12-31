//
//  AssignmentsStoreBasicTests.swift
//  RootsTests
//
//  Tests for AssignmentsStore - Basic CRUD operations
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class AssignmentsStoreBasicTests: BaseTestCase {
    
    var store: AssignmentsStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        store = AssignmentsStore.shared
        store.resetAll()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        store = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Add Task Tests
    
    func testAddTask() {
        let task = mockData.createTask(title: "Test Task")
        
        store.addTask(task)
        
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.title, "Test Task")
    }
    
    func testAddMultipleTasks() {
        let task1 = mockData.createTask(title: "Task 1")
        let task2 = mockData.createTask(title: "Task 2")
        
        store.addTask(task1)
        store.addTask(task2)
        
        XCTAssertEqual(store.tasks.count, 2)
    }
    
    // MARK: - Remove Task Tests
    
    func testRemoveTask() {
        let task = mockData.createTask()
        store.addTask(task)
        
        store.removeTask(id: task.id)
        
        XCTAssertEqual(store.tasks.count, 0)
    }
    
    func testRemoveNonexistentTask() {
        store.removeTask(id: UUID())
        XCTAssertEqual(store.tasks.count, 0)
    }
    
    // MARK: - Update Task Tests
    
    func testUpdateTask() {
        var task = mockData.createTask(title: "Original")
        store.addTask(task)
        
        task.title = "Updated"
        store.updateTask(task)
        
        XCTAssertEqual(store.tasks.first?.title, "Updated")
    }
    
    func testUpdateTaskCompletion() {
        var task = mockData.createTask()
        store.addTask(task)
        
        task.completed = true
        store.updateTask(task)
        
        XCTAssertTrue(store.tasks.first?.completed ?? false)
    }
    
    func testUpdateNonexistentTask() {
        let task = mockData.createTask()
        store.updateTask(task)
        XCTAssertEqual(store.tasks.count, 0)
    }
    
    // MARK: - Incomplete Tasks Tests
    
    func testIncompleteTasksFiltering() {
        let incomplete = mockData.createTask(title: "Incomplete")
        var complete = mockData.createTask(title: "Complete")
        complete.completed = true
        
        store.addTask(incomplete)
        store.addTask(complete)
        
        let incompleteTasks = store.incompleteTasks()
        
        XCTAssertEqual(incompleteTasks.count, 1)
        XCTAssertEqual(incompleteTasks.first?.title, "Incomplete")
    }
    
    func testIncompleteTasksEmpty() {
        var task = mockData.createTask()
        task.completed = true
        store.addTask(task)
        
        XCTAssertEqual(store.incompleteTasks().count, 0)
    }
    
    // MARK: - Reassign Tasks Tests
    
    func testReassignTasksToCourse() {
        let oldCourseId = UUID()
        let newCourseId = UUID()
        
        var task = mockData.createTask()
        task.courseId = oldCourseId
        store.addTask(task)
        
        store.reassignTasks(fromCourseId: oldCourseId, toCourseId: newCourseId)
        
        XCTAssertEqual(store.tasks.first?.courseId, newCourseId)
    }
    
    func testReassignTasksToNil() {
        let oldCourseId = UUID()
        
        var task = mockData.createTask()
        task.courseId = oldCourseId
        store.addTask(task)
        
        store.reassignTasks(fromCourseId: oldCourseId, toCourseId: nil)
        
        XCTAssertNil(store.tasks.first?.courseId)
    }
    
    // MARK: - Reset Tests
    
    func testResetAll() {
        store.addTask(mockData.createTask())
        store.addTask(mockData.createTask())
        
        store.resetAll()
        
        XCTAssertEqual(store.tasks.count, 0)
    }
    
    // MARK: - Published Property Tests
    
    func testTasksPublished() {
        let expectation = XCTestExpectation(description: "Tasks published")
        
        store.$tasks
            .dropFirst()
            .sink { tasks in
                XCTAssertEqual(tasks.count, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        store.addTask(mockData.createTask())
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Edge Cases
    
    func testAddTaskWithEmptyTitle() {
        let task = mockData.createTask(title: "")
        store.addTask(task)
        
        XCTAssertEqual(store.tasks.first?.title, "")
    }
    
    func testAddTaskWithFutureDueDate() {
        var task = mockData.createTask()
        task.dueDate = Date().addingTimeInterval(86400 * 7)
        
        store.addTask(task)
        
        XCTAssertNotNil(store.tasks.first?.dueDate)
    }
    
    func testAddTaskWithPastDueDate() {
        var task = mockData.createTask()
        task.dueDate = Date().addingTimeInterval(-86400 * 7)
        
        store.addTask(task)
        
        XCTAssertNotNil(store.tasks.first?.dueDate)
    }
    
    func testMultipleUpdatesToSameTask() {
        var task = mockData.createTask(title: "Original")
        store.addTask(task)
        
        task.title = "Update 1"
        store.updateTask(task)
        
        task.title = "Update 2"
        store.updateTask(task)
        
        task.title = "Final"
        store.updateTask(task)
        
        XCTAssertEqual(store.tasks.first?.title, "Final")
    }
}
