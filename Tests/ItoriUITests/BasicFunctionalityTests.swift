//
//  BasicFunctionalityTests.swift
//  ItoriUITests
//
//  Simple tests to verify basic app functionality
//

import XCTest

final class BasicFunctionalityTests: XCTestCase {
    
    var app: XCUIApplication!
    
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
        
        // Check that the app has rendered something
        XCTAssertTrue(app.windows.firstMatch.exists, "App window should exist")
        
        // Check for common UI elements (buttons, text, etc)
        let hasButtons = app.buttons.count > 0
        let hasText = app.staticTexts.count > 0
        
        XCTAssertTrue(hasButtons || hasText, "App should have some interactive elements")
    }
    
    /// Tests app can handle user interaction
    func testBasicInteraction() throws {
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
        sleep(2)
        
        // Perform repeated actions to check for memory leaks or crashes
        for _ in 1...5 {
            // Swipe or scroll if possible
            app.swipeDown()
            usleep(500000) // 0.5 second
            app.swipeUp()
            usleep(500000)
        }
        
        // App should still be responsive
        XCTAssertTrue(app.exists, "App should handle repeated interactions")
    }
    
    /// Tests app handles backgrounding and foregrounding
    func testBackgroundForeground() throws {
        sleep(2)
        
        // Send app to background
        XCUIDevice.shared.press(.home)
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
        sleep(2)
        
        let coordinate = app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
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
        sleep(2)
        
        // Perform various gestures
        app.swipeLeft()
        usleep(200000)
        app.swipeRight()
        usleep(200000)
        app.swipeUp()
        usleep(200000)
        app.swipeDown()
        usleep(200000)
        
        // Pinch if possible
        let window = app.windows.firstMatch
        window.pinch(withScale: 1.5, velocity: 1.0)
        usleep(200000)
        
        XCTAssertTrue(app.exists, "App should handle multiple gesture types")
    }
    
    // MARK: - Long Running Test
    
    /// Tests app stability over 30 seconds
    func testLongRunningStability() throws {
        let startTime = Date()
        let duration: TimeInterval = 30
        
        while Date().timeIntervalSince(startTime) < duration {
            // Perform random interactions
            app.swipeUp()
            sleep(1)
            app.swipeDown()
            sleep(1)
            
            // Verify app is still running
            XCTAssertTrue(app.exists, "App crashed during long running test")
        }
        
        XCTAssertTrue(app.exists, "App should remain stable for 30+ seconds")
    }
}
