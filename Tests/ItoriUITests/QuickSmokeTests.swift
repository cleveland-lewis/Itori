//
//  QuickSmokeTests.swift
//  ItoriUITests
//
//  Fast smoke tests that complete in under 30 seconds
//

import XCTest

final class QuickSmokeTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    /// Super fast test - just launches app and checks it exists
    func testAppCanLaunch() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
    
    /// Verify app has some UI elements
    func testAppHasUI() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // Wait for any UI content to appear - try different element types
        // On macOS, look for splitter (from NavigationSplitView) or any buttons
        let hasSplitter = app.splitters.count > 0
        let hasButtons = app.buttons.count > 0
        let hasStaticTexts = app.staticTexts.count > 0
        
        XCTAssertTrue(hasSplitter || hasButtons || hasStaticTexts, "App window should have some UI content")
    }
    
    /// Test app doesn't crash immediately
    func testAppDoesNotCrash() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // Wait 3 seconds
        sleep(3)
        
        // App should still be running
        XCTAssertEqual(app.state, .runningForeground, "App should still be running")
    }
}
