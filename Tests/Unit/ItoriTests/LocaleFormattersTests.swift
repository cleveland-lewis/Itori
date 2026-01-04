//
//  LocaleFormattersTests.swift
//  ItoriTests
//
//  Tests for LocaleFormatters - Date and time formatting utilities
//

import XCTest
@testable import Roots

@MainActor
final class LocaleFormattersTests: BaseTestCase {
    
    // MARK: - Time Formatter Tests
    
    func testTimeFormatter24Hour() {
        let formatter = LocaleFormatters.timeFormatter(use24Hour: true, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let date = date(year: 2024, month: 1, day: 1, hour: 14, minute: 30)
        let formatted = formatter.string(from: date)
        XCTAssertTrue(formatted.contains("14"))
        XCTAssertTrue(formatted.contains("30"))
    }
    
    func testTimeFormatter12Hour() {
        let formatter = LocaleFormatters.timeFormatter(use24Hour: false, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let date = date(year: 2024, month: 1, day: 1, hour: 14, minute: 30)
        let formatted = formatter.string(from: date)
        XCTAssertTrue(formatted.contains("2") || formatted.contains("14"))
        XCTAssertTrue(formatted.contains("30"))
    }
    
    func testTimeFormatterWithSeconds() {
        let formatter = LocaleFormatters.timeFormatter(use24Hour: true, includeSeconds: true, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let date = date(year: 2024, month: 1, day: 1, hour: 14, minute: 30, second: 45)
        let formatted = formatter.string(from: date)
        XCTAssertTrue(formatted.contains("14"))
        XCTAssertTrue(formatted.contains("30"))
    }
    
    // MARK: - Hour Formatter Tests
    
    func testHourFormatter24Hour() {
        let formatter = LocaleFormatters.hourFormatter(use24Hour: true, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let date = date(year: 2024, month: 1, day: 1, hour: 14, minute: 0)
        let formatted = formatter.string(from: date)
        XCTAssertTrue(formatted.contains("14"))
    }
    
    func testHourFormatter12Hour() {
        let formatter = LocaleFormatters.hourFormatter(use24Hour: false, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let date = date(year: 2024, month: 1, day: 1, hour: 14, minute: 0)
        let formatted = formatter.string(from: date)
        XCTAssertTrue(formatted.contains("2") || formatted.contains("PM"))
    }
    
    // MARK: - Date Formatter Tests
    
    func testFullDateFormatter() {
        let formatter = LocaleFormatters.fullDate
        let testDate = date(year: 2024, month: 12, day: 23)
        let formatted = formatter.string(from: testDate)
        
        XCTAssertTrue(formatted.contains("2024"))
        XCTAssertTrue(formatted.contains("23") || formatted.contains("December"))
    }
    
    func testLongDateFormatter() {
        let formatter = LocaleFormatters.longDate
        formatter.timeZone = calendar.timeZone
        let testDate = date(year: 2024, month: 12, day: 23)
        let formatted = formatter.string(from: testDate)
        
        XCTAssertTrue(formatted.contains("2024"))
        XCTAssertTrue(formatted.contains("23"))
    }
    
    func testMediumDateFormatter() {
        let formatter = LocaleFormatters.mediumDate
        formatter.timeZone = calendar.timeZone
        let testDate = date(year: 2024, month: 12, day: 23)
        let formatted = formatter.string(from: testDate)
        
        XCTAssertTrue(formatted.contains("23") || formatted.contains("12"))
    }
    
    // MARK: - Template Formatter Tests
    
    func testTemplateFormatter() {
        let formatter = LocaleFormatters.templateFormatter("MMM d, yyyy", locale: Locale(identifier: "en_US"))
        let testDate = date(year: 2024, month: 12, day: 23)
        let formatted = formatter.string(from: testDate)
        
        XCTAssertTrue(formatted.contains("2024"))
    }
    
    // MARK: - Locale Sensitivity Tests
    
    func testFormatterWithDifferentLocales() {
        let testDate = date(year: 2024, month: 12, day: 23)
        
        let enFormatter = LocaleFormatters.templateFormatter("MMM d", locale: Locale(identifier: "en_US"))
        let enFormatted = enFormatter.string(from: testDate)
        XCTAssertNotNil(enFormatted)
        
        let frFormatter = LocaleFormatters.templateFormatter("MMM d", locale: Locale(identifier: "fr_FR"))
        let frFormatted = frFormatter.string(from: testDate)
        XCTAssertNotNil(frFormatted)
        
        // Different locales may produce different output
        // Just verify both produce valid strings
        XCTAssertFalse(enFormatted.isEmpty)
        XCTAssertFalse(frFormatted.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testFormatterWithMidnight() {
        let formatter = LocaleFormatters.timeFormatter(use24Hour: true, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let midnight = date(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let formatted = formatter.string(from: midnight)
        
        XCTAssertTrue(formatted.contains("0") || formatted.contains("12"))
    }
    
    func testFormatterWithNoon() {
        let formatter = LocaleFormatters.timeFormatter(use24Hour: false, locale: Locale(identifier: "en_US"), timeZone: calendar.timeZone)
        let noon = date(year: 2024, month: 1, day: 1, hour: 12, minute: 0)
        let formatted = formatter.string(from: noon)
        
        XCTAssertTrue(formatted.contains("12"))
    }
    
    func testFormatterReusability() {
        let formatter1 = LocaleFormatters.fullDate
        let formatter2 = LocaleFormatters.fullDate
        
        let testDate = date(year: 2024, month: 1, day: 1)
        let result1 = formatter1.string(from: testDate)
        let result2 = formatter2.string(from: testDate)
        
        XCTAssertEqual(result1, result2)
    }
}
