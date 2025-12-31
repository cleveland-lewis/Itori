//
//  RecurrenceRuleTests.swift
//  RootsTests
//
//  Tests for RecurrenceRule - Task recurrence patterns
//

import XCTest
@testable import Roots

@MainActor
final class RecurrenceRuleTests: BaseTestCase {
    
    // MARK: - Frequency Tests
    
    func testFrequencyRawValues() {
        XCTAssertEqual(RecurrenceRule.Frequency.daily.rawValue, "daily")
        XCTAssertEqual(RecurrenceRule.Frequency.weekly.rawValue, "weekly")
        XCTAssertEqual(RecurrenceRule.Frequency.monthly.rawValue, "monthly")
        XCTAssertEqual(RecurrenceRule.Frequency.yearly.rawValue, "yearly")
    }
    
    // MARK: - End Tests
    
    func testEndNever() {
        let end = RecurrenceRule.End.never
        XCTAssertEqual(end, .never)
    }
    
    func testEndAfterOccurrences() {
        let end = RecurrenceRule.End.afterOccurrences(10)
        if case .afterOccurrences(let count) = end {
            XCTAssertEqual(count, 10)
        } else {
            XCTFail("Expected afterOccurrences")
        }
    }
    
    func testEndUntilDate() {
        let targetDate = date(year: 2025, month: 12, day: 31)
        let end = RecurrenceRule.End.until(targetDate)
        if case .until(let date) = end {
            assertDatesEqual(date, targetDate)
        } else {
            XCTFail("Expected until")
        }
    }
    
    func testEndOnDate() {
        let targetDate = date(year: 2025, month: 6, day: 15)
        let end = RecurrenceRule.End.onDate(targetDate)
        if case .until(let date) = end {
            assertDatesEqual(date, targetDate)
        } else {
            XCTFail("Expected until")
        }
    }
    
    // MARK: - HolidaySource Tests
    
    func testHolidaySourceValues() {
        XCTAssertEqual(RecurrenceRule.HolidaySource.none.rawValue, "none")
        XCTAssertEqual(RecurrenceRule.HolidaySource.deviceCalendar.rawValue, "deviceCalendar")
        XCTAssertEqual(RecurrenceRule.HolidaySource.usaFederal.rawValue, "usaFederal")
        XCTAssertEqual(RecurrenceRule.HolidaySource.custom.rawValue, "custom")
    }
    
    // MARK: - SkipPolicy Tests
    
    func testSkipPolicyDefaultInit() {
        let policy = RecurrenceRule.SkipPolicy()
        
        XCTAssertFalse(policy.skipWeekends)
        XCTAssertFalse(policy.skipHolidays)
        XCTAssertEqual(policy.holidaySource, .none)
        XCTAssertEqual(policy.adjustment, .forward)
    }
    
    func testSkipPolicyCustomInit() {
        let policy = RecurrenceRule.SkipPolicy(
            skipWeekends: true,
            skipHolidays: true,
            holidaySource: .usaFederal,
            adjustment: .forward
        )
        
        XCTAssertTrue(policy.skipWeekends)
        XCTAssertTrue(policy.skipHolidays)
        XCTAssertEqual(policy.holidaySource, .usaFederal)
        XCTAssertEqual(policy.adjustment, .forward)
    }
    
    // MARK: - RecurrenceRule Initialization Tests
    
    func testRecurrenceRuleInit() {
        let skipPolicy = RecurrenceRule.SkipPolicy()
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            end: .never,
            skipPolicy: skipPolicy
        )
        
