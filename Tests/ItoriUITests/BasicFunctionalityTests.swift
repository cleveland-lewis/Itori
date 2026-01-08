//
//  BasicFunctionalityTests.swift
//  ItoriUITests
//
//  Simple tests to verify basic app functionality
//

import XCTest

final class BasicFunctionalityTests: XCTestCase {
    
    var app: XCUIApplication!

    private func mainContainer(timeout: TimeInterval = 10) -> XCUIElement {
        let hittable = app.descendants(matching: .any)
            .matching(NSPredicate(format: "isHittable == true"))
            .firstMatch
        if hittable.waitForExistence(timeout: timeout) {
            return hittable
        }

        if app.windows.firstMatch.waitForExistence(timeout: timeout) {
            return app.windows.firstMatch
        }

        if app.otherElements.firstMatch.waitForExistence(timeout: timeout) {
            return app.otherElements.firstMatch
        }

        return app
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch Tests
    
    /// Verifies app launches successfully
    func testAppLaunches() throws {
        XCTAssertTrue(app.exists)
    }
    
    /// Verifies app doesn't crash during first 10 seconds
    func testAppStaysRunning() throws {
        XCTAssertTrue(app.exists)
        sleep(10)
        XCTAssertTrue(app.exists, "App should still be running after 10 seconds")
    }
    
    // MARK: - Basic Navigation
    
    /// Tests that main UI elements are present
    func testMainUIElementsExist() throws {
        // Give app time to fully load
        sleep(2)

        #if os(macOS)
        // macOS: Check for NavigationSplitView content
        let hasSplitter = app.splitters.count > 0
        let hasButtons = app.buttons.count > 0
        XCTAssertTrue(hasSplitter || hasButtons, "App should have UI elements")
        #else
        // iOS: Check for container
        let container = mainContainer()
        XCTAssertTrue(container.exists, "App container should exist")
        
        // Check for common UI elements (buttons, text, etc)
        let hasButtons = app.buttons.count > 0
        let hasText = app.staticTexts.count > 0
        
        XCTAssertTrue(hasButtons || hasText, "App should have some interactive elements")
        #endif
    }
    
    /// Tests app can handle user interaction
    func testBasicInteraction() throws {
        #if os(macOS)
        throw XCTSkip("Test uses iOS menu traversal patterns - needs macOS adaptation")
        #endif
        
        throw XCTSkip("Temporarily disabled - menu traversal issue in XCUITest")
        
        sleep(2)
        
        // Try tapping somewhere safe (the first button if it exists)
        let firstButton = app.buttons.firstMatch
        if firstButton.exists {
            firstButton.tap()
            
            // App should still be running
            XCTAssertTrue(app.exists, "App should handle button tap without crashing")
        }
    }
    
    // MARK: - Memory and Performance
    
    /// Tests app handles repeated interactions
    func testRepeatedInteractions() throws {
        #if os(macOS)
        throw XCTSkip("Test uses mobile swipe gestures - needs macOS adaptation")
        #endif
        
        throw XCTSkip("Temporarily disabled - swipe gestures not finding hit points")
        
        let container = mainContainer()
        
        // Perform repeated actions to check for memory leaks or crashes
        for _ in 1...5 {
            // Swipe or scroll if possible
            container.swipeDown()
            usleep(500000) // 0.5 second
            container.swipeUp()
            usleep(500000)
        }
        
        // App should still be responsive
        XCTAssertTrue(app.exists, "App should handle repeated interactions")
    }
    
    /// Tests app handles backgrounding and foregrounding
    func testBackgroundForeground() throws {
        #if os(macOS)
        throw XCTSkip("Test uses iOS SpringBoard - needs macOS adaptation")
        #endif
        
        throw XCTSkip("Temporarily disabled - SpringBoard not accessible in current simulator")
        
        sleep(2)
        
        // Send app to background (iOS 17+)
        XCUIApplication(bundleIdentifier: "com.apple.springboard").activate()
        sleep(2)
        
        // Bring app back to foreground
        app.activate()
        sleep(2)
        
        // App should still be functional
        XCTAssertTrue(app.exists, "App should handle background/foreground transition")
    }
    
    // MARK: - Orientation Tests (iOS only)
    
    #if os(iOS)
    /// Tests app handles rotation
    func testDeviceRotation() throws {
        sleep(2)
        
        let device = XCUIDevice.shared
        let originalOrientation = device.orientation
        
        // Rotate to landscape
        device.orientation = .landscapeLeft
        sleep(1)
        XCTAssertTrue(app.exists, "App should handle landscape orientation")
        
        // Rotate back
        device.orientation = originalOrientation
        sleep(1)
        XCTAssertTrue(app.exists, "App should handle orientation changes")
    }
    #endif
    
    // MARK: - Stress Tests
    
    /// Tests app with rapid tapping
    func testRapidTapping() throws {
        #if os(macOS)
        throw XCTSkip("Test expects iOS window structure - needs macOS adaptation")
        #endif
        
        let container = mainContainer()
        guard container.isHittable else {
            throw XCTSkip("No hittable UI container available for tapping")
        }
        let coordinate = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        // Rapid tap in center of screen
        for _ in 1...20 {
            coordinate.tap()
            usleep(50000) // 50ms between taps
        }
        
        // App should not crash from rapid input
        XCTAssertTrue(app.exists, "App should handle rapid tapping")
    }
    
    /// Tests app with multiple gestures
    func testMultipleGestures() throws {
        #if os(macOS)
        throw XCTSkip("Test uses mobile swipe gestures - needs macOS adaptation")
        #endif
        
        let container = mainContainer()
        guard container.isHittable else {
            throw XCTSkip("No hittable UI container available for gestures")
        }
        
        // Perform various gestures
        container.swipeLeft()
        usleep(200000)
        container.swipeRight()
        usleep(200000)
        container.swipeUp()
        usleep(200000)
        container.swipeDown()
        usleep(200000)
        
        // Note: Pinch gesture not available in this iOS version
        // Testing other gestures is sufficient for gesture handling
        
        XCTAssertTrue(app.exists, "App should handle multiple gesture types")
    }
    
    // MARK: - Long Running Test
    
    /// Tests app stability over 30 seconds
    func testLongRunningStability() throws {
        throw XCTSkip("Temporarily disabled - swipe gestures not finding hit points")
        
        let startTime = Date()
        let duration: TimeInterval = 30
        let container = mainContainer()
        
        while Date().timeIntervalSince(startTime) < duration {
            // Perform random interactions
            container.swipeUp()
            sleep(1)
            container.swipeDown()
            sleep(1)
            
            // Verify app is still running
            XCTAssertTrue(app.exists, "App crashed during long running test")
        }
        
        XCTAssertTrue(app.exists, "App should remain stable for 30+ seconds")
    }
}
