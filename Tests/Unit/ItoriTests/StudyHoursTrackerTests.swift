//
//  StudyHoursTrackerTests.swift
//  ItoriTests
//
//  Tests for Phase D: Study hours tracking
//

import XCTest
@testable import Itori

@MainActor
final class StudyHoursTrackerTests: XCTestCase {
    
    var tracker: StudyHoursTracker!
    
    override func setUp() async throws {
        tracker = StudyHoursTracker.shared
        // Reset for clean test state
        tracker.resetAllTotals()
    }
    
    // MARK: - Session Recording Tests
    
    func testRecordSessionWhenEnabled() async {
        // Given: Tracking is enabled
        AppSettingsModel.shared.trackStudyHours = true
        
        let sessionId = UUID()
        let durationMinutes = 60
        
        // When: Recording a session
        tracker.recordCompletedSession(sessionId: sessionId, durationMinutes: durationMinutes)
        
        // Then: Totals should be updated
        XCTAssertEqual(tracker.totals.todayMinutes, 60)
        XCTAssertEqual(tracker.totals.weekMinutes, 60)
        XCTAssertEqual(tracker.totals.monthMinutes, 60)
    }
    
    func testNoRecordingWhenDisabled() async {
        // Given: Tracking is disabled
        AppSettingsModel.shared.trackStudyHours = false
        
        let sessionId = UUID()
        let durationMinutes = 45
        
        // When: Attempting to record
        tracker.recordCompletedSession(sessionId: sessionId, durationMinutes: durationMinutes)
        
        // Then: Totals should remain zero
        XCTAssertEqual(tracker.totals.todayMinutes, 0)
        XCTAssertEqual(tracker.totals.weekMinutes, 0)
        XCTAssertEqual(tracker.totals.monthMinutes, 0)
    }
    
    func testIdempotentRecording() async {
        // Given: Tracking is enabled
        AppSettingsModel.shared.trackStudyHours = true
        
        let sessionId = UUID()
        let durationMinutes = 30
        
        // When: Recording same session twice
        tracker.recordCompletedSession(sessionId: sessionId, durationMinutes: durationMinutes)
        tracker.recordCompletedSession(sessionId: sessionId, durationMinutes: durationMinutes)
        
        // Then: Should only count once
        XCTAssertEqual(tracker.totals.todayMinutes, 30, "Should not double-count same session")
        XCTAssertEqual(tracker.totals.weekMinutes, 30)
        XCTAssertEqual(tracker.totals.monthMinutes, 30)
    }
    
    func testMultipleSessionsAccumulate() async {
        // Given: Tracking is enabled
        AppSettingsModel.shared.trackStudyHours = true
        
        // When: Recording multiple different sessions
        tracker.recordCompletedSession(sessionId: UUID(), durationMinutes: 25)
        tracker.recordCompletedSession(sessionId: UUID(), durationMinutes: 30)
        tracker.recordCompletedSession(sessionId: UUID(), durationMinutes: 45)
        
        // Then: All durations should sum
        XCTAssertEqual(tracker.totals.todayMinutes, 100)
        XCTAssertEqual(tracker.totals.weekMinutes, 100)
        XCTAssertEqual(tracker.totals.monthMinutes, 100)
    }
    
    // MARK: - Formatting Tests
    
    func testFormatMinutesUnderOneHour() {
        let formatted = StudyHoursTotals.formatMinutes(45)
        XCTAssertEqual(formatted, "45m")
    }
    
    func testFormatMinutesExactHours() {
        let formatted = StudyHoursTotals.formatMinutes(120)
        XCTAssertEqual(formatted, "2h")
    }
    
    func testFormatMinutesHoursAndMinutes() {
        let formatted = StudyHoursTotals.formatMinutes(95)
        XCTAssertEqual(formatted, "1h 35m")
    }
    
    // MARK: - Reset Tests
    
    func testResetAllTotals() async {
        // Given: Some tracked time
        AppSettingsModel.shared.trackStudyHours = true
        tracker.recordCompletedSession(sessionId: UUID(), durationMinutes: 60)
        
        // When: Resetting
        tracker.resetAllTotals()
        
        // Then: All totals should be zero
        XCTAssertEqual(tracker.totals.todayMinutes, 0)
        XCTAssertEqual(tracker.totals.weekMinutes, 0)
        XCTAssertEqual(tracker.totals.monthMinutes, 0)
    }
    
    // MARK: - Decimal Hours Tests
    
    func testDecimalHourConversions() {
        var totals = StudyHoursTotals(todayMinutes: 90, weekMinutes: 180, monthMinutes: 360)
        
        XCTAssertEqual(totals.todayHours, 1.5, accuracy: 0.01)
        XCTAssertEqual(totals.weekHours, 3.0, accuracy: 0.01)
        XCTAssertEqual(totals.monthHours, 6.0, accuracy: 0.01)
    }
}