        XCTAssertEqual(rule.frequency, .weekly)
        XCTAssertEqual(rule.interval, 2)
        XCTAssertEqual(rule.end, .never)
    }
    
    func testRecurrenceRuleEnforcesMinimumInterval() {
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 0,
            end: .never,
            skipPolicy: RecurrenceRule.SkipPolicy()
        )
        
        XCTAssertEqual(rule.interval, 1)
    }
    
    func testRecurrenceRuleEnforcesMinimumIntervalNegative() {
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: -5,
            end: .never,
            skipPolicy: RecurrenceRule.SkipPolicy()
        )
        
        XCTAssertEqual(rule.interval, 1)
    }
    
    // MARK: - Preset Tests
    
    func testPresetDaily() {
        let rule = RecurrenceRule.preset(.daily)
        
        XCTAssertEqual(rule.frequency, .daily)
        XCTAssertEqual(rule.interval, 1)
        XCTAssertEqual(rule.end, .never)
        XCTAssertFalse(rule.skipPolicy.skipWeekends)
    }
    
    func testPresetWeekly() {
        let rule = RecurrenceRule.preset(.weekly)
        
        XCTAssertEqual(rule.frequency, .weekly)
        XCTAssertEqual(rule.interval, 1)
    }
    
    func testPresetMonthly() {
        let rule = RecurrenceRule.preset(.monthly)
        
        XCTAssertEqual(rule.frequency, .monthly)
        XCTAssertEqual(rule.interval, 1)
    }
    
    func testPresetYearly() {
        let rule = RecurrenceRule.preset(.yearly)
        
        XCTAssertEqual(rule.frequency, .yearly)
        XCTAssertEqual(rule.interval, 1)
    }
    
    // MARK: - Next Due Date Tests
    
    func testNextDueDateDaily() {
        let rule = RecurrenceRule.preset(.daily)
        let baseDate = date(year: 2024, month: 1, day: 15)
        let nextDate = rule.nextDueDate(from: baseDate)
        
        XCTAssertNotNil(nextDate)
        let expected = date(year: 2024, month: 1, day: 16)
        assertDatesEqual(nextDate!, expected)
    }
    
    func testNextDueDateWeekly() {
        let rule = RecurrenceRule.preset(.weekly)
        let baseDate = date(year: 2024, month: 1, day: 15)
        let nextDate = rule.nextDueDate(from: baseDate)
        
        XCTAssertNotNil(nextDate)
        let expected = date(year: 2024, month: 1, day: 22)
        assertDatesEqual(nextDate!, expected)
    }
    
    func testNextDueDateMonthly() {
        let rule = RecurrenceRule.preset(.monthly)
        let baseDate = date(year: 2024, month: 1, day: 15)
        let nextDate = rule.nextDueDate(from: baseDate)
        
        XCTAssertNotNil(nextDate)
        let expected = date(year: 2024, month: 2, day: 15)
        assertDatesEqual(nextDate!, expected)
    }
    
    func testNextDueDateYearly() {
        let rule = RecurrenceRule.preset(.yearly)
        let baseDate = date(year: 2024, month: 6, day: 15)
        let nextDate = rule.nextDueDate(from: baseDate)
        
        XCTAssertNotNil(nextDate)
        let expected = date(year: 2025, month: 6, day: 15)
        assertDatesEqual(nextDate!, expected)
    }
    
    func testNextDueDateWithInterval() {
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 3,
            end: .never,
            skipPolicy: RecurrenceRule.SkipPolicy()
        )
        let baseDate = date(year: 2024, month: 1, day: 1)
        let nextDate = rule.nextDueDate(from: baseDate)
        
        XCTAssertNotNil(nextDate)
        let expected = date(year: 2024, month: 1, day: 4)
        assertDatesEqual(nextDate!, expected)
    }
    
    // MARK: - Equatable Tests
    
    func testRecurrenceRuleEquality() {
        let rule1 = RecurrenceRule.preset(.daily)
        let rule2 = RecurrenceRule.preset(.daily)
        
        XCTAssertEqual(rule1, rule2)
    }
    
    func testRecurrenceRuleInequality() {
        let rule1 = RecurrenceRule.preset(.daily)
        let rule2 = RecurrenceRule.preset(.weekly)
        
        XCTAssertNotEqual(rule1, rule2)
    }
    
    // MARK: - Hashable Tests
    
    func testRecurrenceRuleHashable() {
        let rule = RecurrenceRule.preset(.daily)
        var set = Set<RecurrenceRule>()
        set.insert(rule)
        
        XCTAssertTrue(set.contains(rule))
        XCTAssertEqual(set.count, 1)
    }
    
    // MARK: - Codable Tests
    
    func testRecurrenceRuleCodable() throws {
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            end: .afterOccurrences(10),
            skipPolicy: RecurrenceRule.SkipPolicy(skipWeekends: true)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecurrenceRule.self, from: data)
        
        XCTAssertEqual(decoded.frequency, rule.frequency)
        XCTAssertEqual(decoded.interval, rule.interval)
        XCTAssertEqual(decoded.end, rule.end)
        XCTAssertEqual(decoded.skipPolicy, rule.skipPolicy)
    }
}
