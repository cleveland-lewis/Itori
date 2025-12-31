//
//  GradesStoreTests.swift
//  RootsTests
//
//  Tests for GradesStore - Grade management and persistence
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class GradesStoreTests: BaseTestCase {
    
    var store: GradesStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        store = GradesStore.shared
        store.resetAll()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        store?.resetAll()
        store = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(store.grades.count, 0)
        XCTAssertFalse(store.isLoading)
    }
    
    // MARK: - Upsert Tests
    
    func testUpsertNewGrade() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 85.5, letter: "B")
        
        XCTAssertEqual(store.grades.count, 1)
        XCTAssertEqual(store.grades.first?.courseId, courseId)
        XCTAssertEqual(store.grades.first?.percent, 85.5)
        XCTAssertEqual(store.grades.first?.letter, "B")
    }
    
    func testUpsertExistingGradeUpdates() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 80.0, letter: "B-")
        store.upsert(courseId: courseId, percent: 90.0, letter: "A-")
        
        XCTAssertEqual(store.grades.count, 1)
        XCTAssertEqual(store.grades.first?.percent, 90.0)
        XCTAssertEqual(store.grades.first?.letter, "A-")
    }
    
    func testUpsertWithNilPercent() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: nil, letter: "A")
        
        XCTAssertNil(store.grades.first?.percent)
        XCTAssertEqual(store.grades.first?.letter, "A")
    }
    
    func testUpsertWithNilLetter() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 92.5, letter: nil)
        
        XCTAssertEqual(store.grades.first?.percent, 92.5)
        XCTAssertNil(store.grades.first?.letter)
    }
    
    func testUpsertUpdatesTimestamp() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 80.0, letter: "B")
        let firstTimestamp = store.grades.first?.updatedAt
        
        // Small delay to ensure timestamp changes
        let expectation = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.store.upsert(courseId: courseId, percent: 85.0, letter: "B+")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let secondTimestamp = store.grades.first?.updatedAt
        XCTAssertNotEqual(firstTimestamp, secondTimestamp)
        XCTAssertTrue((secondTimestamp ?? Date.distantPast) > (firstTimestamp ?? Date.distantPast))
    }
    
    // MARK: - Grade Lookup Tests
    
    func testGradeForCourseId() {
        let courseId = UUID()
        store.upsert(courseId: courseId, percent: 88.0, letter: "B+")
        
        let grade = store.grade(for: courseId)
        
        XCTAssertNotNil(grade)
        XCTAssertEqual(grade?.percent, 88.0)
        XCTAssertEqual(grade?.letter, "B+")
    }
    
    func testGradeForNonexistentCourse() {
        let grade = store.grade(for: UUID())
        
        XCTAssertNil(grade)
    }
    
    // MARK: - Remove Tests
    
    func testRemoveGrade() {
        let courseId = UUID()
        store.upsert(courseId: courseId, percent: 90.0, letter: "A-")
        
        store.remove(courseId: courseId)
        
        XCTAssertEqual(store.grades.count, 0)
    }
    
    func testRemoveNonexistentGrade() {
        store.upsert(courseId: UUID(), percent: 90.0, letter: "A-")
        
        store.remove(courseId: UUID())
        
        XCTAssertEqual(store.grades.count, 1)
    }
    
    // MARK: - Reset Tests
    
    func testResetAll() {
        store.upsert(courseId: UUID(), percent: 85.0, letter: "B")
        store.upsert(courseId: UUID(), percent: 90.0, letter: "A-")
        
        store.resetAll()
        
        XCTAssertEqual(store.grades.count, 0)
    }
    
    // MARK: - Published Property Tests
    
    func testGradesPublished() {
        let expectation = XCTestExpectation(description: "Grades published")
        let courseId = UUID()
        
        store.$grades
            .dropFirst()
            .sink { grades in
                XCTAssertEqual(grades.count, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        store.upsert(courseId: courseId, percent: 88.0, letter: "B+")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Multiple Courses Tests
    
    func testMultipleCourseGrades() {
        let course1 = UUID()
        let course2 = UUID()
        let course3 = UUID()
        
        store.upsert(courseId: course1, percent: 85.0, letter: "B")
        store.upsert(courseId: course2, percent: 92.0, letter: "A-")
        store.upsert(courseId: course3, percent: 78.0, letter: "C+")
        
        XCTAssertEqual(store.grades.count, 3)
        XCTAssertEqual(store.grade(for: course1)?.percent, 85.0)
        XCTAssertEqual(store.grade(for: course2)?.percent, 92.0)
        XCTAssertEqual(store.grade(for: course3)?.percent, 78.0)
    }
    
    func testRemoveOneOfMultipleCourses() {
        let course1 = UUID()
        let course2 = UUID()
        
        store.upsert(courseId: course1, percent: 85.0, letter: "B")
        store.upsert(courseId: course2, percent: 92.0, letter: "A-")
        
        store.remove(courseId: course1)
        
        XCTAssertEqual(store.grades.count, 1)
        XCTAssertNil(store.grade(for: course1))
        XCTAssertNotNil(store.grade(for: course2))
    }
    
    // MARK: - Edge Cases
    
    func testUpsertWithZeroPercent() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 0.0, letter: "F")
        
        XCTAssertEqual(store.grades.first?.percent, 0.0)
    }
    
    func testUpsertWithHundredPercent() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 100.0, letter: "A+")
        
        XCTAssertEqual(store.grades.first?.percent, 100.0)
    }
    
    func testUpsertWithEmptyLetter() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: 85.0, letter: "")
        
        XCTAssertEqual(store.grades.first?.letter, "")
    }
    
    func testUpsertBothNil() {
        let courseId = UUID()
        
        store.upsert(courseId: courseId, percent: nil, letter: nil)
        
        XCTAssertEqual(store.grades.count, 1)
        XCTAssertNil(store.grades.first?.percent)
        XCTAssertNil(store.grades.first?.letter)
    }
}

