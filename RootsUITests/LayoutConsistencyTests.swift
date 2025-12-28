//
//  LayoutConsistencyTests.swift
//  RootsUITests
//
//  Tests for layout consistency, spacing, and alignment across the app
//

import XCTest

@MainActor
final class LayoutConsistencyTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    // MARK: - Spacing Constants Tests
    
    func testStandardSpacingConsistency() throws {
        // Test that standard spacing values are consistent throughout the app
        // Standard Apple spacing: 8, 16, 20, 24, 32, 40
        
        let dashboardButton = app.buttons["Dashboard"]
        XCTAssertTrue(dashboardButton.waitForExistence(timeout: 5), "Dashboard should be available")
        dashboardButton.tap()
        
        // Wait for dashboard to load
        _ = app.staticTexts["Dashboard"].waitForExistence(timeout: 3)
        
        // Take snapshot for manual inspection
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Dashboard Layout"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Dashboard Layout Tests
    
    func testDashboardClockCentering() throws {
        navigateToDashboard()
        
        // The analog clock should be centered in its container
        let clockExists = app.otherElements["AnalogClock"].waitForExistence(timeout: 3)
        if clockExists {
            let clock = app.otherElements["AnalogClock"]
            let clockFrame = clock.frame
            
            // Get parent container bounds
            let window = app.windows.firstMatch
            let windowFrame = window.frame
            
            // Clock should be horizontally centered (within tolerance)
            let clockCenterX = clockFrame.midX
            let windowCenterX = windowFrame.midX
            let tolerance: CGFloat = 50
            
            XCTAssertTrue(
                abs(clockCenterX - windowCenterX) < tolerance,
                "Clock should be horizontally centered. Clock center: \(clockCenterX), Window center: \(windowCenterX)"
            )
        }
    }
    
    func testDashboardItemSpacing() throws {
        navigateToDashboard()
        
        // Test spacing between dashboard items
        let dashboardItems = app.otherElements.matching(identifier: "DashboardCard")
        let count = dashboardItems.count
        
        if count >= 2 {
            for i in 0..<(count - 1) {
                let item1 = dashboardItems.element(boundBy: i)
                let item2 = dashboardItems.element(boundBy: i + 1)
                
                let spacing = item2.frame.minY - item1.frame.maxY
                
                // Spacing should be consistent (16 or 20 points is standard)
                XCTAssertTrue(
                    spacing >= 12 && spacing <= 24,
                    "Card spacing should be between 12-24 points, found: \(spacing)"
                )
            }
        }
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Dashboard Item Spacing"
        add(attachment)
    }
    
    // MARK: - Calendar Layout Tests
    
    func testCalendarGridAlignment() throws {
        navigateToCalendar()
        
        // Calendar grid cells should be evenly spaced and aligned
        let calendarGrid = app.otherElements["CalendarGrid"]
        if calendarGrid.waitForExistence(timeout: 3) {
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Calendar Grid Alignment"
            add(attachment)
        }
    }
    
    func testCalendarViewSwitcherAlignment() throws {
        navigateToCalendar()
        
        // View switcher (Day/Week/Month/Year) should be properly aligned
        let dayButton = app.buttons["Day"]
        let weekButton = app.buttons["Week"]
        let monthButton = app.buttons["Month"]
        
        if dayButton.exists && weekButton.exists && monthButton.exists {
            let dayY = dayButton.frame.midY
            let weekY = weekButton.frame.midY
            let monthY = monthButton.frame.midY
            
            // All buttons should be vertically aligned
            XCTAssertEqual(dayY, weekY, accuracy: 2, "View switcher buttons should be vertically aligned")
            XCTAssertEqual(weekY, monthY, accuracy: 2, "View switcher buttons should be vertically aligned")
        }
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Calendar View Switcher"
        add(attachment)
    }
    
    // MARK: - Sidebar Layout Tests
    
    func testSidebarItemAlignment() throws {
        // Sidebar items should be left-aligned with consistent indentation
        let sidebar = app.otherElements["Sidebar"]
        if sidebar.waitForExistence(timeout: 3) {
            let sidebarButtons = sidebar.buttons.allElementsBoundByIndex
            
            var previousMinX: CGFloat?
            for button in sidebarButtons where button.exists {
                let minX = button.frame.minX
                
                if let prevMinX = previousMinX {
                    // All sidebar items at the same level should have the same left edge
                    XCTAssertEqual(minX, prevMinX, accuracy: 2, "Sidebar items should be left-aligned")
                }
                previousMinX = minX
            }
        }
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Sidebar Layout"
        add(attachment)
    }
    
    // MARK: - Flashcards Layout Tests
    
    func testFlashcardCentering() throws {
        navigateToFlashcards()
        
        // Flashcard should be centered in its container
        let flashcard = app.otherElements["FlashcardContainer"]
        if flashcard.waitForExistence(timeout: 3) {
            let cardFrame = flashcard.frame
            let window = app.windows.firstMatch
            let windowFrame = window.frame
            
            let cardCenterX = cardFrame.midX
            let windowCenterX = windowFrame.midX
            let tolerance: CGFloat = 100
            
            XCTAssertTrue(
                abs(cardCenterX - windowCenterX) < tolerance,
                "Flashcard should be horizontally centered"
            )
        }
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Flashcard Centering"
        add(attachment)
    }
    
    // MARK: - Typography Consistency Tests
    
    func testHeaderTypographyConsistency() throws {
        // Test that headers use consistent font sizes throughout the app
        let pages = ["Dashboard", "Calendar", "Assignments", "Flashcards"]
        
        for page in pages {
            let button = app.buttons[page].firstMatch
            if button.exists {
                button.tap()
                sleep(1)
                
                // Capture screenshot for manual review
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = "\(page) Typography"
                add(attachment)
            }
        }
    }
    
    // MARK: - Button Layout Tests
    
    func testButtonSizeConsistency() throws {
        navigateToDashboard()
        
        // Primary action buttons should have consistent sizing
        let buttons = app.buttons.allElementsBoundByIndex
        var primaryButtonHeights: [CGFloat] = []
        
        for button in buttons where button.exists && button.isHittable {
            let height = button.frame.height
            if height > 30 && height < 60 {
                primaryButtonHeights.append(height)
            }
        }
        
        // Check if most buttons have similar heights
        if let firstHeight = primaryButtonHeights.first {
            let consistentButtons = primaryButtonHeights.filter { abs($0 - firstHeight) < 5 }
            let consistencyRatio = Double(consistentButtons.count) / Double(primaryButtonHeights.count)
            
            XCTAssertGreaterThan(
                consistencyRatio,
                0.7,
                "At least 70% of primary buttons should have consistent heights"
            )
        }
    }
    
    // MARK: - Form Layout Tests
    
    func testFormFieldAlignment() throws {
        // Navigate to a page with forms (e.g., adding an assignment)
        navigateToAssignments()
        
        // Look for "Add" or "New Assignment" button
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'new'")).firstMatch
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            // Form fields should be left-aligned
            let textFields = app.textFields.allElementsBoundByIndex
            var previousMinX: CGFloat?
            
            for field in textFields where field.exists {
                let minX = field.frame.minX
                
                if let prevMinX = previousMinX {
                    XCTAssertEqual(minX, prevMinX, accuracy: 5, "Form fields should be left-aligned")
                }
                previousMinX = minX
            }
            
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Form Field Alignment"
            add(attachment)
        }
    }
    
    // MARK: - Color Consistency Tests
    
    func testAccentColorConsistency() throws {
        // Ensure accent colors are used consistently
        navigateToDashboard()
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Accent Color Usage"
        add(attachment)
        
        // Manual inspection: Check that interactive elements use the same accent color
    }
    
    // MARK: - Padding Tests
    
    func testScreenEdgePadding() throws {
        let pages = ["Dashboard", "Calendar", "Assignments"]
        
        for page in pages {
            let button = app.buttons[page].firstMatch
            if button.exists {
                button.tap()
                sleep(1)
                
                let window = app.windows.firstMatch
                let windowFrame = window.frame
                
                // Check that content isn't touching screen edges
                let allElements = app.descendants(matching: .any).allElementsBoundByIndex
                
                for element in allElements where element.exists && element.isHittable {
                    let frame = element.frame
                    
                    // Minimum padding from edges should be at least 8 points
                    let minPadding: CGFloat = 8
                    
                    XCTAssertGreaterThan(
                        frame.minX - windowFrame.minX,
                        minPadding,
                        "Content should have padding from left edge in \(page)"
                    )
                    
                    XCTAssertGreaterThan(
                        windowFrame.maxX - frame.maxX,
                        minPadding,
                        "Content should have padding from right edge in \(page)"
                    )
                }
                
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = "\(page) Edge Padding"
                add(attachment)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToDashboard() {
        let button = app.buttons["Dashboard"]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            sleep(1)
        }
    }
    
    private func navigateToCalendar() {
        let button = app.buttons["Calendar"]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            sleep(1)
        }
    }
    
    private func navigateToAssignments() {
        let button = app.buttons["Assignments"]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            sleep(1)
        }
    }
    
    private func navigateToFlashcards() {
        let button = app.buttons["Flashcards"]
        if button.waitForExistence(timeout: 5) {
            button.tap()
            sleep(1)
        }
    }
}
