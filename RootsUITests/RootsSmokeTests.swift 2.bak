import XCTest

final class RootsSmokeTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testDashboardLoads() throws {
        let overviewHeader = app.staticTexts["Today's Overview"]
        XCTAssertTrue(overviewHeader.waitForExistence(timeout: 5), "Dashboard should show 'Today's Overview'")
    }

    func testTaskCompletion() throws {
        // Assumes the task checkbox in DashboardTaskRow has accessibilityIdentifier("TaskCheckbox")
        let firstCheckbox = app.buttons.matching(identifier: "TaskCheckbox").firstMatch
        guard firstCheckbox.waitForExistence(timeout: 3) else {
            XCTFail("Task checkbox not found on dashboard")
            return
        }

        firstCheckbox.tap()

        // Wait briefly for removal/animation
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: firstCheckbox)
        let result = XCTWaiter().wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result, .completed, "Task should disappear or move after checking it off")
    }

    func testCalendarNavigation() throws {
        // Assumes sidebar button has accessibilityIdentifier("Sidebar.Calendar")
        let calendarButton = app.buttons["Sidebar.Calendar"]
        XCTAssertTrue(calendarButton.waitForExistence(timeout: 3), "Calendar sidebar button should exist")
        calendarButton.tap()

        // Assumes main calendar grid container has accessibilityIdentifier("CalendarGrid")
        let grid = app.otherElements["CalendarGrid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5), "Calendar grid should appear")

        // Capture current month label (requires identifier on the month title)
        let monthLabel = app.staticTexts["CalendarMonthLabel"]
        XCTAssertTrue(monthLabel.waitForExistence(timeout: 3), "Month label should exist")
        let initialMonth = monthLabel.label

        let nextButton = app.buttons["chevron.right"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2), "Next month button should exist")
        nextButton.tap()

        // Verify month label changes
        let predicate = NSPredicate(format: "label != %@", initialMonth)
        let monthChanged = XCTNSPredicateExpectation(predicate: predicate, object: monthLabel)
        let result = XCTWaiter().wait(for: [monthChanged], timeout: 2.0)
        XCTAssertEqual(result, .completed, "Month label should change after tapping next")
    }

    func testSettingsVisible() throws {
        // Assumes settings button has accessibilityIdentifier("Header.Settings")
        let settingsButton = app.buttons["Header.Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3), "Settings button should exist")
        settingsButton.tap()

        // Assumes Sync & Integrations section is labeled with accessibilityIdentifier("Settings.SyncIntegrations")
        let syncSection = app.staticTexts["Settings.SyncIntegrations"]
        XCTAssertTrue(syncSection.waitForExistence(timeout: 5), "Sync & Integrations section should be visible")
    }
}
