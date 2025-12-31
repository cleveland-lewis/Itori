//
//  AnalyticsModelsTests.swift
//  RootsTests
//
//  Tests for AnalyticsModels - Study hours tracking
//

import XCTest
@testable import Roots

@MainActor
final class AnalyticsModelsTests: BaseTestCase {
    
    // MARK: - StudyHoursTotals Initialization Tests
    
    func testStudyHoursTotalsDefaultInit() {
        let totals = StudyHoursTotals()
        
        XCTAssertEqual(totals.todayMinutes, 0)
        XCTAssertEqual(totals.weekMinutes, 0)
        XCTAssertEqual(totals.monthMinutes, 0)
        XCTAssertNotNil(totals.lastResetDate)
    }
    
    func testStudyHoursTotalsCustomInit() {
        let resetDate = date(year: 2024, month: 1, day: 1)
        let totals = StudyHoursTotals(
            todayMinutes: 120,
            weekMinutes: 500,
            monthMinutes: 2000,
            lastResetDate: resetDate
        )
        
        XCTAssertEqual(totals.todayMinutes, 120)
        XCTAssertEqual(totals.weekMinutes, 500)
        XCTAssertEqual(totals.monthMinutes, 2000)
        assertDatesEqual(totals.lastResetDate, resetDate)
    }
    
    // MARK: - Format Minutes Tests
    
    func testFormatMinutesLessThanHour() {
        XCTAssertEqual(StudyHoursTotals.formatMinutes(0), "0m")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(30), "30m")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(59), "59m")
    }
    
    func testFormatMinutesExactHours() {
        XCTAssertEqual(StudyHoursTotals.formatMinutes(60), "1h")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(120), "2h")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(180), "3h")
    }
    
    func testFormatMinutesHoursAndMinutes() {
        XCTAssertEqual(StudyHoursTotals.formatMinutes(90), "1h 30m")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(125), "2h 5m")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(185), "3h 5m")
    }
    
    func testFormatMinutesLargeValues() {
        XCTAssertEqual(StudyHoursTotals.formatMinutes(600), "10h")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(1440), "24h")
        XCTAssertEqual(StudyHoursTotals.formatMinutes(1500), "25h")
    }
    
    // MARK: - Decimal Hours Tests
    
    func testTodayHoursDecimal() {
        let totals = StudyHoursTotals(todayMinutes: 90, weekMinutes: 0, monthMinutes: 0)
        
        XCTAssertEqual(totals.todayHours, 1.5)
    }
    
    func testWeekHoursDecimal() {
        let totals = StudyHoursTotals(todayMinutes: 0, weekMinutes: 120, monthMinutes: 0)
        
        XCTAssertEqual(totals.weekHours, 2.0)
    }
    
    func testMonthHoursDecimal() {
        let totals = StudyHoursTotals(todayMinutes: 0, weekMinutes: 0, monthMinutes: 600)
        
        XCTAssertEqual(totals.monthHours, 10.0)
    }
    
    func testDecimalHoursPrecision() {
        let totals = StudyHoursTotals(todayMinutes: 45, weekMinutes: 0, monthMinutes: 0)
        
        XCTAssertEqual(totals.todayHours, 0.75, accuracy: 0.01)
    }
    
    // MARK: - Codable Tests
    
    func testStudyHoursTotalsCodable() throws {
        let totals = StudyHoursTotals(
            todayMinutes: 100,
            weekMinutes: 500,
            monthMinutes: 2000,
            lastResetDate: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(totals)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StudyHoursTotals.self, from: data)
        
        XCTAssertEqual(decoded.todayMinutes, totals.todayMinutes)
        XCTAssertEqual(decoded.weekMinutes, totals.weekMinutes)
        XCTAssertEqual(decoded.monthMinutes, totals.monthMinutes)
    }
    
    // MARK: - Equatable Tests
    
    func testStudyHoursTotalsEquality() {
        let resetDate = Date()
        let totals1 = StudyHoursTotals(todayMinutes: 100, weekMinutes: 500, monthMinutes: 2000, lastResetDate: resetDate)
        let totals2 = StudyHoursTotals(todayMinutes: 100, weekMinutes: 500, monthMinutes: 2000, lastResetDate: resetDate)
        
        XCTAssertEqual(totals1, totals2)
    }
    
    func testStudyHoursTotalsInequality() {
        let totals1 = StudyHoursTotals(todayMinutes: 100, weekMinutes: 500, monthMinutes: 2000)
        let totals2 = StudyHoursTotals(todayMinutes: 200, weekMinutes: 500, monthMinutes: 2000)
        
        XCTAssertNotEqual(totals1, totals2)
    }
    
    // MARK: - Edge Cases
    
    func testFormatMinutesZero() {
        XCTAssertEqual(StudyHoursTotals.formatMinutes(0), "0m")
    }
    
    func testFormatMinutesNegative() {
        // Negative values shouldn't happen but test behavior
        let result = StudyHoursTotals.formatMinutes(-30)
        XCTAssertTrue(result.contains("-"))
    }
    
    func testZeroHoursDecimal() {
        let totals = StudyHoursTotals(todayMinutes: 0, weekMinutes: 0, monthMinutes: 0)
        
        XCTAssertEqual(totals.todayHours, 0.0)
        XCTAssertEqual(totals.weekHours, 0.0)
        XCTAssertEqual(totals.monthHours, 0.0)
    }
}

// MARK: - CompletedSessionRecord Tests

@MainActor
final class CompletedSessionRecordTests: BaseTestCase {
    
    func testCompletedSessionRecordInitialization() {
        let sessionId = UUID()
        let completedAt = Date()
        
        let record = CompletedSessionRecord(
            sessionId: sessionId,
            completedAt: completedAt,
            durationMinutes: 45
        )
        
        XCTAssertEqual(record.sessionId, sessionId)
        XCTAssertEqual(record.completedAt, completedAt)
        XCTAssertEqual(record.durationMinutes, 45)
    }
    
    func testCompletedSessionRecordCodable() throws {
        let record = CompletedSessionRecord(
            sessionId: UUID(),
            completedAt: Date(),
            durationMinutes: 60
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(record)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CompletedSessionRecord.self, from: data)
        
        XCTAssertEqual(decoded.sessionId, record.sessionId)
        XCTAssertEqual(decoded.durationMinutes, record.durationMinutes)
    }
    
    func testCompletedSessionRecordWithZeroDuration() {
        let record = CompletedSessionRecord(
            sessionId: UUID(),
            completedAt: Date(),
            durationMinutes: 0
        )
        
        XCTAssertEqual(record.durationMinutes, 0)
    }
    
    func testCompletedSessionRecordWithLargeDuration() {
        let record = CompletedSessionRecord(
            sessionId: UUID(),
            completedAt: Date(),
            durationMinutes: 10000
        )
        
        XCTAssertEqual(record.durationMinutes, 10000)
    }
}
