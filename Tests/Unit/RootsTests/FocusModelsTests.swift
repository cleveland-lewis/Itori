//
//  FocusModelsTests.swift
//  RootsTests
//
//  Tests for FocusModels - Timer and focus session models
//

import XCTest
@testable import Roots

@MainActor
final class FocusModelsTests: BaseTestCase {
    
    // MARK: - LocalTimerMode Tests
    
    func testLocalTimerModeAllCases() {
        XCTAssertEqual(LocalTimerMode.allCases.count, 3)
        XCTAssertTrue(LocalTimerMode.allCases.contains(.pomodoro))
        XCTAssertTrue(LocalTimerMode.allCases.contains(.countdown))
        XCTAssertTrue(LocalTimerMode.allCases.contains(.stopwatch))
    }
    
    func testLocalTimerModeLabels() {
        XCTAssertEqual(LocalTimerMode.pomodoro.label, "Pomodoro")
        XCTAssertEqual(LocalTimerMode.countdown.label, "Timer")
        XCTAssertEqual(LocalTimerMode.stopwatch.label, "Stopwatch")
    }
    
    func testLocalTimerModeIdentifiable() {
        XCTAssertEqual(LocalTimerMode.pomodoro.id, "pomodoro")
        XCTAssertEqual(LocalTimerMode.countdown.id, "countdown")
        XCTAssertEqual(LocalTimerMode.stopwatch.id, "stopwatch")
    }
    
    func testLocalTimerModeCodable() throws {
        let mode = LocalTimerMode.pomodoro
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(mode)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LocalTimerMode.self, from: data)
        
        XCTAssertEqual(decoded, mode)
    }
    
    // MARK: - LocalTimerActivity Tests
    
    func testLocalTimerActivityInitialization() {
        let activity = LocalTimerActivity(
            id: UUID(),
            name: "Study Session",
            category: "Homework",
            courseCode: "CS101",
            assignmentTitle: "Project 1",
            colorTag: .blue,
            isPinned: true,
            totalTrackedSeconds: 3600,
            todayTrackedSeconds: 1800
        )
        
        XCTAssertEqual(activity.name, "Study Session")
        XCTAssertEqual(activity.category, "Homework")
        XCTAssertEqual(activity.courseCode, "CS101")
        XCTAssertEqual(activity.assignmentTitle, "Project 1")
        XCTAssertEqual(activity.colorTag, .blue)
        XCTAssertTrue(activity.isPinned)
        XCTAssertEqual(activity.totalTrackedSeconds, 3600)
        XCTAssertEqual(activity.todayTrackedSeconds, 1800)
    }
    
    func testLocalTimerActivityHashable() {
        let id = UUID()
        let activity1 = LocalTimerActivity(
            id: id,
            name: "Study",
            category: "Work",
            colorTag: .blue,
            isPinned: false,
            totalTrackedSeconds: 0,
            todayTrackedSeconds: 0
        )
        
        let activity2 = LocalTimerActivity(
            id: id,
            name: "Study",
            category: "Work",
            colorTag: .blue,
            isPinned: false,
            totalTrackedSeconds: 0,
            todayTrackedSeconds: 0
        )
        
        XCTAssertEqual(activity1, activity2)
        XCTAssertEqual(activity1.hashValue, activity2.hashValue)
    }
    
    // MARK: - LocalTimerSession Tests
    
    func testLocalTimerSessionPomodoroWork() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1500) // 25 minutes
        
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .pomodoro,
            startDate: startDate,
            endDate: endDate,
            duration: 1500,
            isBreakSession: false
        )
        
        XCTAssertEqual(session.mode, .pomodoro)
        XCTAssertEqual(session.duration, 1500)
        XCTAssertEqual(session.workSeconds, 1500)
        XCTAssertEqual(session.breakSeconds, 0)
        XCTAssertFalse(session.isBreakSession)
    }
    
    func testLocalTimerSessionPomodoroBreak() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(300) // 5 minutes
        
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .pomodoro,
            startDate: startDate,
            endDate: endDate,
            duration: 300,
            isBreakSession: true
        )
        
        XCTAssertEqual(session.mode, .pomodoro)
        XCTAssertEqual(session.duration, 300)
        XCTAssertEqual(session.workSeconds, 0)
        XCTAssertEqual(session.breakSeconds, 300)
        XCTAssertTrue(session.isBreakSession)
    }
    
    func testLocalTimerSessionCountdownMode() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(600)
        
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .countdown,
            startDate: startDate,
            endDate: endDate,
            duration: 600
        )
        
        XCTAssertEqual(session.mode, .countdown)
        XCTAssertEqual(session.workSeconds, 600)
        XCTAssertEqual(session.breakSeconds, 0)
        XCTAssertFalse(session.isBreakSession)
    }
    
    func testLocalTimerSessionStopwatchMode() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1234)
        
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .stopwatch,
            startDate: startDate,
            endDate: endDate,
            duration: 1234
        )
        
        XCTAssertEqual(session.mode, .stopwatch)
        XCTAssertEqual(session.workSeconds, 1234)
        XCTAssertEqual(session.breakSeconds, 0)
    }
    
    func testLocalTimerSessionCodable() throws {
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .pomodoro,
            startDate: Date(),
            endDate: Date(),
            duration: 1500,
            isBreakSession: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LocalTimerSession.self, from: data)
        
        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.mode, session.mode)
        XCTAssertEqual(decoded.duration, session.duration)
        XCTAssertEqual(decoded.workSeconds, session.workSeconds)
        XCTAssertEqual(decoded.breakSeconds, session.breakSeconds)
    }
    
    func testLocalTimerSessionHashable() {
        let id = UUID()
        let activityID = UUID()
        let startDate = Date()
        
        let session1 = LocalTimerSession(
            id: id,
            activityID: activityID,
            mode: .pomodoro,
            startDate: startDate,
            endDate: nil,
            duration: 1500
        )
        
        let session2 = LocalTimerSession(
            id: id,
            activityID: activityID,
            mode: .pomodoro,
            startDate: startDate,
            endDate: nil,
            duration: 1500
        )
        
        XCTAssertEqual(session1, session2)
    }
    
    // MARK: - Edge Cases
    
    func testLocalTimerSessionZeroDuration() {
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .countdown,
            startDate: Date(),
            endDate: Date(),
            duration: 0
        )
        
        XCTAssertEqual(session.duration, 0)
        XCTAssertEqual(session.workSeconds, 0)
    }
    
    func testLocalTimerSessionNilEndDate() {
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .stopwatch,
            startDate: Date(),
            endDate: nil,
            duration: 1000
        )
        
        XCTAssertNil(session.endDate)
        XCTAssertEqual(session.duration, 1000)
    }
    
    func testLocalTimerActivityWithOptionalFields() {
        let activity = LocalTimerActivity(
            id: UUID(),
            name: "Quick Task",
            category: "General",
            courseCode: nil,
            assignmentTitle: nil,
            colorTag: .blue,
            isPinned: false,
            totalTrackedSeconds: 0,
            todayTrackedSeconds: 0
        )
        
        XCTAssertNil(activity.courseCode)
        XCTAssertNil(activity.assignmentTitle)
    }
    
    func testLocalTimerSessionLongDuration() {
        // Test with a very long session (8 hours)
        let session = LocalTimerSession(
            id: UUID(),
            activityID: UUID(),
            mode: .stopwatch,
            startDate: Date(),
            endDate: Date().addingTimeInterval(28800),
            duration: 28800
        )
        
        XCTAssertEqual(session.duration, 28800)
        XCTAssertEqual(session.workSeconds, 28800)
    }
}
