//
//  PlannerCoordinatorTests.swift
//  RootsTests
//
//  Tests for PlannerCoordinator - Planner navigation state
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class PlannerCoordinatorTests: BaseTestCase {
    
    var coordinator: PlannerCoordinator!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        coordinator = PlannerCoordinator()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        coordinator = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultState() {
        XCTAssertNil(coordinator.requestedCourseId)
        XCTAssertNil(coordinator.requestedDate)
        XCTAssertNil(coordinator.selectedCourseFilter)
    }
    
    // MARK: - Open Planner with Course Tests
    
    func testOpenPlannerWithCourseId() {
        let courseId = UUID()
        
        coordinator.openPlanner(with: courseId)
        
        XCTAssertEqual(coordinator.requestedCourseId, courseId)
        XCTAssertEqual(coordinator.selectedCourseFilter, courseId)
    }
    
    func testOpenPlannerWithNilCourse() {
        coordinator.openPlanner(with: nil)
        
        XCTAssertNil(coordinator.requestedCourseId)
        XCTAssertNil(coordinator.selectedCourseFilter)
    }
    
    func testOpenPlannerWithCoursePublishes() {
        let expectation = XCTestExpectation(description: "Course published")
        let courseId = UUID()
        
        coordinator.$requestedCourseId
            .dropFirst()
            .sink { id in
                XCTAssertEqual(id, courseId)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        coordinator.openPlanner(with: courseId)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Open Planner for Date Tests
    
    func testOpenPlannerForDate() {
        let date = Date()
        
        coordinator.openPlanner(for: date)
        
        XCTAssertEqual(coordinator.requestedDate, date)
    }
    
    func testOpenPlannerForDateWithCourse() {
        let date = Date()
        let courseId = UUID()
        
        coordinator.openPlanner(for: date, courseId: courseId)
        
        XCTAssertEqual(coordinator.requestedDate, date)
        XCTAssertEqual(coordinator.requestedCourseId, courseId)
        XCTAssertEqual(coordinator.selectedCourseFilter, courseId)
    }
    
    func testOpenPlannerForNilDate() {
        coordinator.openPlanner(for: nil)
        
        XCTAssertNil(coordinator.requestedDate)
    }
    
    func testOpenPlannerForDatePublishes() {
        let expectation = XCTestExpectation(description: "Date published")
        let date = Date()
        
        coordinator.$requestedDate
            .dropFirst()
            .sink { requestedDate in
                XCTAssertEqual(requestedDate, date)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        coordinator.openPlanner(for: date)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Selected Course Filter Tests
    
    func testSelectedCourseFilterPersists() {
        let courseId = UUID()
        
        coordinator.openPlanner(with: courseId)
        
        XCTAssertEqual(coordinator.selectedCourseFilter, courseId)
        
        // Filter should persist even after requestedCourseId is cleared
        coordinator.requestedCourseId = nil
        XCTAssertEqual(coordinator.selectedCourseFilter, courseId)
    }
    
    func testSelectedCourseFilterPublishes() {
        let expectation = XCTestExpectation(description: "Filter published")
        let courseId = UUID()
        
        coordinator.$selectedCourseFilter
            .dropFirst()
            .sink { filter in
                XCTAssertEqual(filter, courseId)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        coordinator.openPlanner(with: courseId)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Multiple Operations Tests
    
    func testOpenPlannerMultipleTimes() {
        let course1 = UUID()
        let course2 = UUID()
        
        coordinator.openPlanner(with: course1)
        XCTAssertEqual(coordinator.requestedCourseId, course1)
        
        coordinator.openPlanner(with: course2)
        XCTAssertEqual(coordinator.requestedCourseId, course2)
        XCTAssertEqual(coordinator.selectedCourseFilter, course2)
    }
    
    func testOpenPlannerWithDateThenCourse() {
        let date = Date()
        let courseId = UUID()
        
        coordinator.openPlanner(for: date)
        coordinator.openPlanner(with: courseId)
        
        XCTAssertEqual(coordinator.requestedDate, date)
        XCTAssertEqual(coordinator.requestedCourseId, courseId)
    }
    
    func testClearRequestedValues() {
        let date = Date()
        let courseId = UUID()
        
        coordinator.openPlanner(for: date, courseId: courseId)
        
        coordinator.requestedDate = nil
        coordinator.requestedCourseId = nil
        
        XCTAssertNil(coordinator.requestedDate)
        XCTAssertNil(coordinator.requestedCourseId)
        XCTAssertEqual(coordinator.selectedCourseFilter, courseId) // Filter persists
    }
    
    // MARK: - Edge Cases
    
    func testOpenPlannerWithSameCourseMultipleTimes() {
        let courseId = UUID()
        
        coordinator.openPlanner(with: courseId)
        coordinator.openPlanner(with: courseId)
        
        XCTAssertEqual(coordinator.requestedCourseId, courseId)
    }
    
    func testOpenPlannerForSameDateMultipleTimes() {
        let date = Date()
        
        coordinator.openPlanner(for: date)
        coordinator.openPlanner(for: date)
        
        XCTAssertEqual(coordinator.requestedDate, date)
    }
}
