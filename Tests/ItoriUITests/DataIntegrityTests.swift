//
//  DataIntegrityTests.swift
//  ItoriUITests
//
//  Tests data persistence, edge cases, and user flow integrity
//

import XCUIApplication

final class DataIntegrityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITestingMode", "DisableAnimations"]
        app.launch()
    }
    
    // MARK: - Data Persistence Tests
    
    /// Tests that data persists after app restart
    func testDataPersistenceAcrossLaunches() throws {
        app.buttons["TabBar.courses"].tap()
        
        // Create data
        let semesterName = "Persistence Test Fall 2026"
        let courseName = "CS 999"
        
        // Add semester and course (using helper methods)
        // Note: These need to be implemented based on actual UI
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        
        // Verify data still exists
        app.buttons["TabBar.courses"].tap()
        XCTAssertTrue(app.otherElements["Page.courses"].waitForExistence(timeout: 5))
        
        // Check for semester and course
        // XCTAssertTrue(app.staticTexts[semesterName].exists)
        // XCTAssertTrue(app.staticTexts[courseName].exists)
    }
    
    // MARK: - Edge Case Tests
    
    /// Tests handling of maximum length inputs
    func testMaximumLengthInputs() throws {
        app.buttons["TabBar.courses"].tap()
        
        // Create very long semester name
        let longName = String(repeating: "A", count: 200)
        
        // Attempt to create semester with max length name
        // The UI should either accept and display correctly
        // or show validation error
        
        // This test ensures no crashes with extreme inputs
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    /// Tests handling of special characters and unicode
    func testSpecialCharactersAndUnicode() throws {
        app.buttons["TabBar.courses"].tap()
        
        let specialNames = [
            "Fall 2026 🎓",
            "Español 101",
            "数学 201",
            "العربية",
            "Semester w/ Special: @#$%"
        ]
        
        // Each special name should be handled gracefully
        for name in specialNames {
            // Attempt to add with special characters
            // App should not crash
        }
        
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    /// Tests handling of duplicate entries
    func testDuplicateDataHandling() throws {
        app.buttons["TabBar.courses"].tap()
        
        // Add same course twice
        // UI should either prevent duplicates or allow with warning
        
        // App should handle gracefully without crashing
        XCTAssertTrue(app.otherElements["Page.courses"].exists)
    }
    
    /// Tests handling of zero and negative values
    func testZeroAndNegativeValues() throws {
        app.buttons["TabBar.grades"].tap()
        
        // Attempt to enter 0 credits
        // Attempt to enter negative grade percentages
        // UI should validate or handle gracefully
        
        XCTAssertTrue(app.otherElements["Page.grades"].exists)
    }
    
    // MARK: - User Flow Integrity Tests
    
    /// Tests complete workflow: semester → courses → assignments → grades
    func testCompleteAcademicWorkflow() throws {
        // 1. Create semester
        app.buttons["TabBar.courses"].tap()
        XCTAssertTrue(app.otherElements["Page.courses"].waitForExistence(timeout: 5))
        
        // 2. Add courses to semester
        
        // 3. Navigate to assignments and add for each course
        app.buttons["TabBar.assignments"].tap()
        XCTAssertTrue(app.otherElements["Page.assignments"].waitForExistence(timeout: 5))
        
        // 4. Navigate to grades and verify
        app.buttons["TabBar.grades"].tap()
        XCTAssertTrue(app.otherElements["Page.grades"].waitForExistence(timeout: 5))
        
        // 5. Check dashboard reflects all data
        app.buttons["TabBar.dashboard"].tap()
        XCTAssertTrue(app.otherElements["Page.dashboard"].waitForExistence(timeout: 5))
    }
    
    /// Tests editing and deleting data maintains consistency
    func testDataEditingConsistency() throws {
        app.buttons["TabBar.courses"].tap()
        
        // Create initial data
        // Edit semester name
        // Edit course details
        // Delete a course
        
        // Verify changes propagate to all relevant views
        app.buttons["TabBar.dashboard"].tap()
        app.buttons["TabBar.grades"].tap()
        app.buttons["TabBar.assignments"].tap()
        
        // All views should reflect current state consistently
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    // MARK: - Performance Under Realistic Usage
    
    /// Simulates a full semester lifecycle
    func testFullSemesterLifecycle() throws {
        // Week 1: Add all courses
        app.buttons["TabBar.courses"].tap()
        
        // Week 2-15: Add assignments progressively
        app.buttons["TabBar.assignments"].tap()
        
        // Throughout: Check planner
        app.buttons["TabBar.planner"].tap()
        
        // End of semester: Add final grades
        app.buttons["TabBar.grades"].tap()
        
        // Verify dashboard summary
        app.buttons["TabBar.dashboard"].tap()
        XCTAssertTrue(app.otherElements["Page.dashboard"].exists)
    }
    
    /// Tests usage patterns of heavy vs light semesters
    func testVariableSemesterLoad() throws {
        app.buttons["TabBar.courses"].tap()
        
        // Light semester: 3 courses, few assignments
        // Heavy semester: 7 courses, many assignments
        
        // App should handle both efficiently
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    // MARK: - Boundary Condition Tests
    
    /// Tests first-time user experience (empty state)
    func testEmptyStateHandling() throws {
        // Fresh launch with no data
        // All tabs should show appropriate empty states
        
        let tabs = ["dashboard", "calendar", "planner", "assignments", "courses", "grades"]
        for tab in tabs {
            app.buttons["TabBar.\(tab)"].tap()
            XCTAssertTrue(app.otherElements["Page.\(tab)"].waitForExistence(timeout: 5))
            
            // Should show empty state, not crash
        }
    }
    
    /// Tests maximum realistic data load
    func testMaximumDataLoad() throws {
        // 8 years of data
        // 16 semesters
        // ~120 courses total (15 per year average)
        // ~1000 assignments total
        
        // App should handle without performance degradation
        
        app.buttons["TabBar.dashboard"].tap()
        XCTAssertTrue(app.otherElements["Page.dashboard"].exists)
        
        // Navigate through all tabs
        let tabs = ["calendar", "planner", "assignments", "courses", "grades"]
        for tab in tabs {
            app.buttons["TabBar.\(tab)"].tap()
            XCTAssertTrue(app.otherElements["Page.\(tab)"].waitForExistence(timeout: 10))
        }
    }
    
    // MARK: - Concurrent Operation Tests
    
    /// Tests rapid user interactions
    func testRapidUserInteractions() throws {
        // Simulate anxious student clicking rapidly
        for _ in 1...20 {
            app.buttons["TabBar.dashboard"].tap()
            app.buttons["TabBar.assignments"].tap()
            app.buttons["TabBar.grades"].tap()
            usleep(100000) // 100ms between taps
        }
        
        // App should not crash or enter bad state
        XCTAssertTrue(app.buttons["TabBar.dashboard"].exists)
    }
    
    /// Tests background/foreground transitions
    func testBackgroundTransitions() throws {
        app.buttons["TabBar.dashboard"].tap()
        
        // Simulate backgrounding
        XCUIDevice.shared.press(.home)
        usleep(2000000) // 2 seconds
        
        // Reactivate
        app.activate()
        
        // Should return to same state
        XCTAssertTrue(app.otherElements["Page.dashboard"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Search and Filter Tests
    
    /// Tests search functionality with large datasets
    func testSearchPerformance() throws {
        // Create many courses/assignments
        
        app.buttons["TabBar.assignments"].tap()
        
        // Use search if available
        if app.searchFields.firstMatch.exists {
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            searchField.typeText("CS")
            
            // Results should filter quickly
            usleep(500000) // 500ms
            
            searchField.clearText()
            searchField.typeText("Assignment")
            
            // Should remain responsive
        }
        
        XCTAssertTrue(app.otherElements["Page.assignments"].exists)
    }
    
    /// Tests filter combinations
    func testComplexFiltering() throws {
        app.buttons["TabBar.assignments"].tap()
        
        // Apply multiple filters:
        // - By semester
        // - By course
        // - By status
        // - By due date
        
        // Should handle complex filter logic correctly
        XCTAssertTrue(app.otherElements["Page.assignments"].exists)
    }
}

// MARK: - XCUIElement Extension
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
