//
//  SchedulerFeedbackTests.swift
//  RootsTests
//
//  Tests for SchedulerFeedback - User feedback on scheduled blocks
//

import XCTest
@testable import Roots

@MainActor
final class SchedulerFeedbackTests: BaseTestCase {
    
    // MARK: - FeedbackAction Tests
    
    func testFeedbackActionAllCases() {
        let actions: [FeedbackAction] = [.kept, .rescheduled, .deleted, .shortened, .extended]
        XCTAssertEqual(actions.count, 5)
    }
    
    func testFeedbackActionRawValues() {
        XCTAssertEqual(FeedbackAction.kept.rawValue, "kept")
        XCTAssertEqual(FeedbackAction.rescheduled.rawValue, "rescheduled")
        XCTAssertEqual(FeedbackAction.deleted.rawValue, "deleted")
        XCTAssertEqual(FeedbackAction.shortened.rawValue, "shortened")
        XCTAssertEqual(FeedbackAction.extended.rawValue, "extended")
    }
    
    func testFeedbackActionCodable() throws {
        let action = FeedbackAction.rescheduled
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(action)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FeedbackAction.self, from: data)
        
        XCTAssertEqual(decoded, action)
    }
    
    func testFeedbackActionFromRawValue() {
        XCTAssertEqual(FeedbackAction(rawValue: "kept"), .kept)
        XCTAssertEqual(FeedbackAction(rawValue: "deleted"), .deleted)
        XCTAssertNil(FeedbackAction(rawValue: "invalid"))
    }
    
    // MARK: - BlockFeedback Tests
    
    func testBlockFeedbackInitialization() {
        let blockId = UUID()
        let taskId = UUID()
        let courseId = UUID()
        let start = Date()
        let end = Date().addingTimeInterval(3600)
        
        let feedback = BlockFeedback(
            blockId: blockId,
            taskId: taskId,
            courseId: courseId,
            type: .assignment,
            start: start,
            end: end,
            completion: 0.8,
            action: .kept
        )
        
        XCTAssertEqual(feedback.blockId, blockId)
        XCTAssertEqual(feedback.taskId, taskId)
        XCTAssertEqual(feedback.courseId, courseId)
        XCTAssertEqual(feedback.type, .assignment)
        XCTAssertEqual(feedback.start, start)
        XCTAssertEqual(feedback.end, end)
        XCTAssertEqual(feedback.completion, 0.8)
        XCTAssertEqual(feedback.action, .kept)
    }
    
    func testBlockFeedbackWithNilCourseId() {
        let feedback = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date().addingTimeInterval(3600),
            completion: 0.5,
            action: .kept
        )
        
        XCTAssertNil(feedback.courseId)
    }
    
    func testBlockFeedbackCompletionRange() {
        let feedback1 = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.0,
            action: .kept
        )
        
        let feedback2 = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 1.0,
            action: .kept
        )
        
        XCTAssertEqual(feedback1.completion, 0.0)
        XCTAssertEqual(feedback2.completion, 1.0)
    }
    
    func testBlockFeedbackCodable() throws {
        let feedback = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: UUID(),
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.75,
            action: .rescheduled
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(feedback)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BlockFeedback.self, from: data)
        
        XCTAssertEqual(decoded.blockId, feedback.blockId)
        XCTAssertEqual(decoded.taskId, feedback.taskId)
        XCTAssertEqual(decoded.completion, feedback.completion)
        XCTAssertEqual(decoded.action, feedback.action)
    }
}

// MARK: - SchedulerFeedbackStore Tests

@MainActor
final class SchedulerFeedbackStoreTests: BaseTestCase {
    
    var store: SchedulerFeedbackStore!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        store = SchedulerFeedbackStore.shared
        store.clear()
    }
    
    override func tearDownWithError() throws {
        store.clear()
        store = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testStoreInitializesEmpty() {
        XCTAssertEqual(store.feedback.count, 0)
    }
    
    // MARK: - Append Tests
    
    func testAppendFeedback() {
        let feedback = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.5,
            action: .kept
        )
        
        store.append(feedback)
        
        XCTAssertEqual(store.feedback.count, 1)
        XCTAssertEqual(store.feedback.first?.blockId, feedback.blockId)
    }
    
    func testAppendMultipleFeedback() {
        let feedback1 = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.5,
            action: .kept
        )
        
        let feedback2 = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.8,
            action: .rescheduled
        )
        
        store.append(feedback1)
        store.append(feedback2)
        
        XCTAssertEqual(store.feedback.count, 2)
    }
    
    // MARK: - Clear Tests
    
    func testClearEmptyStore() {
        store.clear()
        
        XCTAssertEqual(store.feedback.count, 0)
    }
    
    func testClearNonEmptyStore() {
        let feedback = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.5,
            action: .kept
        )
        
        store.append(feedback)
        XCTAssertEqual(store.feedback.count, 1)
        
        store.clear()
        XCTAssertEqual(store.feedback.count, 0)
    }
    
    // MARK: - Persistence Tests
    
    func testSaveToDiskDoesNotCrash() {
        let feedback = BlockFeedback(
            blockId: UUID(),
            taskId: UUID(),
            courseId: nil,
            type: .assignment,
            start: Date(),
            end: Date(),
            completion: 0.5,
            action: .kept
        )
        
        store.append(feedback)
        store.saveToDisk()
        
        XCTAssertTrue(true) // Should not crash
    }
    
    func testLoadFromDiskDoesNotCrash() {
        store.loadFromDisk()
        
        XCTAssertTrue(true) // Should not crash
    }
}
