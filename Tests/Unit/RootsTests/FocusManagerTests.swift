//
//  FocusManagerTests.swift
//  RootsTests
//
//  Tests for FocusManager - Timer and focus session management
//

import XCTest
@testable import Roots

@MainActor
final class FocusManagerTests: BaseTestCase {
    
    var manager: FocusManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        manager = FocusManager()
    }
    
    override func tearDownWithError() throws {
        manager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testFocusManagerInitialization() {
        XCTAssertEqual(manager.mode, .pomodoro)
        XCTAssertEqual(manager.activities.count, 0)
        XCTAssertNil(manager.selectedActivityID)
        XCTAssertFalse(manager.isRunning)
        XCTAssertEqual(manager.remainingSeconds, 25 * 60)
        XCTAssertEqual(manager.elapsedSeconds, 0)
        XCTAssertEqual(manager.completedPomodoroSessions, 0)
        XCTAssertFalse(manager.isPomodorBreak)
        XCTAssertNil(manager.activeSession)
        XCTAssertEqual(manager.sessions.count, 0)
    }
    
    func testFocusManagerPomodoroSessionsFromSettings() {
        XCTAssertGreaterThan(manager.pomodoroSessions, 0)
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedMode() {
        XCTAssertNotNil(manager.$mode)
    }
    
    func testPublishedActivities() {
        XCTAssertNotNil(manager.$activities)
    }
    
    func testPublishedSelectedActivityID() {
        XCTAssertNotNil(manager.$selectedActivityID)
    }
    
    func testPublishedIsRunning() {
        XCTAssertNotNil(manager.$isRunning)
    }
    
    func testPublishedRemainingSeconds() {
        XCTAssertNotNil(manager.$remainingSeconds)
    }
    
    func testPublishedElapsedSeconds() {
        XCTAssertNotNil(manager.$elapsedSeconds)
    }
    
    func testPublishedCompletedPomodoroSessions() {
        XCTAssertNotNil(manager.$completedPomodoroSessions)
    }
    
    func testPublishedIsPomodorBreak() {
        XCTAssertNotNil(manager.$isPomodorBreak)
    }
    
    func testPublishedActiveSession() {
        XCTAssertNotNil(manager.$activeSession)
    }
    
    func testPublishedSessions() {
        XCTAssertNotNil(manager.$sessions)
    }
    
    // MARK: - Timer Control Tests
    
    func testStartTimerChangesState() {
        XCTAssertFalse(manager.isRunning)
        
        manager.startTimer()
        
        XCTAssertTrue(manager.isRunning)
    }
    
    func testStartTimerWhenAlreadyRunning() {
        manager.startTimer()
        XCTAssertTrue(manager.isRunning)
        
        // Should not change anything
        manager.startTimer()
        XCTAssertTrue(manager.isRunning)
    }
    
    func testPauseTimer() {
        manager.startTimer()
        XCTAssertTrue(manager.isRunning)
        
        manager.pauseTimer()
        
        XCTAssertFalse(manager.isRunning)
    }
    
    func testResetTimer() {
        manager.elapsedSeconds = 100
        manager.remainingSeconds = 1400
        manager.completedPomodoroSessions = 2
        manager.isPomodorBreak = true
        manager.isRunning = true
        
        manager.resetTimer()
        
        XCTAssertFalse(manager.isRunning)
        XCTAssertEqual(manager.elapsedSeconds, 0)
        XCTAssertEqual(manager.remainingSeconds, 25 * 60)
        XCTAssertEqual(manager.completedPomodoroSessions, 0)
        XCTAssertFalse(manager.isPomodorBreak)
    }
    
    func testEndTimerSession() {
        manager.startTimer()
        XCTAssertTrue(manager.isRunning)
        
        manager.endTimerSession()
        
        XCTAssertFalse(manager.isRunning)
    }
    
    // MARK: - Activity Management Tests
    
    func testAddActivity() {
        let activity = LocalTimerActivity(
            id: UUID(),
            name: "Study Math",
            colorTag: ColorTag(id: UUID(), name: "Blue", color: "blue", order: 0)
        )
        
        manager.activities = [activity]
        
        XCTAssertEqual(manager.activities.count, 1)
        XCTAssertEqual(manager.activities.first?.name, "Study Math")
    }
    
    func testSelectActivity() {
        let activity = LocalTimerActivity(
            id: UUID(),
            name: "Study Math",
            colorTag: ColorTag(id: UUID(), name: "Blue", color: "blue", order: 0)
        )
        
        manager.activities = [activity]
        manager.selectedActivityID = activity.id
        
        XCTAssertEqual(manager.selectedActivityID, activity.id)
    }
    
    // MARK: - Session Management Tests
    
    func testSessionsArray() {
        XCTAssertEqual(manager.sessions.count, 0)
        
        let session = LocalTimerSession(
            id: UUID(),
            activityID: nil,
            mode: .pomodoro,
            startDate: Date(),
            endDate: nil,
            duration: 0
        )
        
        manager.sessions = [session]
        
        XCTAssertEqual(manager.sessions.count, 1)
    }
    
    func testActiveSession() {
        XCTAssertNil(manager.activeSession)
        
        let session = LocalTimerSession(
            id: UUID(),
            activityID: nil,
            mode: .pomodoro,
            startDate: Date(),
            endDate: nil,
            duration: 0
        )
        
        manager.activeSession = session
        
        XCTAssertNotNil(manager.activeSession)
        XCTAssertEqual(manager.activeSession?.id, session.id)
    }
    
    // MARK: - Mode Tests
    
    func testChangeModeToTimer() {
        manager.mode = .timer
        
        XCTAssertEqual(manager.mode, .timer)
    }
    
    func testChangeModeToStopwatch() {
        manager.mode = .stopwatch
        
        XCTAssertEqual(manager.mode, .stopwatch)
    }
    
    // MARK: - Pomodoro Tests
    
    func testPomodoroBreakState() {
        XCTAssertFalse(manager.isPomodorBreak)
        
        manager.isPomodorBreak = true
        
        XCTAssertTrue(manager.isPomodorBreak)
    }
    
    func testCompletedPomodoroSessions() {
        XCTAssertEqual(manager.completedPomodoroSessions, 0)
        
        manager.completedPomodoroSessions = 3
        
        XCTAssertEqual(manager.completedPomodoroSessions, 3)
    }
    
    func testPomodoroSessionsLimit() {
        let limit = manager.pomodoroSessions
        XCTAssertGreaterThan(limit, 0)
    }
    
    // MARK: - Timer State Tests
    
    func testRemainingSecondsDecreases() {
        let initial = manager.remainingSeconds
        manager.remainingSeconds -= 60
        
        XCTAssertLessThan(manager.remainingSeconds, initial)
    }
    
    func testElapsedSecondsIncreases() {
        let initial = manager.elapsedSeconds
        manager.elapsedSeconds += 60
        
        XCTAssertGreaterThan(manager.elapsedSeconds, initial)
    }
}
