//
//  DragDropTypesTests.swift
//  ItoriTests
//
//  Tests for drag & drop type system
//

import XCTest
@testable import Roots

final class DragDropTypesTests: XCTestCase {
    
    func testTransferableAssignmentCreation() {
        // Given
        let taskId = UUID()
        let courseId = UUID()
        let dueDate = Date()
        let task = AppTask(
            id: taskId,
            title: "Math Homework",
            courseId: courseId,
            due: dueDate,
            estimatedMinutes: 120,
            minBlockMinutes: 30,
            maxBlockMinutes: 60,
            difficulty: 0.7,
            importance: 0.8,
            type: .homework,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .homework
        )
        
        // When
        let transferable = TransferableAssignment(from: task)
        
        // Then
        XCTAssertEqual(transferable.id, taskId.uuidString)
        XCTAssertEqual(transferable.title, "Math Homework")
        XCTAssertEqual(transferable.courseId, courseId.uuidString)
        // AppTask normalizes dates to start of day
        XCTAssertEqual(transferable.dueDate, Calendar.current.startOfDay(for: dueDate))
        XCTAssertEqual(transferable.estimatedMinutes, 120)
    }
    
    func testTransferableAssignmentPlainText() {
        // Given
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dueDate = Date()
        
        let task = AppTask(
            id: UUID(),
            title: "Physics Lab Report",
            courseId: nil,
            due: dueDate,
            estimatedMinutes: 90,
            minBlockMinutes: 30,
            maxBlockMinutes: 90,
            difficulty: 0.5,
            importance: 0.6,
            type: .project,
            locked: false,
            attachments: [],
            isCompleted: false,
            category: .project
        )
        
        // When
        let transferable = TransferableAssignment(from: task)
        let plainText = transferable.plainTextRepresentation
        
        // Then
        XCTAssertTrue(plainText.contains("Physics Lab Report"))
        XCTAssertTrue(plainText.contains("Due:"))
        XCTAssertTrue(plainText.contains(formatter.string(from: dueDate)))
        XCTAssertTrue(plainText.contains("90 minutes"))
    }
    
    func testTransferableCourseWithCode() {
        // Given
        let course = TransferableCourse(
            id: UUID().uuidString,
            title: "Introduction to Computer Science",
            code: "CS101",
            semesterId: UUID().uuidString
        )
        
        // When
        let plainText = course.plainTextRepresentation
        
        // Then
        XCTAssertEqual(plainText, "CS101 - Introduction to Computer Science")
    }
    
    func testTransferableCourseWithoutCode() {
        // Given
        let course = TransferableCourse(
            id: UUID().uuidString,
            title: "Independent Study",
            code: "",
            semesterId: nil
        )
        
        // When
        let plainText = course.plainTextRepresentation
        
        // Then
        XCTAssertEqual(plainText, "Independent Study")
    }
    
    func testWindowStateEncoding() {
        // Given
        let assignmentId = UUID().uuidString
        let state = WindowState(
            windowId: .assignmentDetail,
            entityId: assignmentId,
            displayTitle: "Math Homework"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try? encoder.encode(state)
        
        // Then
        XCTAssertNotNil(data)
        
        // Verify round-trip
        let decoder = JSONDecoder()
        let decoded = try? decoder.decode(WindowState.self, from: data!)
        XCTAssertEqual(decoded?.windowId, WindowIdentifier.assignmentDetail.rawValue)
        XCTAssertEqual(decoded?.entityId, assignmentId)
        XCTAssertEqual(decoded?.displayTitle, "Math Homework")
    }
    
    func testWindowStateHash() {
        // Given
        let id1 = UUID().uuidString
        let state1 = WindowState(windowId: .assignmentDetail, entityId: id1)
        let state2 = WindowState(windowId: .assignmentDetail, entityId: id1)
        let state3 = WindowState(windowId: .courseDetail, entityId: id1)
        
        // Then
        XCTAssertEqual(state1, state2) // Same window type and entity
        XCTAssertNotEqual(state1, state3) // Different window type
    }
}
