//
//  DurationEstimatorTests.swift
//  RootsTests
//
//  Tests for DurationEstimator - Assignment duration estimation
//

import XCTest
@testable import Roots

@MainActor
final class DurationEstimatorTests: BaseTestCase {
    
    // MARK: - Estimated Duration Tests
    
    func testEstimatedDurationWithNoLearningData() {
        let course = mockData.createCourse()
        let learningData: [String: CategoryLearningData] = [:]
        
        let estimate = DurationEstimator.estimatedDuration(
            category: .homework,
            course: course,
            learningData: learningData
        )
        
        XCTAssertGreaterThan(estimate, 0)
    }
    
    func testEstimatedDurationUsesBaseValues() {
        let course = mockData.createCourse()
        let learningData: [String: CategoryLearningData] = [:]
        
        let readingEstimate = DurationEstimator.estimatedDuration(
            category: .reading,
            course: course,
            learningData: learningData
        )
        
        let homeworkEstimate = DurationEstimator.estimatedDuration(
            category: .homework,
            course: course,
            learningData: learningData
        )
        
        // Homework should take longer than reading
        XCTAssertGreaterThan(homeworkEstimate, readingEstimate)
    }
    
    func testEstimatedDurationWithLearningData() {
        let course = mockData.createCourse()
        var learningData: [String: CategoryLearningData] = [:]
        
        let key = DurationEstimator.learningKey(courseId: course.id, category: .homework)
        var categoryData = CategoryLearningData(courseId: course.id, category: .homework)
        categoryData.record(actualMinutes: 60)
        categoryData.record(actualMinutes: 65)
        categoryData.record(actualMinutes: 70)
        learningData[key] = categoryData
        
        let estimate = DurationEstimator.estimatedDuration(
            category: .homework,
            course: course,
            learningData: learningData
        )
        
        // Should use learned average
        XCTAssertGreaterThan(estimate, 50)
        XCTAssertLessThan(estimate, 80)
    }
    
    // MARK: - Decomposition Hint Tests
    
    func testDecompositionHintReading() {
        let dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let hint = DurationEstimator.decompositionHint(
            category: .reading,
            estimatedMinutes: 45,
            dueDate: dueDate
        )
        
        XCTAssertTrue(hint.contains("same day"))
    }
    
    func testDecompositionHintHomework() {
        let dueDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let hint = DurationEstimator.decompositionHint(
            category: .homework,
            estimatedMinutes: 60,
            dueDate: dueDate
        )
        
        XCTAssertTrue(hint.contains("over 2 days"))
    }
    
    func testDecompositionHintReviewLongTerm() {
        let dueDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let hint = DurationEstimator.decompositionHint(
            category: .review,
            estimatedMinutes: 90,
            dueDate: dueDate
        )
        
        XCTAssertTrue(hint.contains("spaced"))
    }
    
    func testDecompositionHintProjectLongTerm() {
        let dueDate = Calendar.current.date(byAdding: .day, value: 20, to: Date())!
        let hint = DurationEstimator.decompositionHint(
            category: .project,
            estimatedMinutes: 240,
            dueDate: dueDate
        )
        
        XCTAssertTrue(hint.contains("weeks"))
    }
    
    func testDecompositionHintExam() {
        let dueDate = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        let hint = DurationEstimator.decompositionHint(
            category: .exam,
            estimatedMinutes: 180,
            dueDate: dueDate
        )
        
        XCTAssertTrue(hint.contains("spaced"))
    }
    
    func testDecompositionHintQuiz() {
        let dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let hint = DurationEstimator.decompositionHint(
            category: .quiz,
            estimatedMinutes: 30,
            dueDate: dueDate
        )
        
        XCTAssertTrue(hint.contains("24h"))
    }
    
    // MARK: - Learning Key Tests
    
    func testLearningKeyFormat() {
        let courseId = UUID()
        let key = DurationEstimator.learningKey(courseId: courseId, category: .homework)
        
        XCTAssertTrue(key.contains("_"))
        XCTAssertTrue(key.contains(courseId.uuidString))
        XCTAssertTrue(key.contains("homework"))
    }
    
    func testLearningKeyUniqueness() {
        let courseId1 = UUID()
        let courseId2 = UUID()
        
        let key1 = DurationEstimator.learningKey(courseId: courseId1, category: .homework)
        let key2 = DurationEstimator.learningKey(courseId: courseId2, category: .homework)
        let key3 = DurationEstimator.learningKey(courseId: courseId1, category: .reading)
        
        XCTAssertNotEqual(key1, key2)
        XCTAssertNotEqual(key1, key3)
    }
}