// MARK: - GradeEntry Tests

@MainActor
final class GradeEntryTests: BaseTestCase {
    
    func testGradeEntryInitialization() {
        let courseId = UUID()
        let now = Date()
        
        let entry = GradeEntry(courseId: courseId, percent: 85.5, letter: "B", updatedAt: now)
        
        XCTAssertEqual(entry.id, courseId)
        XCTAssertEqual(entry.courseId, courseId)
        XCTAssertEqual(entry.percent, 85.5)
        XCTAssertEqual(entry.letter, "B")
        XCTAssertEqual(entry.updatedAt, now)
    }
    
    func testGradeEntryIdMatchesCourseId() {
        let courseId = UUID()
        let entry = GradeEntry(courseId: courseId, percent: 90.0, letter: "A-", updatedAt: Date())
        
        XCTAssertEqual(entry.id, entry.courseId)
    }
    
    func testGradeEntryCodable() throws {
        let entry = GradeEntry(courseId: UUID(), percent: 88.0, letter: "B+", updatedAt: Date())
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GradeEntry.self, from: data)
        
        XCTAssertEqual(decoded.courseId, entry.courseId)
        XCTAssertEqual(decoded.percent, entry.percent)
        XCTAssertEqual(decoded.letter, entry.letter)
    }
    
    func testGradeEntryHashable() {
        let courseId = UUID()
        let entry1 = GradeEntry(courseId: courseId, percent: 90.0, letter: "A-", updatedAt: Date())
        let entry2 = GradeEntry(courseId: courseId, percent: 90.0, letter: "A-", updatedAt: Date())
        
        XCTAssertEqual(entry1, entry2)
        
        var set = Set<GradeEntry>()
        set.insert(entry1)
        set.insert(entry2)
        
        XCTAssertEqual(set.count, 1)
    }
}
