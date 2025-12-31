//
//  AssignmentsStoreTests.swift
//  RootsTests
//
//  Tests for AssignmentsStore - Core task management functionality
//

import XCTest
@testable import Roots

@MainActor
final class AssignmentsStoreTests: BaseTestCase {
    
    // MARK: - Properties
    
    var store: AssignmentsStore!
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        store = AssignmentsStore()
    }
    
    override func tearDownWithError() throws {
        store = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Task Creation Tests
    
    func testCreateTask() {
        // Given
        let task = mockData.createTask(title: "New Assignment")
        
        // When
        store.addTask(task)
        
        // Then
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.id, task.id)
        XCTAssertEqual(store.tasks.first?.title, "New Assignment")
    }
    
    func testCreateMultipleTasks() {
        // Given
        let tasks = mockData.createTaskBatch(count: 5)
        
        // When
        tasks.forEach { store.addTask($0) }
        
        // Then
        XCTAssertEqual(store.tasks.count, 5)
    }
    
    // MARK: - Task Update Tests
    
    func testUpdateTaskTitle() {
        // Given
        var task = mockData.createTask(title: "Original Title")
        store.addTask(task)
        
        // When
        task = AppTask(
            id: task.id,
            title: "Updated Title",
            courseId: task.courseId,
            due: task.due,
            estimatedMinutes: task.estimatedMinutes,
            minBlockMinutes: task.minBlockMinutes,
            maxBlockMinutes: task.maxBlockMinutes,
            difficulty: task.difficulty,
            importance: task.importance,
            type: task.type,
            locked: task.locked,
            isCompleted: task.isCompleted
        )
        store.updateTask(task)
        
        // Then
        XCTAssertEqual(store.tasks.first?.title, "Updated Title")
    }
    
    func testUpdateTaskCompletion() {
        // Given
        var task = mockData.createTask()
        store.addTask(task)
        XCTAssertFalse(task.isCompleted)
        
        // When
        task = AppTask(
            id: task.id,
            title: task.title,
            courseId: task.courseId,
            due: task.due,
            estimatedMinutes: task.estimatedMinutes,
            minBlockMinutes: task.minBlockMinutes,
            maxBlockMinutes: task.maxBlockMinutes,
            difficulty: task.difficulty,
            importance: task.importance,
            type: task.type,
            locked: task.locked,
            isCompleted: true
        )
        store.updateTask(task)
        
        // Then
        XCTAssertTrue(store.tasks.first?.isCompleted ?? false)
    }
    
    // MARK: - Task Deletion Tests
    
    func testDeleteTask() {
        // Given
        let task = mockData.createTask()
        store.addTask(task)
        XCTAssertEqual(store.tasks.count, 1)
        
        // When
        store.removeTask(id: task.id)
        
        // Then
        XCTAssertEqual(store.tasks.count, 0)
    }
    
    func testDeleteNonexistentTask() {
        // Given
        let task = mockData.createTask()
        store.addTask(task)
        let fakeId = UUID()
        
        // When
        store.removeTask(id: fakeId)
        
        // Then - should not remove the task
        XCTAssertEqual(store.tasks.count, 1)
    }
    
    // MARK: - Task Filtering Tests
    
    func testFilterTasksByType() {
        // Given
        store.addTask(mockData.createHomeworkTask())
        store.addTask(mockData.createQuizTask())
        store.addTask(mockData.createExamTask())
        
        // When
        let homeworkTasks = store.tasks.filter { $0.type == .homework }
        
        // Then
        XCTAssertEqual(homeworkTasks.count, 1)
        XCTAssertEqual(homeworkTasks.first?.type, .homework)
    }
    
    func testFilterTasksByCompletion() {
        // Given
        let completedTask = mockData.createTask(isCompleted: true)
        let incompleteTask = mockData.createTask(isCompleted: false)
        store.addTask(completedTask)
        store.addTask(incompleteTask)
        
        // When
        let completed = store.tasks.filter { $0.isCompleted }
        let incomplete = store.tasks.filter { !$0.isCompleted }
        
        // Then
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(incomplete.count, 1)
    }
    
    // MARK: - Due Date Tests
    
    func testTasksSortedByDueDate() {
        // Given
        let tomorrow = Date().addingTimeInterval(86400)
        let nextWeek = Date().addingTimeInterval(86400 * 7)
        let today = Date()
        
        store.addTask(mockData.createTask(title: "Next Week", due: nextWeek))
        store.addTask(mockData.createTask(title: "Tomorrow", due: tomorrow))
        store.addTask(mockData.createTask(title: "Today", due: today))
        
        // When
        let sorted = store.tasks.sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
        
        // Then
        XCTAssertEqual(sorted[0].title, "Today")
        XCTAssertEqual(sorted[1].title, "Tomorrow")
        XCTAssertEqual(sorted[2].title, "Next Week")
    }
    
    func testOverdueTasks() {
        // Given
        let past = Date().addingTimeInterval(-86400) // Yesterday
        let future = Date().addingTimeInterval(86400) // Tomorrow
        
        store.addTask(mockData.createTask(title: "Overdue", due: past))
        store.addTask(mockData.createTask(title: "Upcoming", due: future))
        
        // When
        let overdue = store.tasks.filter { 
            if let due = $0.due, due < Date(), !$0.isCompleted {
                return true
            }
            return false
        }
        
        // Then
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue")
    }
    
    // MARK: - Edge Cases
    
    func testTaskWithNilDueDate() {
        // Given
        let task = mockData.createTask(due: nil)
        
        // When
        store.addTask(task)
        
        // Then
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertNil(store.tasks.first?.due)
    }
    
    func testTaskWithZeroEstimatedMinutes() {
        // Given
        let task = mockData.createTask(estimatedMinutes: 0)
        
        // When
        store.addTask(task)
        
        // Then
        XCTAssertEqual(store.tasks.first?.estimatedMinutes, 0)
    }
    
    func testTaskWithExtremeImportance() {
        // Given
        let maxImportance = mockData.createTask(importance: 1.0)
        let minImportance = mockData.createTask(importance: 0.0)
        
        // When
        store.addTask(maxImportance)
        store.addTask(minImportance)
        
        // Then
        XCTAssertEqual(store.tasks.count, 2)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceBulkInsert() {
        measure {
            let tasks = mockData.createTaskBatch(count: 100)
            tasks.forEach { store.addTask($0) }
        }
    }
    
    func testPerformanceFiltering() {
        // Setup
        let tasks = mockData.createTaskBatch(count: 1000)
        tasks.forEach { store.addTask($0) }
        
        measure {
            _ = store.tasks.filter { $0.type == .homework }
        }
    }
}
