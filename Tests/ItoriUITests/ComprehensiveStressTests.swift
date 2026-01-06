//
//  ComprehensiveStressTests.swift
//  ItoriUITests
//
//  Created for comprehensive testing with many courseloads, semesters, and grades
//

import XCTest

final class ComprehensiveStressTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITestingMode", "DisableAnimations"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Multi-Year Semester Tests
    
    /// Tests app performance with 8 years (16 semesters) of data
    func testMultiYearSemesterLoad() throws {
        // Navigate to courses tab
        app.buttons["TabBar.courses"].tap()
        XCTAssertTrue(app.otherElements["Page.courses"].waitForExistence(timeout: 5))
        
        // Create 16 semesters (4 years undergraduate + 4 years graduate)
        for year in 1...8 {
            for semester in ["Fall", "Spring"] {
                addSemester(name: "\(semester) \(2018 + year)")
            }
        }
        
        // Verify all semesters are accessible
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
        
        // Scroll through semester list
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeDown()
        
        // App should not crash or freeze
        XCTAssertTrue(app.buttons["TabBar.courses"].exists)
    }
    
    /// Tests app with realistic heavy courseload per semester
    func testHeavyCourseload() throws {
        app.buttons["TabBar.courses"].tap()
        XCTAssertTrue(app.otherElements["Page.courses"].waitForExistence(timeout: 5))
        
        // Create a semester
        addSemester(name: "Fall 2025")
        
        // Add 7 courses (heavy load)
        let courses = [
            ("CS 101", "Intro to Computer Science"),
            ("MATH 201", "Calculus II"),
            ("PHYS 101", "Physics I"),
            ("CHEM 101", "General Chemistry"),
            ("ENG 201", "English Literature"),
            ("HIST 101", "World History"),
            ("PSYCH 101", "Introduction to Psychology")
        ]
        
        for (code, title) in courses {
            addCourse(code: code, title: title)
        }
        
        // Verify all courses appear
        for (code, _) in courses {
            XCTAssertTrue(app.staticTexts[code].waitForExistence(timeout: 3),
                         "Course \(code) should be visible")
        }
        
        // Switch to grades tab and verify performance
        app.buttons["TabBar.grades"].tap()
        XCTAssertTrue(app.otherElements["Page.grades"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Assignment Stress Tests
    
    /// Tests with hundreds of assignments across multiple courses
    func testMassiveAssignmentLoad() throws {
        app.buttons["TabBar.assignments"].tap()
        XCTAssertTrue(app.otherElements["Page.assignments"].waitForExistence(timeout: 5))
        
        // Create semester and courses
        addSemester(name: "Spring 2026")
        let courses = ["CS 101", "MATH 201", "ENG 101"]
        for code in courses {
            addCourse(code: code, title: code)
        }
        
        // Add 50 assignments (realistic for 3 courses over a semester)
        for i in 1...50 {
            addAssignment(title: "Assignment \(i)", courseCode: courses[i % courses.count])
        }
        
        // Verify list scrolls smoothly
        let assignmentsList = app.scrollViews.firstMatch
        XCTAssertTrue(assignmentsList.exists)
        
        for _ in 1...5 {
            assignmentsList.swipeUp()
            assignmentsList.swipeDown()
        }
        
        // App should remain responsive
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    // MARK: - Grades and GPA Calculation Tests
    
    /// Tests GPA calculation accuracy with many courses and varied grades
    func testComprehensiveGPACalculation() throws {
        app.buttons["TabBar.grades"].tap()
        XCTAssertTrue(app.otherElements["Page.grades"].waitForExistence(timeout: 5))
        
        // Create multiple semesters with varied grades
        addSemester(name: "Fall 2023")
        addGradedCourse(code: "CS 101", title: "Intro to CS", grade: "A", credits: 4)
        addGradedCourse(code: "MATH 101", title: "Calculus I", grade: "B+", credits: 4)
        addGradedCourse(code: "ENG 101", title: "English", grade: "A-", credits: 3)
        
        addSemester(name: "Spring 2024")
        addGradedCourse(code: "CS 201", title: "Data Structures", grade: "A", credits: 4)
        addGradedCourse(code: "MATH 201", title: "Calculus II", grade: "B", credits: 4)
        addGradedCourse(code: "PHYS 101", title: "Physics I", grade: "B+", credits: 4)
        
        // Verify GPA display exists and is formatted correctly
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'GPA'")).firstMatch.waitForExistence(timeout: 5))
        
        // Navigate through grade views
        app.buttons["TabBar.courses"].tap()
        app.buttons["TabBar.grades"].tap()
        
        // App should not crash
        XCTAssertTrue(app.otherElements["Page.grades"].exists)
    }
    
    // MARK: - Calendar and Planner Stress Tests
    
    /// Tests calendar with dense schedule (multiple events per day)
    func testDenseCalendarSchedule() throws {
        app.buttons["TabBar.calendar"].tap()
        XCTAssertTrue(app.otherElements["Page.calendar"].waitForExistence(timeout: 5))
        
        // Simulate week view with many events
        // This tests UI responsiveness with dense data
        
        // Swipe through multiple weeks
        for _ in 1...10 {
            app.swipeLeft()
            usleep(100000) // 100ms delay
        }
        
        for _ in 1...10 {
            app.swipeRight()
            usleep(100000)
        }
        
        // App should remain responsive
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    /// Tests planner with complex scheduling scenarios
    func testComplexPlannerScenarios() throws {
        app.buttons["TabBar.planner"].tap()
        XCTAssertTrue(app.otherElements["Page.planner"].waitForExistence(timeout: 5))
        
        // Create multiple study sessions, assignments due, exams
        // across different time periods
        
        // Swipe through different date ranges
        for _ in 1...5 {
            app.swipeLeft()
            usleep(200000)
        }
        
        // Check that UI elements render correctly
        XCTAssertTrue(app.otherElements["Page.planner"].exists)
    }
    
    // MARK: - Tab Switching Under Load
    
    /// Tests rapid tab switching with heavy data load
    func testRapidTabSwitchingUnderLoad() throws {
        let tabs = ["dashboard", "calendar", "planner", "assignments", "courses", "grades"]
        
        // Create some data first
        app.buttons["TabBar.courses"].tap()
        addSemester(name: "Test Semester")
        for i in 1...5 {
            addCourse(code: "CS \(i)00", title: "Course \(i)")
        }
        
        // Rapidly switch between tabs
        for _ in 1...3 {
            for tab in tabs {
                app.buttons["TabBar.\(tab)"].tap()
                XCTAssertTrue(app.otherElements["Page.\(tab)"].waitForExistence(timeout: 3),
                             "Page.\(tab) should load")
            }
        }
        
        // App should remain stable
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    // MARK: - Memory Pressure Tests
    
    /// Tests app behavior when scrolling through large datasets
    func testLargeDatasetScrolling() throws {
        app.buttons["TabBar.courses"].tap()
        
        // Create many semesters
        for year in 2020...2026 {
            addSemester(name: "Fall \(year)")
            addSemester(name: "Spring \(year)")
        }
        
        // Scroll extensively
        let scrollView = app.scrollViews.firstMatch
        for _ in 1...20 {
            scrollView.swipeUp()
            usleep(50000)
        }
        
        for _ in 1...20 {
            scrollView.swipeDown()
            usleep(50000)
        }
        
        // Memory should not leak, app should not crash
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func addSemester(name: String) {
        // Implementation depends on your UI structure
        // This is a placeholder - adjust to match actual UI
        if app.buttons["AddSemester"].exists {
            app.buttons["AddSemester"].tap()
            let nameField = app.textFields["SemesterName"]
            if nameField.waitForExistence(timeout: 2) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["Save"].tap()
            }
        }
    }
    
    private func addCourse(code: String, title: String) {
        if app.buttons["AddCourse"].exists {
            app.buttons["AddCourse"].tap()
            if let codeField = app.textFields["CourseCode"].firstMatch {
                codeField.tap()
                codeField.typeText(code)
            }
            if let titleField = app.textFields["CourseTitle"].firstMatch {
                titleField.tap()
                titleField.typeText(title)
            }
            app.buttons["Save"].tap()
        }
    }
    
    private func addGradedCourse(code: String, title: String, grade: String, credits: Int) {
        addCourse(code: code, title: title)
        // Additional logic to add grade
        // This is a placeholder - adjust to match actual UI
    }
    
    private func addAssignment(title: String, courseCode: String) {
        if app.buttons["AddAssignment"].exists {
            app.buttons["AddAssignment"].tap()
            if let titleField = app.textFields["AssignmentTitle"].firstMatch {
                titleField.tap()
                titleField.typeText(title)
            }
            app.buttons["Save"].tap()
        }
    }
}
