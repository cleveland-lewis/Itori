import XCTest
@testable import Roots

#if os(macOS)
@MainActor
final class macOSMenuBarViewModelTests: XCTestCase {
    var viewModel: MenuBarViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = MenuBarViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testMenuBarViewModelInitializesWithDefaultValues() {
        XCTAssertEqual(viewModel.mode, .pomodoro)
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertEqual(viewModel.remainingSeconds, 0)
        XCTAssertEqual(viewModel.elapsedSeconds, 0)
        XCTAssertEqual(viewModel.pomodoroSessions, 0)
        XCTAssertEqual(viewModel.completedPomodoroSessions, 0)
        XCTAssertFalse(viewModel.isPomodorBreak)
        XCTAssertNil(viewModel.selectedActivityID)
        XCTAssertTrue(viewModel.activities.isEmpty)
        XCTAssertTrue(viewModel.sessions.isEmpty)
    }
    
    // MARK: - Mode Management Tests
    
    func testMenuBarViewModelCanSwitchModes() {
        viewModel.mode = .timer
        XCTAssertEqual(viewModel.mode, .timer)
        
        viewModel.mode = .pomodoro
        XCTAssertEqual(viewModel.mode, .pomodoro)
        
        viewModel.mode = .stopwatch
        XCTAssertEqual(viewModel.mode, .stopwatch)
    }
    
    // MARK: - Timer State Tests
    
    func testMenuBarViewModelTracksRunningState() {
        XCTAssertFalse(viewModel.isRunning)
        
        viewModel.isRunning = true
        XCTAssertTrue(viewModel.isRunning)
        
        viewModel.isRunning = false
        XCTAssertFalse(viewModel.isRunning)
    }
    
    func testMenuBarViewModelTracksTimeValues() {
        viewModel.remainingSeconds = 1500
        XCTAssertEqual(viewModel.remainingSeconds, 1500)
        
        viewModel.elapsedSeconds = 300
        XCTAssertEqual(viewModel.elapsedSeconds, 300)
    }
    
    // MARK: - Pomodoro Session Tests
    
    func testMenuBarViewModelTracksPomodoroSessions() {
        viewModel.pomodoroSessions = 4
        XCTAssertEqual(viewModel.pomodoroSessions, 4)
        
        viewModel.completedPomodoroSessions = 2
        XCTAssertEqual(viewModel.completedPomodoroSessions, 2)
    }
    
    func testMenuBarViewModelTracksBreakState() {
        viewModel.isPomodorBreak = true
        XCTAssertTrue(viewModel.isPomodorBreak)
        
        viewModel.isPomodorBreak = false
        XCTAssertFalse(viewModel.isPomodorBreak)
    }
    
    // MARK: - Activity Selection Tests
    
    func testMenuBarViewModelHandlesActivitySelection() {
        let activityId = UUID()
        viewModel.selectedActivityID = activityId
        XCTAssertEqual(viewModel.selectedActivityID, activityId)
        
        viewModel.selectedActivityID = nil
        XCTAssertNil(viewModel.selectedActivityID)
    }
    
    // MARK: - Activities Management Tests
    
    func testMenuBarViewModelManagesActivitiesList() {
        let activity1 = LocalTimerActivity(
            id: UUID(),
            name: "Study Math",
            colorHex: "#FF0000",
            createdAt: Date()
        )
        let activity2 = LocalTimerActivity(
            id: UUID(),
            name: "Read Book",
            colorHex: "#00FF00",
            createdAt: Date()
        )
        
        viewModel.activities = [activity1, activity2]
        XCTAssertEqual(viewModel.activities.count, 2)
        XCTAssertEqual(viewModel.activities[0].name, "Study Math")
        XCTAssertEqual(viewModel.activities[1].name, "Read Book")
    }
    
    // MARK: - Sessions Management Tests
    
    func testMenuBarViewModelManagesSessionsList() {
        let session1 = LocalTimerSession(
            id: UUID(),
            mode: .pomodoro,
            startTime: Date(),
            endTime: nil,
            elapsedSeconds: 300,
            activityId: nil
        )
        let session2 = LocalTimerSession(
            id: UUID(),
            mode: .timer,
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            elapsedSeconds: 600,
            activityId: nil
        )
        
        viewModel.sessions = [session1, session2]
        XCTAssertEqual(viewModel.sessions.count, 2)
        XCTAssertEqual(viewModel.sessions[0].mode, .pomodoro)
        XCTAssertEqual(viewModel.sessions[1].mode, .timer)
        XCTAssertNil(viewModel.sessions[0].endTime)
        XCTAssertNotNil(viewModel.sessions[1].endTime)
    }
    
    // MARK: - Published Properties Tests
    
    func testMenuBarViewModelPropertiesArePublished() async {
        let expectation = expectation(description: "Mode change published")
        var cancellables = Set<AnyCancellable>()
        
        viewModel.$mode
            .dropFirst()
            .sink { mode in
                XCTAssertEqual(mode, .timer)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.mode = .timer
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
#endif

import Combine
