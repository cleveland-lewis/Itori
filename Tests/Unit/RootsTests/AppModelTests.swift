//
//  AppModelTests.swift
//  RootsTests
//
//  Tests for AppModel - Global app state management
//

import XCTest
import Combine
@testable import Roots

@MainActor
final class AppModelTests: BaseTestCase {
    
    var appModel: AppModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        appModel = AppModel()
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        appModel = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultState() {
        XCTAssertEqual(appModel.selectedPage, .dashboard)
        XCTAssertNil(appModel.requestedAssignmentDueDate)
        XCTAssertFalse(appModel.isPresentingAddHomework)
        XCTAssertFalse(appModel.isPresentingAddExam)
        XCTAssertNil(appModel.focusDeepLink)
        XCTAssertFalse(appModel.focusWindowRequested)
    }
    
    // MARK: - Page Selection Tests
    
    func testChangeSelectedPage() {
        appModel.selectedPage = .calendar
        XCTAssertEqual(appModel.selectedPage, .calendar)
        
        appModel.selectedPage = .planner
        XCTAssertEqual(appModel.selectedPage, .planner)
    }
    
    func testSelectedPagePublishes() {
        let expectation = XCTestExpectation(description: "Selected page published")
        
        appModel.$selectedPage
            .dropFirst()
            .sink { page in
                XCTAssertEqual(page, .assignments)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        appModel.selectedPage = .assignments
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Assignment Due Date Tests
    
    func testSetRequestedAssignmentDueDate() {
        let date = Date()
        appModel.requestedAssignmentDueDate = date
        
        XCTAssertEqual(appModel.requestedAssignmentDueDate, date)
    }
    
    func testClearRequestedAssignmentDueDate() {
        appModel.requestedAssignmentDueDate = Date()
        appModel.requestedAssignmentDueDate = nil
        
        XCTAssertNil(appModel.requestedAssignmentDueDate)
    }
    
    // MARK: - Modal Presentation Tests
    
    func testTogglePresentingAddHomework() {
        XCTAssertFalse(appModel.isPresentingAddHomework)
        
        appModel.isPresentingAddHomework = true
        XCTAssertTrue(appModel.isPresentingAddHomework)
        
        appModel.isPresentingAddHomework = false
        XCTAssertFalse(appModel.isPresentingAddHomework)
    }
    
    func testTogglePresentingAddExam() {
        XCTAssertFalse(appModel.isPresentingAddExam)
        
        appModel.isPresentingAddExam = true
        XCTAssertTrue(appModel.isPresentingAddExam)
        
        appModel.isPresentingAddExam = false
        XCTAssertFalse(appModel.isPresentingAddExam)
    }
    
    // MARK: - Focus Deep Link Tests
    
    func testSetFocusDeepLink() {
        let deepLink = FocusDeepLink(mode: .pomodoro, activityId: UUID())
        
        appModel.focusDeepLink = deepLink
        
        XCTAssertEqual(appModel.focusDeepLink?.mode, .pomodoro)
        XCTAssertNotNil(appModel.focusDeepLink?.activityId)
    }
    
    func testFocusDeepLinkWithModeOnly() {
        let deepLink = FocusDeepLink(mode: .stopwatch, activityId: nil)
        
        appModel.focusDeepLink = deepLink
        
        XCTAssertEqual(appModel.focusDeepLink?.mode, .stopwatch)
        XCTAssertNil(appModel.focusDeepLink?.activityId)
    }
    
    func testClearFocusDeepLink() {
        appModel.focusDeepLink = FocusDeepLink(mode: .pomodoro, activityId: UUID())
        appModel.focusDeepLink = nil
        
        XCTAssertNil(appModel.focusDeepLink)
    }
    
    // MARK: - Focus Window Tests
    
    func testFocusWindowRequest() {
        XCTAssertFalse(appModel.focusWindowRequested)
        
        appModel.focusWindowRequested = true
        XCTAssertTrue(appModel.focusWindowRequested)
        
        appModel.focusWindowRequested = false
        XCTAssertFalse(appModel.focusWindowRequested)
    }
    
    // MARK: - Reset Publisher Tests
    
    func testRequestReset() {
        let expectation = XCTestExpectation(description: "Reset published")
        
        appModel.resetPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        appModel.requestReset()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMultipleResetRequests() {
        var resetCount = 0
        
        appModel.resetPublisher
            .sink { _ in
                resetCount += 1
            }
            .store(in: &cancellables)
        
        appModel.requestReset()
        appModel.requestReset()
        appModel.requestReset()
        
        XCTAssertEqual(resetCount, 3)
    }
    
    // MARK: - FocusDeepLink Tests
    
    func testFocusDeepLinkInitialization() {
        let activityId = UUID()
        let deepLink = FocusDeepLink(mode: .pomodoro, activityId: activityId)
        
        XCTAssertEqual(deepLink.mode, .pomodoro)
        XCTAssertEqual(deepLink.activityId, activityId)
    }
    
    func testFocusDeepLinkNilValues() {
        let deepLink = FocusDeepLink(mode: nil, activityId: nil)
        
        XCTAssertNil(deepLink.mode)
        XCTAssertNil(deepLink.activityId)
    }
    
    // MARK: - Multiple Property Changes
    
    func testMultiplePropertyChanges() {
        appModel.selectedPage = .calendar
        appModel.isPresentingAddHomework = true
        appModel.requestedAssignmentDueDate = Date()
        
        XCTAssertEqual(appModel.selectedPage, .calendar)
        XCTAssertTrue(appModel.isPresentingAddHomework)
        XCTAssertNotNil(appModel.requestedAssignmentDueDate)
    }
}
