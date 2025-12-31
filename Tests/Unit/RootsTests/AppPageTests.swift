//
//  AppPageTests.swift
//  RootsTests
//
//  Tests for AppPage enum - App navigation pages
//

import XCTest
@testable import Roots

@MainActor
final class AppPageTests: BaseTestCase {
    
    // MARK: - All Cases Tests
    
    func testAllCases() {
        XCTAssertEqual(AppPage.allCases.count, 9)
        XCTAssertTrue(AppPage.allCases.contains(.dashboard))
        XCTAssertTrue(AppPage.allCases.contains(.calendar))
        XCTAssertTrue(AppPage.allCases.contains(.planner))
        XCTAssertTrue(AppPage.allCases.contains(.assignments))
        XCTAssertTrue(AppPage.allCases.contains(.courses))
        XCTAssertTrue(AppPage.allCases.contains(.grades))
        XCTAssertTrue(AppPage.allCases.contains(.timer))
        XCTAssertTrue(AppPage.allCases.contains(.flashcards))
        XCTAssertTrue(AppPage.allCases.contains(.practice))
    }
    
    // MARK: - Title Tests
    
    func testPageTitles() {
        XCTAssertEqual(AppPage.dashboard.title, "Dashboard")
        XCTAssertEqual(AppPage.calendar.title, "Calendar")
        XCTAssertEqual(AppPage.planner.title, "Planner")
        XCTAssertEqual(AppPage.assignments.title, "Assignments")
        XCTAssertEqual(AppPage.courses.title, "Courses")
        XCTAssertEqual(AppPage.grades.title, "Grades")
        XCTAssertEqual(AppPage.timer.title, "Timer")
        XCTAssertEqual(AppPage.flashcards.title, "Flashcards")
        XCTAssertEqual(AppPage.practice.title, "Practice")
    }
    
    // MARK: - System Image Tests
    
    func testSystemImages() {
        XCTAssertEqual(AppPage.dashboard.systemImage, "rectangle.grid.2x2")
        XCTAssertEqual(AppPage.calendar.systemImage, "calendar")
        XCTAssertEqual(AppPage.planner.systemImage, "square.and.pencil")
        XCTAssertEqual(AppPage.assignments.systemImage, "checklist")
        XCTAssertEqual(AppPage.courses.systemImage, "book.closed")
        XCTAssertEqual(AppPage.grades.systemImage, "chart.bar.doc.horizontal")
        XCTAssertEqual(AppPage.timer.systemImage, "timer")
        XCTAssertEqual(AppPage.flashcards.systemImage, "rectangle.stack")
        XCTAssertEqual(AppPage.practice.systemImage, "list.clipboard")
    }
    
    // MARK: - Identifiable Tests
    
    func testIdentifiable() {
        XCTAssertEqual(AppPage.dashboard.id, "dashboard")
        XCTAssertEqual(AppPage.calendar.id, "calendar")
        XCTAssertEqual(AppPage.planner.id, "planner")
        XCTAssertEqual(AppPage.assignments.id, "assignments")
        XCTAssertEqual(AppPage.courses.id, "courses")
        XCTAssertEqual(AppPage.grades.id, "grades")
        XCTAssertEqual(AppPage.timer.id, "timer")
        XCTAssertEqual(AppPage.flashcards.id, "flashcards")
        XCTAssertEqual(AppPage.practice.id, "practice")
    }
    
    // MARK: - Raw Value Tests
    
    func testRawValues() {
        XCTAssertEqual(AppPage.dashboard.rawValue, "dashboard")
        XCTAssertEqual(AppPage.calendar.rawValue, "calendar")
        XCTAssertEqual(AppPage.planner.rawValue, "planner")
        XCTAssertEqual(AppPage.assignments.rawValue, "assignments")
    }
    
    // MARK: - Uniqueness Tests
    
    func testAllSystemImagesUnique() {
        let images = AppPage.allCases.map { $0.systemImage }
        let uniqueImages = Set(images)
        XCTAssertEqual(images.count, uniqueImages.count)
    }
    
    func testAllTitlesUnique() {
        let titles = AppPage.allCases.map { $0.title }
        let uniqueTitles = Set(titles)
        XCTAssertEqual(titles.count, uniqueTitles.count)
    }
    
    func testAllRawValuesUnique() {
        let rawValues = AppPage.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        XCTAssertEqual(rawValues.count, uniqueRawValues.count)
    }
}
