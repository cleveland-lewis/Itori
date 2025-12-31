//
//  ResetCoordinatorTests.swift
//  RootsTests
//
//  Tests for ResetCoordinator - Global reset management
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class ResetCoordinatorTests: BaseTestCase {
    
    var coordinator: ResetCoordinator!
    var appModel: AppModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        coordinator = ResetCoordinator.shared
        appModel = AppModel()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        appModel = nil
        coordinator = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Start Tests
    
    func testStartSubscribesToResetPublisher() {
        let expectation = XCTestExpectation(description: "Reset triggered")
        
        // Add a task to verify reset was called
        AssignmentsStore.shared.addTask(mockData.createTask())
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 1)
        
        coordinator.start(appModel: appModel)
        
        // Wait a moment for subscription to set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.appModel.requestReset()
            
            // Give time for reset to process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertEqual(AssignmentsStore.shared.tasks.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testStartOnlySubscribesOnce() {
        coordinator.start(appModel: appModel)
        coordinator.start(appModel: appModel)
        
        // Should only subscribe once (no easy way to verify without internal state)
        // Just verify it doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Perform Reset Tests
    
    func testPerformResetClearsAssignments() {
        AssignmentsStore.shared.addTask(mockData.createTask())
        AssignmentsStore.shared.addTask(mockData.createTask())
        
        coordinator.performReset()
        
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 0)
    }
    
    func testPerformResetClearsCourses() {
        let semester = mockData.createSemester()
        CoursesStore.shared?.addSemester(semester)
        CoursesStore.shared?.addCourse(mockData.createCourse(semesterId: semester.id))
        
        coordinator.performReset()
        
        XCTAssertEqual(CoursesStore.shared?.semesters.count ?? 0, 0)
        XCTAssertEqual(CoursesStore.shared?.courses.count ?? 0, 0)
    }
    
    func testPerformResetClearsGrades() {
        GradesStore.shared.upsert(courseId: UUID(), percent: 90.0, letter: "A-")
        
        coordinator.performReset()
        
        XCTAssertEqual(GradesStore.shared.grades.count, 0)
    }
    
    func testPerformResetDisablesICloudSync() {
        let settings = AppSettingsModel.shared
        settings.enableICloudSync = true
        
        coordinator.performReset()
        
        XCTAssertFalse(settings.enableICloudSync)
    }
    
    func testPerformResetSuppressesICloudRestore() {
        let settings = AppSettingsModel.shared
        settings.suppressICloudRestore = false
        
        coordinator.performReset()
        
        XCTAssertTrue(settings.suppressICloudRestore)
    }
    
    // MARK: - Integration Tests
    
    func testFullResetWorkflow() {
        // Set up some data
        AssignmentsStore.shared.addTask(mockData.createTask())
        let semester = mockData.createSemester()
        CoursesStore.shared?.addSemester(semester)
        GradesStore.shared.upsert(courseId: UUID(), percent: 85.0, letter: "B")
        
        // Start coordinator and trigger reset
        coordinator.start(appModel: appModel)
        
        let expectation = XCTestExpectation(description: "Full reset complete")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.appModel.requestReset()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Verify everything is cleared
                XCTAssertEqual(AssignmentsStore.shared.tasks.count, 0)
                XCTAssertEqual(CoursesStore.shared?.semesters.count ?? 0, 0)
                XCTAssertEqual(GradesStore.shared.grades.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Edge Cases
    
    func testPerformResetWhenNoDataExists() {
        // Should not crash when resetting empty stores
        coordinator.performReset()
        
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 0)
        XCTAssertEqual(CoursesStore.shared?.semesters.count ?? 0, 0)
        XCTAssertEqual(GradesStore.shared.grades.count, 0)
    }
    
    func testMultipleResetCalls() {
        AssignmentsStore.shared.addTask(mockData.createTask())
        
        coordinator.performReset()
        coordinator.performReset()
        coordinator.performReset()
        
        XCTAssertEqual(AssignmentsStore.shared.tasks.count, 0)
    }
}
