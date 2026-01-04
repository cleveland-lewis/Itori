//
//  BaseTestCase.swift
//  ItoriTests
//
//  Base test case providing common setup and utilities
//

import XCTest
@testable import Roots

/// Base test case with common setup and utilities for all tests
@MainActor
class BaseTestCase: XCTestCase {
    
    // MARK: - Properties
    
    /// Shared mock data factory for creating test objects
    var mockData: MockDataFactory!
    
    /// Test-specific UserDefaults to avoid polluting real data
    var testDefaults: UserDefaults!
    
    /// Test calendar for date manipulation
    var calendar: Calendar!
    
    // MARK: - Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create isolated test defaults
        let suiteName = "com.roots.test.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)
        
        // Set up calendar for consistent date handling
        calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Initialize mock data factory
        mockData = MockDataFactory(calendar: calendar)
    }
    
    override func tearDownWithError() throws {
        // Clean up test defaults
        if let suiteName = testDefaults.dictionaryRepresentation().keys.first {
            testDefaults.removePersistentDomain(forName: suiteName)
        }
        testDefaults = nil
        mockData = nil
        calendar = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Helper Methods
    
    /// Wait for async operation with timeout
    func wait(
        for condition: @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        description: String = "Condition not met"
    ) throws {
        let expectation = XCTestExpectation(description: description)
        
        Task {
            while !condition() {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            expectation.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, description)
    }
    
    /// Create a date from components for consistent testing
    func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        return calendar.date(from: components)!
    }
    
    /// Assert that two dates are equal within a tolerance
    func assertDatesEqual(
        _ date1: Date?,
        _ date2: Date?,
        tolerance: TimeInterval = 1.0,
        _ message: String = "Dates not equal",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let date1 = date1, let date2 = date2 else {
            XCTAssertEqual(date1, date2, message, file: file, line: line)
            return
        }
        
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(
            difference,
            tolerance,
            "\(message): difference was \(difference)s",
            file: file,
            line: line
        )
    }
    
    /// Assert that a collection contains an element matching a predicate
    func assertContains<T>(
        _ collection: [T],
        where predicate: (T) -> Bool,
        _ message: String = "Collection does not contain matching element",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            collection.contains(where: predicate),
            message,
            file: file,
            line: line
        )
    }
}