// MARK: - CategoryLearningData Tests

@MainActor
final class CategoryLearningDataTests: BaseTestCase {
    
    func testCategoryLearningDataInitialization() {
        let courseId = UUID()
        let data = CategoryLearningData(courseId: courseId, category: .homework)
        
        XCTAssertEqual(data.courseId, courseId)
        XCTAssertEqual(data.category, .homework)
        XCTAssertEqual(data.completedCount, 0)
        XCTAssertEqual(data.averageMinutes, 0)
    }
    
    func testRecordFirstCompletion() {
        var data = CategoryLearningData(courseId: UUID(), category: .homework)
        
        data.record(actualMinutes: 60)
        
        XCTAssertEqual(data.completedCount, 1)
        XCTAssertEqual(data.averageMinutes, 60.0)
    }
    
    func testRecordMultipleCompletions() {
        var data = CategoryLearningData(courseId: UUID(), category: .homework)
        
        data.record(actualMinutes: 60)
        data.record(actualMinutes: 80)
        
        XCTAssertEqual(data.completedCount, 2)
        // EWMA: 0.3 * 80 + 0.7 * 60 = 24 + 42 = 66
        XCTAssertEqual(data.averageMinutes, 66.0, accuracy: 0.1)
    }
    
    func testRecordEWMACalculation() {
        var data = CategoryLearningData(courseId: UUID(), category: .homework)
        
        data.record(actualMinutes: 100)
        data.record(actualMinutes: 50)
        data.record(actualMinutes: 75)
        
        XCTAssertEqual(data.completedCount, 3)
        // Should be weighted toward recent values
        XCTAssertGreaterThan(data.averageMinutes, 60)
        XCTAssertLessThan(data.averageMinutes, 90)
    }
    
    func testHasEnoughDataFalse() {
        var data = CategoryLearningData(courseId: UUID(), category: .homework)
        
        XCTAssertFalse(data.hasEnoughData)
        
        data.record(actualMinutes: 60)
        XCTAssertFalse(data.hasEnoughData)
        
        data.record(actualMinutes: 70)
        XCTAssertFalse(data.hasEnoughData)
    }
    
    func testHasEnoughDataTrue() {
        var data = CategoryLearningData(courseId: UUID(), category: .homework)
        
        data.record(actualMinutes: 60)
        data.record(actualMinutes: 70)
        data.record(actualMinutes: 65)
        
        XCTAssertTrue(data.hasEnoughData)
    }
    
    func testCategoryLearningDataCodable() throws {
        let data = CategoryLearningData(courseId: UUID(), category: .homework)
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(data)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CategoryLearningData.self, from: encoded)
        
        XCTAssertEqual(decoded.courseId, data.courseId)
        XCTAssertEqual(decoded.category, data.category)
        XCTAssertEqual(decoded.completedCount, data.completedCount)
    }
}

// MARK: - AssignmentCategory Extension Tests

@MainActor
final class AssignmentCategoryDurationTests: BaseTestCase {
    
    func testBaseEstimateMinutes() {
        XCTAssertEqual(AssignmentCategory.reading.baseEstimateMinutes, 45)
        XCTAssertEqual(AssignmentCategory.homework.baseEstimateMinutes, 75)
        XCTAssertEqual(AssignmentCategory.review.baseEstimateMinutes, 60)
        XCTAssertEqual(AssignmentCategory.project.baseEstimateMinutes, 120)
        XCTAssertEqual(AssignmentCategory.exam.baseEstimateMinutes, 180)
        XCTAssertEqual(AssignmentCategory.quiz.baseEstimateMinutes, 30)
    }
    
    func testStepSize() {
        XCTAssertEqual(AssignmentCategory.reading.stepSize, 5)
        XCTAssertEqual(AssignmentCategory.homework.stepSize, 10)
        XCTAssertEqual(AssignmentCategory.review.stepSize, 5)
        XCTAssertEqual(AssignmentCategory.project.stepSize, 15)
        XCTAssertEqual(AssignmentCategory.exam.stepSize, 15)
        XCTAssertEqual(AssignmentCategory.quiz.stepSize, 5)
    }
    
    func testBaseEstimateOrdering() {
        // Exam should be longest
        XCTAssertGreaterThan(AssignmentCategory.exam.baseEstimateMinutes, 
                            AssignmentCategory.project.baseEstimateMinutes)
        
        // Quiz should be shortest
        XCTAssertLessThan(AssignmentCategory.quiz.baseEstimateMinutes,
                         AssignmentCategory.reading.baseEstimateMinutes)
    }
}
