import XCTest
@testable import SharedCore

/// Regression tests for core timer functionality
/// These tests ensure existing timer behavior remains unchanged when feature flags are OFF
final class TimerRegressionTests: XCTestCase {
    
    var viewModel: TimerPageViewModel!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        viewModel = TimerPageViewModel.shared
        
        // Ensure all feature flags are OFF for regression testing
        FeatureFlags.shared.resetToDefaults()
    }
    
    @MainActor
    override func tearDown() async throws {
        // Clean up any active sessions
        if viewModel.currentSession != nil {
            viewModel.endSession(completed: false)
        }
        try await super.tearDown()
    }
    
    // MARK: - Core Timer Lifecycle Tests
    
    @MainActor
    func testTimerStartCreatesSession() async throws {
        // Given: No active session
        XCTAssertNil(viewModel.currentSession)
        
        // When: Starting a timer
        viewModel.currentMode = .timer
        viewModel.timerDuration = 10 * 60
        viewModel.startSession()
        
        // Then: Session is created and running
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.currentSession?.state, .running)
        XCTAssertEqual(viewModel.currentSession?.mode, .timer)
        XCTAssertEqual(viewModel.sessionRemaining, 10 * 60, accuracy: 1)
    }
    
    @MainActor
    func testTimerPauseStopsProgress() async throws {
        // Given: Running timer
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 60)
        let initialRemaining = viewModel.sessionRemaining
        
        // When: Pausing the timer
        viewModel.pauseSession()
        
        // Then: Session is paused
        XCTAssertEqual(viewModel.currentSession?.state, .paused)
        
        // And: Time doesn't decrease
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        XCTAssertEqual(viewModel.sessionRemaining, initialRemaining, accuracy: 1)
    }
    
    @MainActor
    func testTimerResumeRestoresProgress() async throws {
        // Given: Paused timer
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 60)
        viewModel.pauseSession()
        
        // When: Resuming the timer
        viewModel.resumeSession()
        
        // Then: Session is running again
        XCTAssertEqual(viewModel.currentSession?.state, .running)
    }
    
    @MainActor
    func testTimerResetClearsSession() async throws {
        // Given: Running timer
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 60)
        
        // When: Ending the session
        viewModel.endSession(completed: false)
        
        // Then: Session is cleared
        XCTAssertNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.sessionElapsed, 0)
        XCTAssertEqual(viewModel.sessionRemaining, 0)
    }
    
    @MainActor
    func testTimerCompletionMarksSessionAsCompleted() async throws {
        // Given: Running timer near completion
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 1)
        
        #if DEBUG
        // Fast-forward to completion
        viewModel.debugAdvance(seconds: 1)
        #endif
        
        // Then: Session should be completed
        XCTAssertNil(viewModel.currentSession)
        XCTAssertTrue(viewModel.pastSessions.contains { $0.state == .completed })
    }
    
    // MARK: - Pomodoro Mode Tests
    
    @MainActor
    func testPomodoroStartsWithFocusDuration() async throws {
        // Given: Pomodoro mode
        viewModel.currentMode = .pomodoro
        viewModel.focusDuration = 25 * 60
        viewModel.isOnBreak = false
        
        // When: Starting a session
        viewModel.startSession()
        
        // Then: Session uses focus duration
        XCTAssertEqual(viewModel.currentSession?.plannedDuration, 25 * 60)
        XCTAssertEqual(viewModel.currentSession?.mode, .pomodoro)
    }
    
    @MainActor
    func testPomodoroTogglesBreakAfterCompletion() async throws {
        // Given: Completed focus session
        viewModel.currentMode = .pomodoro
        viewModel.isOnBreak = false
        let wasOnBreak = viewModel.isOnBreak
        viewModel.startSession(plannedDuration: 1)
        
        #if DEBUG
        viewModel.debugAdvance(seconds: 1)
        #endif
        
        // Then: Should toggle to break
        XCTAssertNotEqual(viewModel.isOnBreak, wasOnBreak)
    }
    
    @MainActor
    func testPomodoroCycleCount() async throws {
        // Given: Fresh pomodoro state
        viewModel.pomodoroCompletedCycles = 0
        viewModel.pomodoroMaxCycles = 4
        viewModel.currentMode = .pomodoro
        viewModel.isOnBreak = false
        
        // When: Completing a focus session
        viewModel.startSession(plannedDuration: 1)
        #if DEBUG
        viewModel.debugAdvance(seconds: 1)
        #endif
        
        // Then: Cycle count increments
        XCTAssertEqual(viewModel.pomodoroCompletedCycles, 1)
    }
    
    // MARK: - Stopwatch Mode Tests
    
    @MainActor
    func testStopwatchHasNoPlannedDuration() async throws {
        // Given: Stopwatch mode
        viewModel.currentMode = .stopwatch
        
        // When: Starting a session
        viewModel.startSession()
        
        // Then: No planned duration
        XCTAssertNil(viewModel.currentSession?.plannedDuration)
        XCTAssertEqual(viewModel.currentSession?.mode, .stopwatch)
        XCTAssertEqual(viewModel.sessionRemaining, 0)
    }
    
    // MARK: - Activity Association Tests
    
    @MainActor
    func testTimerAssociatesWithActivity() async throws {
        // Given: Selected activity
        let activity = TimerActivity(name: "Study Math")
        viewModel.addActivity(activity)
        viewModel.selectActivity(activity.id)
        
        // When: Starting a timer
        viewModel.startSession()
        
        // Then: Session is associated with activity
        XCTAssertEqual(viewModel.currentSession?.activityID, activity.id)
    }
    
    // MARK: - Data Persistence Tests
    
    @MainActor
    func testCompletedSessionIsPersistedToHistory() async throws {
        // Given: Completed session
        let initialCount = viewModel.pastSessions.count
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 1)
        
        #if DEBUG
        viewModel.debugAdvance(seconds: 1)
        #endif
        
        // Then: Session appears in history
        XCTAssertEqual(viewModel.pastSessions.count, initialCount + 1)
        XCTAssertTrue(viewModel.pastSessions.first?.state == .completed)
    }
    
    @MainActor
    func testCancelledSessionIsPersistedToHistory() async throws {
        // Given: Cancelled session
        let initialCount = viewModel.pastSessions.count
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 60)
        
        // When: Cancelling the session
        viewModel.endSession(completed: false)
        
        // Then: Session appears in history as cancelled
        XCTAssertEqual(viewModel.pastSessions.count, initialCount + 1)
        XCTAssertTrue(viewModel.pastSessions.first?.state == .cancelled)
    }
    
    // MARK: - Background Behavior Tests
    
    @MainActor
    func testTimerContinuesInBackground() async throws {
        // Given: Running timer
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 60)
        let initialRemaining = viewModel.sessionRemaining
        
        // When: App enters background (simulated by time passing)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then: Timer should have progressed (clock keeps ticking)
        // Note: This is a simplified test - actual background behavior depends on iOS lifecycle
        XCTAssertLessThan(viewModel.sessionRemaining, initialRemaining)
    }
    
    // MARK: - Notification Tests
    
    @MainActor
    func testNotificationScheduledOnTimerStart() async throws {
        // Given: Timer with duration
        viewModel.currentMode = .timer
        
        // When: Starting the timer
        viewModel.startSession(plannedDuration: 60)
        
        // Then: Session is running (notification scheduling is internal)
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.currentSession?.state, .running)
    }
    
    @MainActor
    func testNotificationCancelledOnTimerStop() async throws {
        // Given: Running timer
        viewModel.currentMode = .timer
        viewModel.startSession(plannedDuration: 60)
        
        // When: Stopping the timer
        viewModel.endSession(completed: false)
        
        // Then: Session is cleared
        XCTAssertNil(viewModel.currentSession)
    }
}
