import XCTest

final class OverlayHeaderSmokeTests: XCTestCase {
    
    override func setUpWithError() throws {
        #if os(macOS)
        throw XCTSkip("Test suite expects iOS overlay structure - needs macOS adaptation")
        #endif
    }
    
    func testOverlayButtonsRemainVisibleWhileScrolling() {
        let app = XCUIApplication()
        app.launch()

        let quickAdd = app.buttons["Overlay.QuickAdd"]
        let settings = app.buttons["Overlay.Settings"]

        XCTAssertTrue(quickAdd.waitForExistence(timeout: 5))
        XCTAssertTrue(settings.waitForExistence(timeout: 5))

        if app.tabBars.count > 0 {
            let tabBar = app.tabBars.firstMatch
            for button in tabBar.buttons.allElementsBoundByIndex {
                button.tap()
                scrollIfPossible(in: app)
                XCTAssertTrue(quickAdd.exists)
                XCTAssertTrue(settings.exists)
                XCTAssertTrue(app.navigationBars.firstMatch.exists)
            }
        } else {
            scrollIfPossible(in: app)
            XCTAssertTrue(quickAdd.exists)
            XCTAssertTrue(settings.exists)
            XCTAssertTrue(app.navigationBars.firstMatch.exists)
        }

        XCTAssertTrue(app.navigationBars.firstMatch.exists)
    }

    private func scrollIfPossible(in app: XCUIApplication) {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        } else if app.tables.firstMatch.exists {
            app.tables.firstMatch.swipeUp()
        }
    }
}
