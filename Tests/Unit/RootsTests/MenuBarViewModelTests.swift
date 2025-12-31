import XCTest
@testable import Roots

@MainActor
final class MenuBarViewModelTests: XCTestCase {
    var viewModel: MenuBarViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = MenuBarViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
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
    
    func testModeCanBeChanged() {
        viewModel.mode = .timer
        XCTAssertEqual(viewModel.mode, .timer)
        
        viewModel.mode = .stopwatch
        XCTAssertEqual(viewModel.mode, .stopwatch)
    }
    
    func testActivitySelectionChanges() {
        let activityID = UUID()
        viewModel.selectedActivityID = activityID
        XCTAssertEqual(viewModel.selectedActivityID, activityID)
    }
    
    func testPomodoroBreakStateToggles() {
        XCTAssertFalse(viewModel.isPomodorBreak)
        
        viewModel.isPomodorBreak = true
        XCTAssertTrue(viewModel.isPomodorBreak)
    }
    
    func testCompletedSessionsIncrement() {
        XCTAssertEqual(viewModel.completedPomodoroSessions, 0)
        
        viewModel.completedPomodoroSessions += 1
        XCTAssertEqual(viewModel.completedPomodoroSessions, 1)
    }
}
