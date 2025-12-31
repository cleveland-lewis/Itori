//
//  CalendarRefreshErrorTests.swift
//  RootsTests
//
//  Tests for CalendarRefreshError - Calendar error types
//

import XCTest
@testable import Roots

@MainActor
final class CalendarRefreshErrorTests: BaseTestCase {
    
    // MARK: - Error Cases Tests
    
    func testCalendarRefreshErrorAllCases() {
        let errors: [CalendarRefreshError] = [.permissionDenied, .schedulingFailed]
        XCTAssertEqual(errors.count, 2)
    }
    
    // MARK: - Identifiable Tests
    
    func testPermissionDeniedId() {
        let error = CalendarRefreshError.permissionDenied
        XCTAssertEqual(error.id, "permissionDenied")
    }
    
    func testSchedulingFailedId() {
        let error = CalendarRefreshError.schedulingFailed
        XCTAssertEqual(error.id, "schedulingFailed")
    }
    
    func testErrorIdsAreUnique() {
        let error1 = CalendarRefreshError.permissionDenied
        let error2 = CalendarRefreshError.schedulingFailed
        
        XCTAssertNotEqual(error1.id, error2.id)
    }
    
    // MARK: - LocalizedError Tests
    
    func testErrorDescriptionNotEmpty() {
        let errors: [CalendarRefreshError] = [.permissionDenied, .schedulingFailed]
        
        for error in errors {
            let description = error.errorDescription ?? ""
            // Should have some description (may be system-provided)
            XCTAssertFalse(description.isEmpty || error.errorDescription == nil)
        }
    }
    
    // MARK: - Equatable Tests
    
    func testErrorEquality() {
        XCTAssertEqual(CalendarRefreshError.permissionDenied, .permissionDenied)
        XCTAssertEqual(CalendarRefreshError.schedulingFailed, .schedulingFailed)
    }
    
    func testErrorInequality() {
        XCTAssertNotEqual(CalendarRefreshError.permissionDenied, .schedulingFailed)
    }
}
