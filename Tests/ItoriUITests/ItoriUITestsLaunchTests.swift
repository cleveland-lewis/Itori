//
//  ItoriUITestsLaunchTests.swift
//  ItoriUITests
//
//  Created by Cleveland Lewis III on 11/30/25.
//

import XCTest

final class ItoriUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    private func skipIfInterferingAppsPresent() throws {
        let updateService = XCUIApplication(bundleIdentifier: "com.grammarly.ProjectLlama.UpdateService")
        updateService.terminate()
        if updateService.state != .notRunning {
            throw XCTSkip("Background update service is active; skipping launch snapshot")
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        try skipIfInterferingAppsPresent()
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
